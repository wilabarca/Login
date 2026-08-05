import admin from 'firebase-admin';
import crypto from 'crypto';

const args = process.argv.slice(2);

function showHelp() {
    console.log(`
Uso: node send_remote_wipe.mjs [opciones]

Opciones:
  --user-id <string>             Usuario cuyos dispositivos serán consultados en Firestore (Requerido).
  --target-user-id <string>      Valor que será colocado en el payload targetUserId (Por defecto: igual a --user-id).
  --command-id <string>          Identificador único del comando (Por defecto: UUID aleatorio).
  --expires-in-seconds <number>  Tiempo de expiración en segundos (Por defecto: 300 = 5 minutos).
  --help                         Muestra esta ayuda.

Ejemplo:
  node send_remote_wipe.mjs --user-id admin
  node send_remote_wipe.mjs --user-id admin --target-user-id otro_usuario
    `);
    process.exit(0);
}

if (args.includes('--help')) {
    showHelp();
}

let userId = null;
let targetUserId = null;
let commandId = crypto.randomUUID();
let expiresInSeconds = 300;

for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--user-id') {
        userId = args[++i];
    } else if (arg === '--target-user-id') {
        targetUserId = args[++i];
    } else if (arg === '--command-id') {
        commandId = args[++i];
    } else if (arg === '--expires-in-seconds') {
        expiresInSeconds = parseInt(args[++i], 10);
    }
}

if (!userId) {
    console.error('Error: Debes proporcionar --user-id.');
    console.log('Ejecuta "node send_remote_wipe.mjs --help" para más información.');
    process.exit(1);
}

if (!targetUserId) {
    targetUserId = userId;
}

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
    console.log(`\nBuscando dispositivos activos en Firestore para el usuario: ${userId}...`);

    try {
        const devicesSnapshot = await db
            .collection('users')
            .doc(userId)
            .collection('devices')
            .where('enabled', '==', true)
            .get();

        if (devicesSnapshot.empty) {
            console.log(`No se encontraron dispositivos activos para el usuario '${userId}'.`);
            process.exit(2);
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
            process.exit(2);
        }

        console.log(`Ruta consultada: users/${userId}/devices`);
        console.log(`Cantidad de dispositivos encontrados: ${validTokens.length}`);
        console.log(`Payload targetUserId: ${targetUserId}`);
        console.log(`Payload commandId: ${commandId}`);

        const now = new Date();
        const expiresAt = new Date(now.getTime() + expiresInSeconds * 1000);

        const payload = {
            data: {
                action: 'remote_wipe',
                targetUserId: targetUserId,
                commandId: commandId,
                issuedAt: now.toISOString(),
                expiresAt: expiresAt.toISOString()
            }
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
                    const docRef = db.collection('users').doc(userId).collection('devices').doc(deviceId);
                    batch.update(docRef, { enabled: false });
                });
                await batch.commit();
                console.log('Tokens inválidos deshabilitados.');
            }
        }

        if (response.successCount > 0) {
            console.log('\nOperación completada con éxito. Al menos un mensaje fue enviado.');
            process.exit(0);
        } else {
            console.log('\nOperación finalizada. Ningún mensaje pudo ser enviado.');
            process.exit(1);
        }

    } catch (e) {
        console.error('Error durante el borrado remoto:', e);
        process.exit(1);
    }
}

run();
