import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:peya_app/models/product_model.dart';
import 'package:peya_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late final Future<List<ProductModel>> _productsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _productsFuture = _apiService.getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Catalogo'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar el catalogo.\nVerifica que Next.js este corriendo en localhost:3000.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final products = snapshot.data ?? <ProductModel>[];
          if (products.isEmpty) {
            return const Center(child: Text('No hay productos disponibles.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductCard(product: product);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Boton de WhatsApp disponible.')),
          );
        },
        elevation: 2,
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade100),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'S/ ${product.precio.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
