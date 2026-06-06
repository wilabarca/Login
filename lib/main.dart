import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:device_preview/device_preview.dart';

import 'app/app.dart';
import 'features/auth/viewmodels/login_view_model.dart';
import 'features/security/data/location_security_service.dart';
import 'features/security/viewmodels/fake_gps_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // screen_protector solo funciona en móvil, no en web
  if (!kIsWeb) {
    await ScreenProtector.preventScreenshotOn();
  }

  runApp(
    DevicePreview(
      enabled: true,
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
