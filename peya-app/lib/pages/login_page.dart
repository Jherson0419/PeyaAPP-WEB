import 'package:flutter/material.dart';
import 'package:peya_app/pages/register_role_page.dart';
import 'package:peya_app/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({this.popOnSuccess = false, super.key});

  final bool popOnSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final rawUser = _emailController.text.trim();
      final normalizedUser = switch (rawUser.toLowerCase()) {
        'cliente' => 'cliente@peya.dev',
        'rider' => 'rider@peya.dev',
        _ => rawUser,
      };
      await AuthService.signIn(
        email: normalizedUser,
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      if (widget.popOnSuccess && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar sesión: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _fillDemoClient() {
    setState(() {
      _emailController.text = 'cliente@peya.dev';
      _passwordController.text = 'cliente123';
    });
  }

  void _fillDemoRider() {
    setState(() {
      _emailController.text = 'rider@peya.dev';
      _passwordController.text = 'rider123';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(false);
                          }
                        },
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Cerrar',
                      ),
                    ),
                    Container(
                      height: 88,
                      width: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00796B),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Peya',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresa para pedir o repartir',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) {
                          return 'Ingresa usuario o correo';
                        }
                        if (!v.contains('@') && v != 'cliente' && v != 'rider') {
                          return 'Usa cliente, rider o correo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _fillDemoClient,
                          icon: const Icon(Icons.person_outline_rounded),
                          label: const Text('Demo Cliente'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _fillDemoRider,
                          icon: const Icon(Icons.pedal_bike_rounded),
                          label: const Text('Demo Rider'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterRolePage(),
                                ),
                              );
                            },
                      child: const Text('¿No tienes cuenta? Registrarse'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
