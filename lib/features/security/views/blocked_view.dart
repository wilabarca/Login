import 'package:flutter/material.dart';

import '../viewmodels/fake_gps_view_model.dart';

class BlockedView extends StatelessWidget {
  const BlockedView({
    super.key,
    required this.status,
    required this.message,
    required this.onRetry,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
  });

  final FakeGpsStatus status;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;

  @override
  Widget build(BuildContext context) {
    final showAppSettingsButton =
        status == FakeGpsStatus.permissionDeniedForever;

    final showLocationSettingsButton =
        status == FakeGpsStatus.locationDisabled ||
        status == FakeGpsStatus.blocked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso bloqueado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.gps_off,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  'No se puede ejecutar la aplicación',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Validar de nuevo'),
                ),
                if (showLocationSettingsButton) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onOpenLocationSettings,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Abrir ajustes de ubicación'),
                  ),
                ],
                if (showAppSettingsButton) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onOpenAppSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Abrir ajustes de la app'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}