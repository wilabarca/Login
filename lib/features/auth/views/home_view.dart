import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/login_view_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => context.read<LoginViewModel>().logout(),
            ),
          ],
        ),
        body: const Center(
          child: Text(
            'Aplicación ejecutándose sin Fake GPS detectado.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
