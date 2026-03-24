import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peya_app/models/user_role.dart';
import 'package:peya_app/pages/rider_orders_map_page.dart';
import 'package:peya_app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterRiderPage extends StatefulWidget {
  const RegisterRiderPage({super.key});

  @override
  State<RegisterRiderPage> createState() => _RegisterRiderPageState();
}

class _RegisterRiderPageState extends State<RegisterRiderPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _plateController = TextEditingController();
  final _dniController = TextEditingController();

  final _picker = ImagePicker();
  String _vehicleType = 'Moto';
  File? _identityFile;
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
    _plateController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _identityFile = File(file.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_identityFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sube una foto de DNI o licencia')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final fullName = _nameController.text.trim();
    final phone = '+51${_phoneController.text.trim()}';
    final plate = _plateController.text.trim();
    final dni = _dniController.text.trim();
    developer.log(
      '[RegisterRiderPage] submit start email=$email role=${UserRole.rider.value} vehicle=$_vehicleType plate=$plate dni=$dni',
    );

    try {
      final auth = await AuthService.signUp(
        email: email,
        password: _passwordController.text.trim(),
        metadata: {
          'full_name': fullName,
          'role': UserRole.rider.value,
        },
      );

      final userId = auth.user?.id;
      if (userId == null) throw Exception('No se pudo crear el usuario');
      developer.log('[RegisterRiderPage] auth userId=$userId');

      await AuthService.uploadIdentityFile(
        userId: userId,
        file: _identityFile!,
      );
      developer.log('[RegisterRiderPage] upload identity ok userId=$userId');

      await AuthService.createProfile({
        'id': userId,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'role': UserRole.rider.value,
        'vehicle_type': _vehicleType,
        'plate_number': plate,
        'is_online': false,
      });
      developer.log('[RegisterRiderPage] profile insert ok userId=$userId');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro completado. Bienvenido a Peya.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RiderOrdersMapPage()),
        (route) => false,
      );
    } on AuthException catch (e, st) {
      developer.log(
        '[RegisterRiderPage] AuthException status=${e.statusCode} message=${e.message}',
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
        '[RegisterRiderPage] Error inesperado en registro',
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
        title: const Text('Registro Repartidor'),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _vehicleType,
                  borderRadius: BorderRadius.circular(18),
                  decoration: const InputDecoration(
                    labelText: 'Tipo de vehículo',
                    prefixIcon: Icon(Icons.two_wheeler_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Moto', child: Text('Moto')),
                    DropdownMenuItem(value: 'Bicicleta', child: Text('Bicicleta')),
                    DropdownMenuItem(value: 'Auto', child: Text('Auto')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _vehicleType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _plateController,
                  decoration: const InputDecoration(
                    labelText: 'Número de placa',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'DNI',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) =>
                      (value ?? '').trim().length != 8 ? 'DNI inválido' : null,
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _pickFile,
                  child: Ink(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.upload_file_rounded),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _identityFile == null
                                ? 'Subir foto de DNI o licencia'
                                : _identityFile!.path.split('\\').last,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      : const Text('Crear cuenta de repartidor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
