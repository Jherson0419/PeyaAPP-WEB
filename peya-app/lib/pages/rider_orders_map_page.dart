import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiderOrdersMapPage extends StatelessWidget {
  const RiderOrdersMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa - Pedidos pendientes'),
        actions: [
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Vista de repartidor activa.\nAqui se mostraran pedidos pendientes en el mapa.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
