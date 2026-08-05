import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/login_view_model.dart';
import 'home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final loginViewModel = context.read<LoginViewModel>();

    bool success;

    if (_isRegisterMode) {
      success = await loginViewModel.register(
        username: _usernameController.text,
        password: _passwordController.text,
      );
    } else {
      success = await loginViewModel.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
    }

    if (!mounted) return;

    if (success) {
      FocusScope.of(context).unfocus();
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
    });

    context.read<LoginViewModel>().resetInactivityTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoggedIn) {
          return const HomeView();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isRegisterMode ? 'Crear cuenta local' : 'Login Seguro',
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                  ),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isRegisterMode
                                  ? Icons.person_add_alt_1
                                  : Icons.lock_outline,
                              size: 72,
                              color: Theme.of(context).colorScheme.primary,
                            ),

                            const SizedBox(height: 16),

                            Text(
                              _isRegisterMode
                                  ? 'Registro local'
                                  : 'Inicio de sesión',
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            Text(
                              _isRegisterMode
                                  ? 'Crea una cuenta guardada localmente en el dispositivo.'
                                  : 'Ingresa con una cuenta local existente.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Usuario',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final username = value?.trim() ?? '';

                                if (username.isEmpty) {
                                  return 'El usuario es obligatorio.';
                                }

                                if (username.length < 3) {
                                  return 'El usuario debe tener al menos 3 caracteres.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.password),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final password = value?.trim() ?? '';

                                if (password.isEmpty) {
                                  return 'La contraseña es obligatoria.';
                                }

                                if (_isRegisterMode && password.length < 4) {
                                  return 'La contraseña debe tener al menos 4 caracteres.';
                                }

                                return null;
                              },
                            ),

                            if (viewModel.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.shade300,
                                  ),
                                ),
                                child: Text(
                                  viewModel.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: viewModel.isLoading ? null : _submit,
                                child: viewModel.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isRegisterMode
                                            ? 'Crear cuenta'
                                            : 'Iniciar sesión',
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextButton(
                              onPressed:
                                  viewModel.isLoading ? null : _toggleMode,
                              child: Text(
                                _isRegisterMode
                                    ? 'Ya tengo cuenta'
                                    : 'Crear una cuenta local',
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Divider(),

                            const SizedBox(height: 12),

                            const Text(
                              'Demo disponible: admin / 1234',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}