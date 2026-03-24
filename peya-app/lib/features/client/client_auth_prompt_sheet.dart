import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peya_app/pages/login_page.dart';
import 'package:peya_app/pages/register_role_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> ensureClientAuthenticated(
  BuildContext context, {
  required String dishName,
}) async {
  if (Supabase.instance.client.auth.currentSession != null) {
    return true;
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _AuthPromptSheet(dishName: dishName),
  );
  return result ?? false;
}

Future<void> showAuthBarrierBottomSheet(
  BuildContext context, {
  required String dishName,
}) async {
  await ensureClientAuthenticated(context, dishName: dishName);
}

class _AuthPromptSheet extends StatelessWidget {
  const _AuthPromptSheet({required this.dishName});

  final String dishName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ya casi es tuyo',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Inicia sesion para completar tu pedido de $dishName.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final didLogin = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const LoginPage(popOnSuccess: true),
                ),
              );
              if (!context.mounted) return;
              if (didLogin ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              elevation: 2,
              backgroundColor: const Color(0xFF00796B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Iniciar sesion'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterRolePage()),
              );
              if (!context.mounted) return;
              if (Supabase.instance.client.auth.currentSession != null) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Registrarse como nuevo usuario'),
          ),
        ],
      ),
    );
  }
}
