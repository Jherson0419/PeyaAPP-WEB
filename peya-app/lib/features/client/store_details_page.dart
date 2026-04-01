import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peya_app/features/client/product_detail_page.dart';
import 'package:peya_app/features/client/widgets/store_product_layout.dart';
import 'package:peya_app/models/product_model.dart';
import 'package:peya_app/models/vendor_branch_model.dart';
import 'package:peya_app/providers/store_providers.dart';
import 'package:peya_app/services/branch_service.dart';
import 'package:peya_app/state/cart_state.dart';

class StoreDetailsPage extends StatefulWidget {
  const StoreDetailsPage({
    required this.storeId,
    required this.storeName,
    this.storeLogoUrl,
    super.key,
  });

  final String storeId;
  final String storeName;
  final String? storeLogoUrl;

  @override
  State<StoreDetailsPage> createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  late final Future<
      ({Map<String, List<ProductModel>> groupedProducts, VendorBranchModel? branch})> _pageFuture;

  @override
  void initState() {
    super.initState();
    _pageFuture = _loadPageData();
  }

  Future<({Map<String, List<ProductModel>> groupedProducts, VendorBranchModel? branch})>
      _loadPageData() async {
    final groupedProducts = await groupedStoreMenuProvider(widget.storeId);
    final branch = await BranchService().getBranchById(widget.storeId);
    return (groupedProducts: groupedProducts, branch: branch);
  }

  Future<void> _tryAddToCart(
    ProductModel product,
    VendorBranchModel? branch,
  ) async {
    final cart = CartScope.of(context);
    if (branch != null) {
      cart.selectBranch(branch);
    }
    var added = cart.addToCart(
      product,
      branchId: widget.storeId,
      branchName: widget.storeName,
      storeIconUrl: widget.storeLogoUrl,
      branchLatitude: branch?.latitude,
      branchLongitude: branch?.longitude,
    );
    if (!added || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.displayName} añadido al carrito')),
    );
  }

  void _openProductDetail(ProductModel product, VendorBranchModel? branch) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          product: product,
          sourceStoreId: widget.storeId,
          sourceStoreName: widget.storeName,
          sourceStoreIconUrl: widget.storeLogoUrl,
          sourceBranchLatitude: branch?.latitude,
          sourceBranchLongitude: branch?.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<
          ({Map<String, List<ProductModel>> groupedProducts, VendorBranchModel? branch})>(
        future: _pageFuture,
        builder: (context, snapshot) {
          final slivers = <Widget>[
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.storeName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: const [Shadow(blurRadius: 8, color: Colors.black38)],
                  ),
                ),
                background: Hero(
                  tag: 'branch-logo-${widget.storeId}',
                  child: widget.storeLogoUrl != null && widget.storeLogoUrl!.isNotEmpty
                      ? Image.network(
                          widget.storeLogoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _headerPlaceholder(),
                        )
                      : _headerPlaceholder(),
                ),
              ),
            ),
          ];

          if (snapshot.connectionState != ConnectionState.done) {
            slivers.add(
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00796B)),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            slivers.add(
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No se pudo cargar el menú.\n${snapshot.error}'),
                ),
              ),
            );
          } else {
            final data = snapshot.data!;
            final groupedProducts = data.groupedProducts;
            final branch = data.branch;
            final categories = groupedProducts.entries.toList();
            final hasProducts = categories.any((entry) => entry.value.isNotEmpty);

            if (!hasProducts) {
              slivers.add(
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Esta sucursal no tiene productos activos.'),
                    ),
                  ),
                ),
              );
            } else if (isSupermarketGridMode(branch)) {
              slivers.addAll(_buildGridCategorySlivers(categories, branch));
            } else {
              slivers.addAll(_buildListCategorySlivers(categories, branch));
            }
          }

          return CustomScrollView(slivers: slivers);
        },
      ),
    );
  }

  Widget _headerPlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.storefront, size: 56, color: Color(0xFF64748B)),
      ),
    );
  }

  List<Widget> _buildListCategorySlivers(
    List<MapEntry<String, List<ProductModel>>> categories,
    VendorBranchModel? branch,
  ) {
    final sections = categories.where((entry) => entry.value.isNotEmpty).toList();
    final slivers = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final products = section.value;
      final isLast = i == sections.length - 1;
      if (i == 0) {
        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 14)));
      }
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _CategoryHeaderDelegate(title: section.key),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, isLast ? 24 : 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final p = products[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == products.length - 1 ? 0 : 10),
                  child: ProductListItem(
                    product: p,
                    onAdd: () => _tryAddToCart(p, branch),
                    onViewDetail: () => _openProductDetail(p, branch),
                  ),
                );
              },
              childCount: products.length,
            ),
          ),
        ),
      );
    }
    return slivers;
  }

  List<Widget> _buildGridCategorySlivers(
    List<MapEntry<String, List<ProductModel>>> categories,
    VendorBranchModel? branch,
  ) {
    final sections = categories.where((entry) => entry.value.isNotEmpty).toList();
    final slivers = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final products = section.value;
      final isLast = i == sections.length - 1;
      if (i == 0) {
        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 14)));
      }
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _CategoryHeaderDelegate(title: section.key),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, isLast ? 24 : 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final p = products[index];
                return ProductGridCard(
                  product: p,
                  onAdd: () => _tryAddToCart(p, branch),
                  onOpenDetail: () => _openProductDetail(p, branch),
                );
              },
              childCount: products.length,
            ),
          ),
        ),
      );
    }
    return slivers;
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CategoryHeaderDelegate({required this.title});

  final String title;

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent == 0 ? 1 : (maxExtent - minExtent)))
        .clamp(0.0, 1.0);
    final bg = Color.lerp(
      Colors.white.withValues(alpha: 0.94),
      Colors.white,
      t,
    )!;
    final showShadow = overlapsContent || t > 0.02;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.title != title;
  }
}
