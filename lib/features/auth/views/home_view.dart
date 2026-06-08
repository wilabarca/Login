import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/login_view_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, _) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            context.read<LoginViewModel>().resetInactivityTimer();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Inicio'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesión',
                  onPressed: () {
                    context.read<LoginViewModel>().logout();
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                const Center(
                  child: Text(
                    'Aplicación ejecutándose sin Fake GPS detectado.',
                    textAlign: TextAlign.center,
                  ),
                ),

                if (viewModel.showInactivityWarning)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 16,
                    child: _InactivityWarningCard(
                      secondsRemaining: viewModel.secondsRemaining,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InactivityWarningCard extends StatelessWidget {
  const _InactivityWarningCard({
    required this.secondsRemaining,
  });

  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.shade700,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Advertencia de inactividad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tu sesión se cerrará por ausencia en $secondsRemaining segundos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<LoginViewModel>().logout();
                    },
                    child: const Text('Cerrar sesión'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      context.read<LoginViewModel>().resetInactivityTimer();
                    },
                    child: const Text('Seguir usando'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}