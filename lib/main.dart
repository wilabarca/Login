import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';

import 'app/app.dart';
import 'features/auth/viewmodels/login_view_model.dart';
import 'features/security/data/location_security_service.dart';
import 'features/security/viewmodels/fake_gps_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mantiene la protección de la práctica anterior.
  await ScreenProtector.preventScreenshotOn();

  runApp(
    MultiProvider(
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
  );
}