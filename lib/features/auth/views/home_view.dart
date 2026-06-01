import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: const Center(
        child: Text(
          'Aplicación ejecutándose sin Fake GPS detectado.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}