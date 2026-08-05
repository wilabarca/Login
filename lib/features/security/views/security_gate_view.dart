import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/views/login_view.dart';
import '../viewmodels/fake_gps_view_model.dart';
import '../views/blocked_view.dart';

class SecurityGateView extends StatefulWidget {
  const SecurityGateView({super.key});

  @override
  State<SecurityGateView> createState() => _SecurityGateViewState();
}

class _SecurityGateViewState extends State<SecurityGateView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // En web no hay GPS real, se salta la validación directamente
      if (kIsWeb) {
        context.read<FakeGpsViewModel>().skipValidation();
      } else {
        context.read<FakeGpsViewModel>().validateDeviceLocation();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !kIsWeb) {
      context.read<FakeGpsViewModel>().validateDeviceLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FakeGpsViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isChecking) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (viewModel.canContinue) {
          return const LoginView();
        }

        return BlockedView(
          status: viewModel.status,
          message: viewModel.message,
          onRetry: viewModel.validateDeviceLocation,
          onOpenAppSettings: viewModel.openAppSettings,
          onOpenLocationSettings: viewModel.openLocationSettings,
        );
      },
    );
  }
}
