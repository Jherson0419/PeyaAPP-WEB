import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peya_app/models/product_model.dart';
import 'package:peya_app/models/vendor_branch_model.dart';
import 'package:peya_app/services/branch_service.dart';
import 'package:peya_app/state/cart_state.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    required this.product,
    this.sourceStoreId,
    this.sourceStoreName,
    this.sourceStoreIconUrl,
    this.sourceBranchLatitude,
    this.sourceBranchLongitude,
    super.key,
  });

  final ProductModel product;
  /// Sucursal desde la que se abrió el detalle (flujo tienda → producto).
  final String? sourceStoreId;
  final String? sourceStoreName;
  final String? sourceStoreIconUrl;
  final double? sourceBranchLatitude;
  final double? sourceBranchLongitude;

  String? _resolveStoreId(CartState cart) {
    if (sourceStoreId != null && sourceStoreId!.isNotEmpty) return sourceStoreId;
    if (product.storeId != null && product.storeId!.isNotEmpty) return product.storeId;
    return cart.selectedBranch?.id;
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final storeIdForSeller = sourceStoreId ?? product.storeId;

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
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SellerContextCard(
                        storeId: storeIdForSeller,
                        knownStoreName: sourceStoreName,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                  onPressed: () => _onAddToCart(context, cart),
                  child: Text(
                    'Añadir al carrito',
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

  Future<void> _onAddToCart(BuildContext context, CartState cart) async {
    final branchId = _resolveStoreId(cart);
    final branchName = sourceStoreName ??
        cart.selectedBranch?.name ??
        'Sucursal';
    double? lat = sourceBranchLatitude;
    double? lng = sourceBranchLongitude;
    if ((lat == null || lng == null) &&
        cart.selectedBranch != null &&
        branchId == cart.selectedBranch!.id) {
      lat = cart.selectedBranch!.latitude;
      lng = cart.selectedBranch!.longitude;
    }

    var added = cart.addToCart(
      product,
      branchId: branchId,
      branchName: branchName,
      storeIconUrl: sourceStoreIconUrl,
      branchLatitude: lat,
      branchLongitude: lng,
    );
    if (!added || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.displayName} añadido al carrito')),
    );
  }
}

/// Tarjeta "Vendido por" con nombre conocido o carga por `storeId`.
class _SellerContextCard extends StatelessWidget {
  const _SellerContextCard({
    required this.storeId,
    this.knownStoreName,
  });

  final String? storeId;
  final String? knownStoreName;

  @override
  Widget build(BuildContext context) {
    if (storeId == null || storeId!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.storefront_outlined, size: 22, color: Colors.grey.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Selecciona una tienda en el mapa para asociar el pedido.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      );
    }

    if (knownStoreName != null && knownStoreName!.trim().isNotEmpty) {
      return _sellerRow(knownStoreName!.trim());
    }

    return FutureBuilder<VendorBranchModel?>(
      future: BranchService().getBranchById(storeId!),
      builder: (context, snapshot) {
        final name = snapshot.data?.name.trim();
        if (snapshot.connectionState == ConnectionState.waiting && name == null) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00796B),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cargando tienda…',
                  style: GoogleFonts.inter(color: Color(0xFF64748B), fontSize: 14),
                ),
              ],
            ),
          );
        }
        final display = (name != null && name.isNotEmpty) ? name : 'Tienda';
        return _sellerRow(display);
      },
    );
  }

  Widget _sellerRow(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE6FFFA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded, color: Color(0xFF00796B), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF334155), height: 1.35),
                children: [
                  const TextSpan(
                    text: 'Vendido por: ',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
