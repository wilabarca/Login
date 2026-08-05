import admin from 'firebase-admin';
import crypto from 'crypto';

const args = process.argv.slice(2);

const userIdIndex = args.findIndex((a) => a === '--user-id');
if (userIdIndex === -1 || userIdIndex + 1 >= args.length) {
    console.error('Error: Debes proporcionar --user-id. Ejemplo: node send_remote_wipe.mjs --user-id admin');
    process.exit(1);
}
const targetUserId = args[userIdIndex + 1];

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.warn('\nADVERTENCIA: No has configurado GOOGLE_APPLICATION_CREDENTIALS.\nSe intentarán usar Application Default Credentials.\nSi falla, ejecuta: export GOOGLE_APPLICATION_CREDENTIALS=/ruta/tu/service-account.json\n');
}

try {
    admin.initializeApp({
        credential: admin.credential.applicationDefault()
    });
} catch (e) {
    console.error('Error inicializando Firebase Admin SDK:', e.message);
    process.exit(1);
}

const db = admin.firestore();

async function run() {
    console.log(`\nBuscando dispositivos para el usuario: ${targetUserId}...`);

    try {
        const devicesSnapshot = await db
            .collection('users')
            .doc(targetUserId)
            .collection('devices')
            .where('enabled', '==', true)
            .get();

        if (devicesSnapshot.empty) {
            console.log(`No se encontraron dispositivos activos para el usuario '${targetUserId}'.`);
            return;
        }

        const validTokens = [];
        devicesSnapshot.forEach(doc => {
            const data = doc.data();
            if (data.fcmToken) {
                validTokens.push({ id: doc.id, token: data.fcmToken });
            }
        });

        if (validTokens.length === 0) {
            console.log('Ningún dispositivo tenía un fcmToken válido.');
            return;
        }

        console.log(`Encontrados ${validTokens.length} dispositivo(s). Preparando envío FCM...`);

        const commandId = crypto.randomUUID();
        const now = new Date();
        const expiresAt = new Date(now.getTime() + 5 * 60000); // 5 minutos

        const payload = {
            data: {
                action: 'remote_wipe',
                targetUserId: targetUserId,
                commandId: commandId,
                issuedAt: now.toISOString(),
                expiresAt: expiresAt.toISOString()
            }
        };

        const options = {
            priority: 'high'
        };

        const tokens = validTokens.map(t => t.token);
        
        console.log('Enviando mensaje...');
        const response = await admin.messaging().sendEachForMulticast({
            tokens: tokens,
            data: payload.data,
            android: { priority: 'high' }
        });

        console.log(`\nResultado del envío:`);
        console.log(`- Éxitos: ${response.successCount}`);
        console.log(`- Fallos: ${response.failureCount}`);

        if (response.failureCount > 0) {
            const failedTokens = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    const error = resp.error;
                    console.log(`\nError enviando al dispositivo ${validTokens[idx].id}:`, error.code);
                    
                    if (
                        error.code === 'messaging/invalid-registration-token' ||
                        error.code === 'messaging/registration-token-not-registered'
                    ) {
                        failedTokens.push(validTokens[idx].id);
                    }
                }
            });

            if (failedTokens.length > 0) {
                console.log(`\nDeshabilitando ${failedTokens.length} token(s) inválido(s) en Firestore...`);
                const batch = db.batch();
                failedTokens.forEach(deviceId => {
                    const docRef = db.collection('users').doc(targetUserId).collection('devices').doc(deviceId);
                    batch.update(docRef, { enabled: false });
                });
                await batch.commit();
                console.log('Tokens inválidos deshabilitados.');
            }
        }

        console.log('\nOperación completada con éxito.');

    } catch (e) {
        console.error('Error durante el borrado remoto:', e);
    }
}

run();
