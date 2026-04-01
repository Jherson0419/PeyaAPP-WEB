import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peya_app/models/product_model.dart';
import 'package:peya_app/models/vendor_branch_model.dart';

/// Modo lista (restaurante): tarjeta horizontal con imagen 100×100.
class ProductListItem extends StatelessWidget {
  const ProductListItem({
    required this.product,
    required this.onAdd,
    required this.onViewDetail,
    super.key,
  });

  final ProductModel product;
  final VoidCallback onAdd;
  final VoidCallback onViewDetail;

  static const Color _green = Color(0xFF00796B);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate500 = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 100,
              height: 100,
              child: product.displayImageUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.fastfood, color: Color(0xFF94A3B8)),
                    )
                  : Image.network(
                      product.displayImageUrl,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.displayName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: _slate900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.displayDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _slate500,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            'S/ ${product.displayPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              color: _green,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onViewDetail,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Ver',
                            style: GoogleFonts.inter(
                              color: _slate900,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: onAdd,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Añadir',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                      ],
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

/// Modo grid (supermercado / retail): sin descripción larga.
class ProductGridCard extends StatelessWidget {
  const ProductGridCard({
    required this.product,
    required this.onAdd,
    required this.onOpenDetail,
    super.key,
  });

  final ProductModel product;
  final VoidCallback onAdd;
  final VoidCallback onOpenDetail;

  static const Color _green = Color(0xFF00796B);
  static const Color _slate900 = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InkWell(
                onTap: onOpenDetail,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: product.displayImageUrl.isEmpty
                          ? Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF94A3B8), size: 40),
                            )
                          : Image.network(
                              product.displayImageUrl,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                product.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: _slate900,
                  fontSize: 13.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              child: Text(
                'S/ ${product.displayPrice.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  color: _green,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onAdd,
                  child: Text(
                    '+ Agregar',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decide si la tienda usa layout tipo supermercado (grid) según vertical o categoría de sucursal.
bool isSupermarketGridMode(VendorBranchModel? branch) {
  final raw = (branch?.verticalName ?? branch?.branchCategoryName ?? '').trim();
  if (raw.isEmpty) return false;
  final l = raw.toLowerCase();
  return l.contains('supermercado') ||
      l.contains('farmacia') ||
      l.contains('minimarket') ||
      l.contains('retail');
}
