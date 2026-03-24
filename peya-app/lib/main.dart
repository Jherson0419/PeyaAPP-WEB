import 'dart:developer' as developer;
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peya_app/pages/client_map_page.dart';
import 'package:peya_app/pages/rider_orders_map_page.dart';
import 'package:peya_app/services/auth_service.dart';
import 'package:peya_app/state/app_flow_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    developer.log(
      '[FlutterError] ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
      level: 1000,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    developer.log(
      '[PlatformError] $error',
      error: error,
      stackTrace: stack,
      level: 1000,
    );
    return false;
  };

  await runZonedGuarded(
    () async {
      runApp(const MyApp());
    },
    (error, stack) {
      developer.log(
        '[ZoneError] $error',
        error: error,
        stackTrace: stack,
        level: 1000,
      );
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<bool> _supabaseInitFuture;
  late final AppFlowState _appFlowState;

  @override
  void initState() {
    super.initState();
    _appFlowState = AppFlowState();
    _supabaseInitFuture = _initializeApp();
  }

  Future<bool> _initializeApp() async {
    final ready = await AuthService.initialize();
    if (!ready) return false;

    final hasActiveSession = Supabase.instance.client.auth.currentSession != null;
    if (!hasActiveSession) {
      await AuthService.ensureDefaultDesignUsers();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF00796B);
    return AppFlowScope(
      state: _appFlowState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Peya',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: brandGreen),
          scaffoldBackgroundColor: Colors.white,
          textTheme: GoogleFonts.interTextTheme(),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: brandGreen, width: 1.4),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          useMaterial3: true,
        ),
        home: FutureBuilder<bool>(
          future: _supabaseInitFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final supabaseReady = snapshot.data ?? false;
            if (!supabaseReady) {
              return const _SupabaseConfigErrorPage();
            }

            return StreamBuilder<AuthState>(
              stream: Supabase.instance.client.auth.onAuthStateChange,
              builder: (context, snapshot) {
                return const _RoleGatePage();
              },
            );
          },
        ),
      ),
    );
  }
}

class _SupabaseConfigErrorPage extends StatelessWidget {
  const _SupabaseConfigErrorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 44,
              ),
              const SizedBox(height: 12),
              const Text(
                'No se pudo inicializar Supabase',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                AuthService.initError ??
                    'Verifica SUPABASE_URL y SUPABASE_ANON_KEY.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              const SelectableText(
                'Configura peya-app/.env con SUPABASE_URL y SUPABASE_ANON_KEY',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleGatePage extends StatelessWidget {
  const _RoleGatePage();

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const ClientMapPage();
    }

    return FutureBuilder<String?>(
      future: AuthService.getCurrentUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data;
        if (role == 'RIDER') {
          return const RiderOrdersMapPage();
        }
        return const ClientMapPage();
      },
    );
  }
}
