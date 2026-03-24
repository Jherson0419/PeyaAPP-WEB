import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:peya_app/pages/client_map_page.dart';
import 'package:peya_app/models/user_role.dart';
import 'package:peya_app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterClientPage extends StatefulWidget {
  const RegisterClientPage({super.key});

  @override
  State<RegisterClientPage> createState() => _RegisterClientPageState();
}

class _RegisterClientPageState extends State<RegisterClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  bool _isRateLimitError(AuthException e) {
    final message = e.message.toLowerCase();
    return message.contains('rate limit');
  }

  void _showRateLimitSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Demasiados intentos. Por favor, espera un momento.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFE57373),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final fullName = _nameController.text.trim();
    final phone = '+51${_phoneController.text.trim()}';

    developer.log(
      '[RegisterClientPage] submit start email=$email role=${UserRole.client.value}',
    );

    try {
      final auth = await AuthService.signUp(
        email: email,
        password: _passwordController.text.trim(),
        metadata: {
          'full_name': fullName,
          'role': UserRole.client.value,
        },
      );

      final userId = auth.user?.id;
      if (userId == null) throw Exception('No se pudo crear el usuario');
      developer.log('[RegisterClientPage] auth userId=$userId');

      await AuthService.createProfile({
        'id': userId,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'role': UserRole.client.value,
        'vehicle_type': null,
        'plate_number': null,
        'is_online': false,
      });
      developer.log('[RegisterClientPage] profile insert ok userId=$userId');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro completado. Bienvenido a Peya.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ClientMapPage()),
        (route) => false,
      );
    } on AuthException catch (e, st) {
      developer.log(
        '[RegisterClientPage] AuthException status=${e.statusCode} message=${e.message}',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      if (_isRateLimitError(e)) {
        _showRateLimitSnackBar();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar: ${e.message}')),
      );
    } catch (e, st) {
      developer.log(
        '[RegisterClientPage] Error inesperado en registro',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Cliente'),
        actions: [
          IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixText: '+51 ',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                  validator: (value) =>
                      (value ?? '').trim().length < 8 ? 'Número inválido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty || !v.contains('@')) return 'Correo inválido';
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
                  validator: (value) =>
                      (value ?? '').length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear cuenta de cliente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
