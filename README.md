# Login App - Remote Wipe via FCM

Esta aplicación Flutter implementa una función de seguridad avanzada: **Borrado Remoto de Datos Sensibles**. Utiliza Firebase Cloud Messaging (FCM), Firebase Firestore, y Flutter Secure Storage.

## Arquitectura y Componentes

1. **Autenticación Local y Remota**: La app permite inicio de sesión (`admin` / `1234`). El ID remoto canónico que usa la aplicación es el nombre del usuario (`admin`).
2. **Registro de Dispositivo (Firestore)**: Tras validar sesión local, la app se autentica anónimamente en Firebase y guarda su token FCM en Firestore bajo la ruta `users/{remoteUserId}/devices/{installationId}`.
3. **Almacenamiento Seguro**: Se guardan 4 datos sensibles de demostración (ID, Access Token, Refresh Token y Session Secret) cifrados a través de `FlutterSecureStorage`.
4. **FCM Background/Foreground Listener**: La app intercepta mensajes FCM `data` dirigidos a ella, tanto activa (foreground), en background o cerrada.
5. **Validación del Comando**: Se valida que la orden de borrado:
   - Sea dirigida expresamente al usuario actual (`targetUserId`).
   - Tenga expiración vigente.
   - No sea un comando duplicado.
6. **Borrado (Remote Wipe)**: Si la validación es correcta, se eliminan exclusivamente los 4 datos sensibles. El ID del dispositivo (`installationId`) y del usuario remoto (`targetUserId`) permanecen intactos.

## Requisitos y Configuración de Firebase

1. El proyecto incluye `firebase_options.dart` y `google-services.json` configurados.
2. Si deseas probar con tu propia instancia, usa `flutterfire configure`, y habilita **Firestore** y **Firebase Authentication (Anónimo)** en la consola. Se proveen `firestore.rules` con permisos estrictos.
3. Para el envío de comandos se requiere `service-account.json`. Nunca lo subas al repositorio.

## Herramienta Emisora (Node.js)

En `tools/remote_wipe_sender` existe un script Node.js para enviar comandos.

Para usarlo:
```bash
cd tools/remote_wipe_sender
npm install
export GOOGLE_APPLICATION_CREDENTIALS=/ruta/a/tu/service-account.json
node send_remote_wipe.mjs --user-id admin
```

Para ver la ayuda y más opciones:
```bash
node send_remote_wipe.mjs --help
```

## Pruebas y Desarrollo

Para ejecutar tests unitarios que cubren flujos exitosos, usuario incorrecto y duplicados:
```bash
flutter test
```

## Demostración

Lee el documento `docs/GUIA_DEMOSTRACION.md` para el paso a paso detallado para evaluar este requerimiento.
