import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../security/data/secure_storage_service.dart';
import '../viewmodels/login_view_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Map<String, bool> _sensitiveFieldsStatus = {};
  bool _isLoadingSensitiveFields = true;
  String? _lastRemoteWipeAt;
  String? _lastProcessedCommandId;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingSensitiveFields = true;
    });

    final status = await SecureStorageService.instance.getSensitiveDataStatus();
    final lastRemoteWipeAt = await SecureStorageService.instance.getLastRemoteWipeAt();
    final lastCommandId = await SecureStorageService.instance.getLastProcessedCommandId();
    final token = await FirebaseMessaging.instance.getToken();

    if (!mounted) return;

    setState(() {
      _sensitiveFieldsStatus = status;
      _lastRemoteWipeAt = lastRemoteWipeAt;
      _lastProcessedCommandId = lastCommandId;
      _fcmToken = token;
      _isLoadingSensitiveFields = false;
    });
  }

  Future<void> _recreateSensitiveFields(LoginViewModel viewModel) async {
    final userId = viewModel.currentUserId;
    if (userId == null) return;

    await SecureStorageService.instance.seedSensitiveData(userId: userId);
    await _loadData();
  }

  bool get _allSensitiveFieldsDeleted {
    if (_sensitiveFieldsStatus.isEmpty) return false;
    return _sensitiveFieldsStatus.values.every((isSaved) => !isSaved);
  }

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
              title: const Text('Inicio - Demo Wipe'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar datos',
                  onPressed: _loadData,
                ),
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
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Usuario Actual: ${viewModel.currentUserId ?? "Ninguno"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('FCM Token Registrado: ${_fcmToken != null ? "Sí" : "No"}'),
                            if (_fcmToken != null) 
                              SelectableText('Token: ${_fcmToken!.substring(0, 15)}...', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_lastRemoteWipeAt != null) ...[
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Borrado remoto aplicado', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                              Text('Fecha: $_lastRemoteWipeAt', style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                              Text('Comando procesado: $_lastProcessedCommandId', style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _SensitiveDataCard(
                      isLoading: _isLoadingSensitiveFields,
                      sensitiveFieldsStatus: _sensitiveFieldsStatus,
                      allDeleted: _allSensitiveFieldsDeleted,
                      onRefresh: _loadData,
                      onRecreate: () => _recreateSensitiveFields(viewModel),
                    ),
                  ],
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

class _SensitiveDataCard extends StatelessWidget {
  const _SensitiveDataCard({
    required this.isLoading,
    required this.sensitiveFieldsStatus,
    required this.allDeleted,
    required this.onRefresh,
    required this.onRecreate,
  });

  final bool isLoading;
  final Map<String, bool> sensitiveFieldsStatus;
  final bool allDeleted;
  final VoidCallback onRefresh;
  final VoidCallback onRecreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  allDeleted ? Icons.check_circle_outline : Icons.security_outlined,
                  color: allDeleted ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Estado de los 4 campos sensibles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: sensitiveFieldsStatus.entries.map((entry) {
                  final isSaved = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !isSaved ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isSaved ? Colors.green.shade300 : Colors.orange.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          !isSaved ? Icons.delete_outline : Icons.lock_outline,
                          color: !isSaved ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${entry.key}: ${isSaved ? "Guardado" : "Eliminado"}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: !isSaved ? Colors.green.shade800 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRecreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Regenerar datos'),
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

class _InactivityWarningCard extends StatelessWidget {
  const _InactivityWarningCard({required this.secondsRemaining});
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
          border: Border.all(color: Colors.orange.shade700),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Advertencia de inactividad', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Tu sesión se cerrará en $secondsRemaining segundos.', textAlign: TextAlign.center),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => context.read<LoginViewModel>().logout(), child: const Text('Cerrar sesión'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: () => context.read<LoginViewModel>().resetInactivityTimer(), child: const Text('Seguir usando'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}