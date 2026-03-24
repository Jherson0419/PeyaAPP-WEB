import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peya_app/features/client/client_auth_prompt_sheet.dart';
import 'package:peya_app/models/product_model.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({required this.product, super.key});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.network(
                            product.displayImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: const Color(0xFFE2E8F0),
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        product.displayName,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0F172A),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'S/ ${product.displayPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF00796B),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        product.displayDescription,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF334155),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    _onAddToCart(context);
                  },
                  child: Text(
                    'Anadir al Carrito',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAddToCart(BuildContext context) async {
    final isAuthenticated = await ensureClientAuthenticated(
      context,
      dishName: product.displayName,
    );
    if (!context.mounted) return;
    if (!isAuthenticated) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto anadido al carrito')),
    );
  }
}
