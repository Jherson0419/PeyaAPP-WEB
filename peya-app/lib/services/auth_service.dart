import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';
  static bool _initialized = false;
  static String? _initError;

  static bool get isInitialized => _initialized;
  static String? get initError => _initError;

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase no esta inicializado. Configura SUPABASE_URL y SUPABASE_ANON_KEY en .env',
      );
    }
    return Supabase.instance.client;
  }

  static Future<bool> initialize() async {
    developer.log('[AuthService] Iniciando Supabase...');
    try {
      await dotenv.load(fileName: '.env');
      _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
        _initError =
            'Faltan variables SUPABASE_URL o SUPABASE_ANON_KEY en .env.';
        developer.log('[AuthService] $_initError', level: 1000);
        _initialized = false;
        return false;
      }

      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
      _initialized = true;
      _initError = null;
      developer.log('[AuthService] Supabase inicializado correctamente.');
      return true;
    } catch (e, st) {
      _initialized = false;
      _initError = e.toString();
      developer.log(
        '[AuthService] Error al inicializar Supabase',
        error: e,
        stackTrace: st,
        level: 1000,
      );
      return false;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e, st) {
      developer.log('[AuthService] Error en signIn', error: e, stackTrace: st);
      rethrow;
    }
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      developer.log(
        '[AuthService] signUp start email=$email metadata=$metadata',
      );
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      developer.log(
        '[AuthService] signUp ok userId=${response.user?.id} session=${response.session != null}',
      );
      return response;
    } catch (e, st) {
      developer.log('[AuthService] Error en signUp', error: e, stackTrace: st);
      rethrow;
    }
  }

  static Future<void> createProfile(Map<String, dynamic> profile) async {
    try {
      developer.log('[AuthService] createProfile start payload=$profile');
      await client.from('Profile').upsert(profile);
      developer.log(
        '[AuthService] createProfile ok id=${profile['id']} role=${profile['role']}',
      );
    } catch (e, st) {
      developer.log(
        '[AuthService] Error guardando profile',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<String?> uploadIdentityFile({
    required String userId,
    required File file,
  }) async {
    final extension = file.path.split('.').last.toLowerCase();
    final path = 'ids/$userId-${DateTime.now().millisecondsSinceEpoch}.$extension';

    try {
      developer.log(
        '[AuthService] uploadIdentityFile start userId=$userId path=$path',
      );
      await client.storage.from('documents').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = client.storage.from('documents').getPublicUrl(path);
      developer.log('[AuthService] uploadIdentityFile ok url=$publicUrl');
      return publicUrl;
    } catch (e, st) {
      developer.log(
        '[AuthService] Error subiendo documento',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<String?> getCurrentUserRole() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await client
          .from('Profile')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      return data?['role'] as String?;
    } catch (e, st) {
      developer.log(
        '[AuthService] Error obteniendo rol de perfil',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<void> ensureDefaultDesignUsers() async {
    const defaultUsers = [
      {
        'email': 'cliente@peya.dev',
        'password': 'cliente123',
        'full_name': 'Cliente Demo',
        'role': 'CLIENT',
        'phone': '+51999999111',
        'vehicle_type': null,
        'plate_number': null,
      },
      {
        'email': 'rider@peya.dev',
        'password': 'rider123',
        'full_name': 'Rider Demo',
        'role': 'RIDER',
        'phone': '+51999999222',
        'vehicle_type': 'Moto',
        'plate_number': 'PEY-123',
      },
    ];

    for (final user in defaultUsers) {
      final email = user['email'] as String;
      final password = user['password'] as String;
      final fullName = user['full_name'] as String;
      final role = user['role'] as String;
      final phone = user['phone'] as String;
      final vehicleType = user['vehicle_type'];
      final plateNumber = user['plate_number'];

      try {
        developer.log('[AuthService] seed start email=$email');
        AuthResponse? response;

        // 1) Primero intenta login: si funciona, el usuario ya existe.
        try {
          response = await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          developer.log('[AuthService] seed login ok email=$email');
        } catch (_) {
          developer.log('[AuthService] seed login miss email=$email');
        }

        // 2) Si no existe/sin credenciales validas, crea y luego loguea.
        if (response?.user == null) {
          await client.auth.signUp(
            email: email,
            password: password,
            data: {'full_name': fullName, 'role': role},
          );
          developer.log('[AuthService] seed signup attempted email=$email');

          response = await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          developer.log('[AuthService] seed login after signup ok email=$email');
        }

        final userId = response?.user?.id;
        if (userId == null) {
          developer.log('[AuthService] seed skip email=$email (sin userId)');
          continue;
        }

        await client.from('Profile').upsert({
          'id': userId,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'role': role,
          'vehicle_type': vehicleType,
          'plate_number': plateNumber,
          'is_online': false,
        });
        developer.log('[AuthService] seed ok email=$email userId=$userId');
      } catch (e, st) {
        developer.log(
          '[AuthService] seed error email=$email',
          error: e,
          stackTrace: st,
        );
      } finally {
        try {
          await client.auth.signOut();
        } catch (_) {}
      }
    }
  }
}
