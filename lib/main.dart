import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'features/auth/viewmodels/login_view_model.dart';
import 'features/security/data/location_security_service.dart';
import 'features/security/data/remote_wipe_service.dart';
import 'features/security/viewmodels/fake_gps_view_model.dart';
import 'features/notifications/data/fcm_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await RemoteWipeService.instance.handleRemoteMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint("Error inicial en signInAnonymously: $e");
    }
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FcmService.instance.init();

  runApp(
    DevicePreview(
      enabled: kIsWeb,
      builder: (context) => MultiProvider(
        providers: [
          Provider<LocationSecurityService>(
            create: (_) => LocationSecurityService(),
          ),
          ChangeNotifierProvider<FakeGpsViewModel>(
            create: (context) => FakeGpsViewModel(
              context.read<LocationSecurityService>(),
            ),
          ),
          ChangeNotifierProvider<LoginViewModel>(
            create: (_) => LoginViewModel(),
          ),
        ],
        child: const App(),
      ),
    ),
  );
}