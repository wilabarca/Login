# Guía de Demostración: Borrado Remoto

Esta guía detalla los pasos exactos para reproducir y validar el borrado remoto usando Firebase Cloud Messaging en todos sus flujos, positivos y negativos.

## Pre-requisitos

1. Emulador o dispositivo Android (API 21+).
2. Haber compilado e instalado el APK (`flutter build apk --debug`).
3. Tener Node.js instalado y dependencias del emisor instaladas (`npm ci`).
4. Archivo `service-account.json` de Firebase (exportado en `GOOGLE_APPLICATION_CREDENTIALS`).

## Pasos de la Demostración

### 1. Iniciar Sesión y Verificar Estado Inicial
- Abre la aplicación e Inicia sesión: **Usuario**: `admin`, **Contraseña**: `1234`.
- Otorga permisos de notificación si se solicitan (Android 13+).
- En la interfaz, verifica:
  - **FCM Token obtenido**: Sí
  - **Registrado en Firestore**: Sí
  - **Estado de los 4 campos sensibles**: Los 4 deben aparecer "Guardado" en verde.

### 2. Prueba 1: Foreground (Primer Plano)
- Mantén la aplicación abierta y visible.
- En una terminal, ejecuta:
  ```bash
  node tools/remote_wipe_sender/send_remote_wipe.mjs --user-id admin
  ```
- Inmediatamente, la UI debe mostrar un **Snackbar rojo**, el aviso de "Borrado remoto aplicado" y los cuatro campos pasarán a estado "Eliminado", sin necesidad de presionar el botón "Actualizar".

### 3. Prueba 2: Background (Segundo Plano)
- Presiona "Regenerar datos" en la app para restaurarlos.
- Presiona el botón de inicio (Home) de Android. NO fuerces el cierre de la app.
- En la terminal, ejecuta nuevamente la orden:
  ```bash
  node tools/remote_wipe_sender/send_remote_wipe.mjs --user-id admin
  ```
- Vuelve a abrir la aplicación. Los campos se mostrarán eliminados automáticamente debido a que el *isolate* de fondo hizo el trabajo exitosamente y el *WidgetsBindingObserver* recargó la UI al regresar.

### 4. Prueba 3: Usuario Incorrecto (Prueba Negativa)
- Presiona "Regenerar datos" en la app.
- Envía una orden a tu mismo dispositivo (usando `--user-id admin` para que Firebase localice tu token), pero inyecta un payload que diga que va dirigido a otro usuario:
  ```bash
  node tools/remote_wipe_sender/send_remote_wipe.mjs --user-id admin --target-user-id intruso
  ```
- Verás un **Snackbar naranja** indicando que la orden fue ignorada por `wrongUser`. Los datos no se eliminan.

### 5. Prueba 4: Comando Duplicado
- Presiona "Regenerar datos".
- Ejecuta una orden explícitamente con un comando repetido:
  ```bash
  node tools/remote_wipe_sender/send_remote_wipe.mjs --user-id admin --command-id prueba-duplicada
  ```
- Se borrarán los datos (resultado: `applied`).
- Regenera datos en la app nuevamente.
- Vuelve a ejecutar exactamente el mismo script con el mismo `command-id`.
- Esta vez, la app muestra una alerta naranja `duplicate` y los datos NO se eliminan.

### 6. Prueba 5: Orden Expirada
- Regenera los datos.
- Ejecuta la orden forzando un tiempo de expiración negativo:
  ```bash
  node tools/remote_wipe_sender/send_remote_wipe.mjs --user-id admin --expires-in-seconds -10
  ```
- La aplicación la recibe pero la rechaza con el motivo `expired`. Los datos se mantienen seguros.
