import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peya_app/features/client/client_auth_prompt_sheet.dart';
import 'package:peya_app/models/product_model.dart';
import 'package:peya_app/features/client/product_detail_page.dart';
import 'package:peya_app/services/product_service.dart';
import 'package:peya_app/state/app_flow_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  static const Color _brandGreen = Color(0xFF00796B);
  static const Color _slate900 = Color(0xFF0F172A);
  int _currentIndex = 0;
  final ProductService _productService = ProductService();
  Future<List<ProductModel>>? _productsFuture;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool showProducts = false;
  String? activeCategoryId;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppFlowScope.of(context);
    final deliveryLat = appState.deliveryLat;
    final deliveryLng = appState.deliveryLng;
    final addressLabel = deliveryLat != null && deliveryLng != null
        ? 'Av. Espana, Trujillo'
        : 'Trujillo Centro';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _FixedHomeHeader(
              addressLabel: addressLabel,
              slate900: _slate900,
              onCartTap: () async {
                final session =
                    Supabase.instance.client.auth.currentSession;
                if (session == null) {
                  await showAuthBarrierBottomSheet(
                    context,
                    dishName: 'tu pedido',
                  );
                  return;
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Carrito abierto')),
                );
              },
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildSectionBody(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _brandGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer_rounded),
            label: 'Promocion',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeMapSection();
      case 1:
        return const _SimpleSection(
          key: ValueKey('promocion'),
          icon: Icons.celebration_outlined,
          title: 'Promociones',
          subtitle: 'Aqui veras descuentos y cupones activos.',
        );
      case 2:
        return const _SimpleSection(
          key: ValueKey('pedidos'),
          icon: Icons.receipt_long_outlined,
          title: 'Pedidos',
          subtitle: 'Consulta tu historial y estado de entregas.',
        );
      default:
        return const _SimpleSection(
          key: ValueKey('perfil'),
          icon: Icons.person_outline_rounded,
          title: 'Perfil',
          subtitle: 'Gestiona tu cuenta, direcciones y metodos de pago.',
        );
    }
  }

  Widget _buildHomeMapSection() {
    return Stack(
      key: const ValueKey('home-map'),
      children: [
        const Positioned.fill(child: _BackgroundMap()),
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.3,
          minChildSize: 0.15,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return FutureBuilder<List<ProductModel>>(
              future: _productsFuture ??= _productService.getActiveProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return _CatalogSheetShell(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      children: const [
                        Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00796B),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _CatalogSheetShell(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _CatalogErrorCard(error: '${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final products = snapshot.data ?? <ProductModel>[];
                if (products.isEmpty) {
                  return _CatalogSheetShell(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: const [
                        _CatalogEmptyCard(),
                      ],
                    ),
                  );
                }

                return _CatalogSheetContent(
                  products: products,
                  scrollController: scrollController,
                  showProducts: showProducts,
                  activeCategoryId: activeCategoryId,
                  onCategoryTap: _openCategory,
                  onBackToCategories: _backToCategories,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _openCategory(String categoryId) async {
    setState(() {
      activeCategoryId = categoryId;
      showProducts = true;
    });
    await _sheetController.animateTo(
      0.9,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _backToCategories() async {
    setState(() {
      showProducts = false;
      activeCategoryId = null;
    });
    await _sheetController.animateTo(
      0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

/// Cabecera fija: ubicación, acciones y búsqueda (no se oculta al mover el sheet).
class _FixedHomeHeader extends StatelessWidget {
  const _FixedHomeHeader({
    required this.addressLabel,
    required this.slate900,
    required this.onCartTap,
  });

  final String addressLabel;
  final Color slate900;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entregar en:',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                addressLabel,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: slate900,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: Color(0xFF475569),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const _RoundActionIcon(
                icon: Icons.notifications_none_rounded,
              ),
              const SizedBox(width: 10),
              _RoundActionIcon(
                icon: Icons.shopping_cart_outlined,
                badgeCount: 2,
                onTap: onCartTap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Busca tu plato favorito en Trujillo...',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenedor blanco del catálogo con solo esquinas superiores redondeadas.
class _CatalogSheetShell extends StatelessWidget {
  const _CatalogSheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _BackgroundMap extends StatefulWidget {
  const _BackgroundMap();

  @override
  State<_BackgroundMap> createState() => _BackgroundMapState();
}

class _BackgroundMapState extends State<_BackgroundMap> {
  bool _mapLoaded = false;
  bool _showMapError = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (!_mapLoaded) {
        setState(() => _showMapError = true);
      }
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(-8.1091, -79.0215),
            zoom: 13.8,
          ),
          mapType: MapType.normal,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          onCameraIdle: () {
            if (_mapLoaded) return;
            _timeout?.cancel();
            if (!mounted) return;
            setState(() {
              _mapLoaded = true;
              _showMapError = false;
            });
          },
        ),
        if (_showMapError)
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  'Mapa no disponible. Revisa API Key, package name y SHA-1 de Android.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF334155),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundActionIcon extends StatelessWidget {
  const _RoundActionIcon({
    required this.icon,
    this.badgeCount = 0,
    this.onTap,
  });

  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF334155), size: 20),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

class _CatalogSheetContent extends StatelessWidget {
  const _CatalogSheetContent({
    required this.products,
    required this.scrollController,
    required this.showProducts,
    required this.activeCategoryId,
    required this.onCategoryTap,
    required this.onBackToCategories,
  });

  final List<ProductModel> products;
  final ScrollController scrollController;
  final bool showProducts;
  final String? activeCategoryId;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onBackToCategories;

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _uiCategories.firstWhere(
      (c) => c.id == activeCategoryId,
      orElse: () => _uiCategories.first,
    );
    final filteredProducts = activeCategoryId == null
        ? <ProductModel>[]
        : products.where((p) => p.displayCategoryId == activeCategoryId).toList();

    return _CatalogSheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!showProducts)
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: _uiCategories.length,
                itemBuilder: (context, index) {
                  final category = _uiCategories[index];
                  return _CategoryLargeCard(
                    category: category,
                    onTap: () => onCategoryTap(category.id),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: onBackToCategories,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            selectedCategory.name,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(24),
                            children: [
                              Center(
                                child: Text(
                                  'No hay productos para esta categoria.',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ProductCatalogCard(product: product),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryLargeCard extends StatelessWidget {
  const _CategoryLargeCard({required this.category, required this.onTap});

  final _UiCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FFFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: const Color(0xFF00796B)),
              ),
              const Spacer(),
              Text(
                category.name,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Toca para explorar',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UiCategory {
  const _UiCategory({required this.id, required this.name, required this.icon});

  final String id;
  final String name;
  final IconData icon;
}

const List<_UiCategory> _uiCategories = [
  _UiCategory(
    id: 'cmn446gk40001v3q0kpxivvdy',
    name: 'Platos de Fondo',
    icon: Icons.lunch_dining,
  ),
  _UiCategory(
    id: 'cmn446gu80002v3q0roy3yxgx',
    name: 'Bebidas',
    icon: Icons.local_drink,
  ),
  _UiCategory(
    id: 'cmn446gz70003v3q0dnbvntev',
    name: 'Postres',
    icon: Icons.cake,
  ),
];

class _ProductCatalogCard extends StatelessWidget {
  const _ProductCatalogCard({required this.product});

  final ProductModel product;

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
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.displayImageUrl.isEmpty
                ? Container(
                    width: 82,
                    height: 82,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.fastfood, color: Color(0xFF94A3B8)),
                  )
                : Image.network(
                    product.displayImageUrl,
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 82,
                      height: 82,
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(
                        Icons.restaurant,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.displayDescription.isEmpty
                      ? 'Sin descripcion disponible'
                      : product.displayDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'S/ ${product.displayPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF00796B),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () async {
                        final session = Supabase.instance.client.auth.currentSession;
                        if (session == null) {
                          await showAuthBarrierBottomSheet(
                            context,
                            dishName: product.displayName,
                          );
                          return;
                        }
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${product.displayName} anadido al carrito',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00796B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailPage(product: product),
                          ),
                        );
                      },
                      child: Text(
                        'Ver',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogErrorCard extends StatelessWidget {
  const _CatalogErrorCard({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No se pudo cargar el catalogo.\n$error',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: const Color(0xFF475569)),
        ),
      ),
    );
  }
}

class _CatalogEmptyCard extends StatelessWidget {
  const _CatalogEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No hay productos activos para mostrar.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: const Color(0xFF475569)),
        ),
      ),
    );
  }
}

class _SimpleSection extends StatelessWidget {
  const _SimpleSection({
    required super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF64748B)),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


