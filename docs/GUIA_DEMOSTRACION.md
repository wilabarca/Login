# Guía de Demostración: Borrado Remoto

Esta guía detalla los pasos exactos para reproducir y validar el borrado remoto usando Firebase Cloud Messaging.

## Pre-requisitos

1. Tener un emulador o dispositivo Android (API 21+).
2. Haber compilado e instalado el APK (`flutter build apk --debug`).
3. (Solo para la prueba automatizada) Tener Node.js instalado.
4. (Solo para la prueba automatizada) Disponer de un archivo `service-account.json` de un proyecto de Firebase válido y configurar la variable de entorno `GOOGLE_APPLICATION_CREDENTIALS`.

## Pasos de la Demostración

### 1. Iniciar Sesión y Verificar Estado Inicial
- Abre la aplicación "Login".
- Inicia sesión con las credenciales de demostración:
  - **Usuario**: `admin`
  - **Contraseña**: `1234`
- Otorga permisos de notificación si el dispositivo los solicita.
- En la pantalla de "Inicio - Demo Wipe", revisa la sección **"Estado de los 4 campos sensibles"**. Deberían aparecer 4 campos como "Guardado" marcados en verde:
  - `user_id`
  - `access_token`
  - `refresh_token`
  - `session_secret`
- Revisa también la parte superior que dice "FCM Token Registrado: Sí".

### 2. Prueba de Background
- Presiona el botón de inicio (Home) de Android para poner la aplicación en segundo plano. NO fuerces el cierre de la aplicación desde ajustes.

### 3. Emisión del Comando de Borrado
- Abre una terminal en tu computadora.
- Navega a la carpeta del emisor:
  ```bash
  cd tools/remote_wipe_sender
  npm install
  export GOOGLE_APPLICATION_CREDENTIALS=/ruta/a/tu/service-account.json
  node send_remote_wipe.mjs --user-id admin
  ```
- **Nota:** El script buscará automáticamente el token en Firestore bajo `users/admin/devices/...` y enviará un payload JSON con `action: "remote_wipe"`.
- Observa la salida de la consola que indica "1 éxitos" y "0 fallos".

### 4. Verificar Eliminación
- Regresa a la aplicación (abre la aplicación nuevamente).
- Verás en color rojo brillante un recuadro indicando **"Borrado remoto aplicado"**, junto con la fecha y hora.
- En la sección **"Estado de los 4 campos sensibles"**, los 4 campos ahora deben aparecer en rojo/naranja como **"Eliminado"**.

### 5. Prueba de Usuario Incorrecto (Seguridad)
- Cierra la alerta roja presionando su botón "X".
- Presiona el botón **"Regenerar datos"** en la app. Los 4 campos volverán a estado "Guardado".
- En tu terminal, envía una orden para otro usuario:
  ```bash
  node send_remote_wipe.mjs --user-id OTRO_USUARIO
  ```
  *(Nota: Si "OTRO_USUARIO" no tiene tokens registrados, el script Node no enviará nada. Para simular un mensaje que sí llega pero con usuario incorrecto, puedes modificar temporalmente el script para que ignore Firestore y mande el mensaje con un payload que diga `--user-id OTRO_USUARIO` directamente a tu token copiado de la pantalla)*.
- Si envías un comando de borrado que lleva `targetUserId` = "OTRO_USUARIO" directamente a tu dispositivo, notarás que la aplicación **no elimina los datos**, ya que el `RemoteWipeService` valida el id del usuario de la sesión contra el del payload.

### Limitaciones Conocidas Android
Si fuerzas la detención (Force Stop) desde Ajustes -> Aplicaciones, Android bloquea la recepción de notificaciones FCM "data" hasta que el usuario abra la aplicación manualmente. Esto no es un bug del código, sino una medida estricta del sistema operativo Android desde API 31+.
