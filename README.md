# Login App - Remote Wipe via FCM

Esta aplicación Flutter implementa una función de seguridad avanzada: **Borrado Remoto de Datos Sensibles**. Utiliza Firebase Cloud Messaging (FCM), Firebase Firestore, y Flutter Secure Storage.

## Arquitectura y Componentes

1. **Autenticación Local**: La app permite inicio de sesión (`admin` / `1234`).
2. **Registro de Dispositivo (Firestore)**: Tras autenticarse, la app usa Firebase Auth Anónimo para guardar de forma segura su token FCM en Firestore bajo la ruta `users/{userId}/devices/{installationId}`.
3. **Almacenamiento Seguro**: Se guardan 4 datos sensibles de demostración (ID, Access Token, Refresh Token y Session Secret) cifrados a través de `FlutterSecureStorage`.
4. **FCM Background/Foreground Listener**: La app intercepta mensajes FCM `data` dirigidos a ella, tanto activa como en segundo plano o cerrada.
5. **Validación del Comando**: Se valida que la orden de borrado:
   - Sea dirigida expresamente al usuario actual (`targetUserId`).
   - Tenga expiración vigente.
   - No sea un comando duplicado.
6. **Borrado (Remote Wipe)**: Si la validación es correcta, se eliminan exclusivamente los 4 datos sensibles en el almacenamiento seguro.

## Requisitos y Configuración de Firebase

1. El proyecto actual incluye archivos `firebase_options.dart` y `google-services.json` configurados.
2. Si deseas probar con tu propia instancia, usa `flutterfire configure` para sobreescribirlos, y habilita **Firestore** y **Firebase Authentication (Anónimo)** en la consola.
3. Para la demostración y envío del comando, se requiere un archivo de credenciales de servicio `service-account.json` (Firebase Admin SDK).

> **Advertencia de Seguridad**: NUNCA subas archivos `google-services.json` de producción, ni cuentas de servicio `*.json` al repositorio. Se ha configurado `.gitignore` para omitirlos.

## Herramienta Emisora (Node.js)

En `tools/remote_wipe_sender` existe un script Node.js que actúa como backend emisor.
Este script lee los tokens de un usuario en Firestore y emite un mensaje HTTP v1 de FCM firmado con Firebase Admin SDK.

Para usarlo:
```bash
cd tools/remote_wipe_sender
npm install
export GOOGLE_APPLICATION_CREDENTIALS=/ruta/a/tu/service-account.json
node send_remote_wipe.mjs --user-id admin
```

## Pruebas y Desarrollo

Para ejecutar los tests unitarios:
```bash
flutter test
```

Para análisis de código:
```bash
flutter analyze
```

## Demostración

Lee el documento `docs/GUIA_DEMOSTRACION.md` para el paso a paso detallado para evaluar este requerimiento, incluyendo capturas de prueba y resultados esperados.

## Estructura de Archivos Relevantes

- `lib/features/security/data/secure_storage_service.dart`: Almacenamiento.
- `lib/features/security/data/device_registration_service.dart`: Registro Firestore.
- `lib/features/security/data/remote_wipe_service.dart`: Lógica de validación.
- `lib/features/remote_wipe/data/remote_wipe_message_parser.dart`: Parser.
- `lib/features/remote_wipe/domain/remote_wipe_command.dart`: Modelo.
- `tools/remote_wipe_sender/send_remote_wipe.mjs`: Node.js emisor.
- `docs/Reporte_FCM_Borrado_Remoto.md`: Reporte en extenso.
