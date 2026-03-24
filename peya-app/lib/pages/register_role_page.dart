import 'package:flutter/material.dart';
import 'package:peya_app/pages/register_client_page.dart';
import 'package:peya_app/pages/register_rider_page.dart';

class RegisterRolePage extends StatelessWidget {
  const RegisterRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        actions: [
          IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selecciona tu perfil',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elige cómo usarás Peya',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _RoleCard(
              icon: Icons.shopping_bag_rounded,
              title: 'Soy Cliente',
              subtitle: 'Pedir productos y seguir pedidos en tiempo real',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterClientPage()),
                );
              },
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.pedal_bike_rounded,
              title: 'Soy Repartidor',
              subtitle: 'Recibir entregas y generar ganancias',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterRiderPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF00796B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: const Color(0xFF00796B)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
