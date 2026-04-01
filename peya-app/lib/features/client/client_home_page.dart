import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:peya_app/models/vendor_branch_model.dart';
import 'package:peya_app/models/vertical_model.dart';
import 'package:peya_app/services/branch_service.dart';
import 'package:peya_app/features/client/cart_page.dart';
import 'package:peya_app/features/client/location_picker_page.dart';
import 'package:peya_app/features/client/store_details_page.dart';
import 'package:peya_app/features/client/stores_by_vertical_page.dart';
import 'package:peya_app/providers/store_providers.dart';
import 'package:peya_app/state/app_flow_state.dart';
import 'package:peya_app/state/cart_state.dart';
import 'package:peya_app/utils/location_utils.dart';
import 'package:peya_app/utils/map_marker_icon_helper.dart';
import 'dart:async';
import 'dart:math' as math;

/// Espacio inferior para que el contenido del sheet no quede tapado por el sistema
/// ni visualmente pegado a la barra de navegación inferior.
double _catalogBottomReserve(BuildContext context) {
  final m = MediaQuery.of(context);
  return math.max(
    16.0,
    m.padding.bottom + m.viewPadding.bottom + 12.0,
  );
}

EdgeInsets _catalogSheetVerticalPadding(BuildContext context) {
  final b = _catalogBottomReserve(context);
  return EdgeInsets.fromLTRB(0, 48, 0, b);
}

String _deliveryHeaderLabel(AppFlowState appState) {
  final label = appState.deliveryAddressLabel?.trim();
  if (label != null && label.isNotEmpty) {
    return label;
  }
  if (appState.hasDeliveryLocation) {
    final lat = appState.deliveryLat!;
    final lng = appState.deliveryLng!;
    return 'Cerca de ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }
  return 'Trujillo Centro';
}

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  static const Color _brandGreen = Color(0xFF00796B);
  static const Color _slate900 = Color(0xFF0F172A);
  /// Reparto inicial: 50 % mapa visible / 50 % panel (zona central bajo la cabecera).
  static const double _sheetInitialSize = 0.5;
  /// El panel no baja del 50 %: reparto mínimo mitad mapa / mitad panel.
  static const double _sheetMinSize = 0.5;
  /// Al arrastrar hacia arriba el panel ocupa toda la zona central (100 %).
  static const double _sheetMaxSize = 1.0;
  int _currentIndex = 0;
  Future<({List<VerticalModel> verticals, List<VendorBranchModel> branches})>?
      _homeDiscoverFuture;
  final DraggableScrollableController sheetController =
      DraggableScrollableController();

  Route<void> _fullScreenRoute(Widget page) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CupertinoPageRoute<void>(builder: (_) => page);
      default:
        return MaterialPageRoute<void>(builder: (_) => page);
    }
  }

  @override
  void dispose() {
    sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppFlowScope.of(context);
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final addressLabel = _deliveryHeaderLabel(appState);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                ListenableBuilder(
                  listenable: CartScope.of(context),
                  builder: (context, _) => _FixedHomeHeader(
                    addressLabel: addressLabel,
                    slate900: _slate900,
                    onLocationTap: () async {
                      if (!context.mounted) return;
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const LocationPickerPage(),
                        ),
                      );
                    },
                    onCartTap: () async {
                      if (!context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CartPage(),
                        ),
                      );
                    },
                    cartBadgeCount: CartScope.of(context).itemCount,
                  ),
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
      },
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
    return KeyedSubtree(
      key: const ValueKey('home-map-sheet'),
      child: Stack(
        children: [
          const Positioned.fill(child: _BackgroundMap()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 72,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x26000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 90,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x26000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            controller: sheetController,
            initialChildSize: _sheetInitialSize,
            minChildSize: _sheetMinSize,
            maxChildSize: _sheetMaxSize,
            builder: (context, scrollController) {
              return _buildHomeDiscoverBody(scrollController: scrollController);
            },
          ),
          Positioned(
            right: 16,
            bottom: 18,
            child: FloatingActionButton(
              heroTag: 'map-cart-fab',
              backgroundColor: const Color(0xFF00796B),
              foregroundColor: Colors.white,
              onPressed: () async {
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CartPage(),
                  ),
                );
              },
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDiscoverBody({required ScrollController scrollController}) {
    _homeDiscoverFuture ??= () async {
      final verticals = await verticalsProvider();
      final branches = await BranchService().getActiveBranches();
      return (verticals: verticals, branches: branches);
    }();

    return FutureBuilder<({List<VerticalModel> verticals, List<VendorBranchModel> branches})>(
      future: _homeDiscoverFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _CatalogSheetShell(
            child: ListView(
              controller: scrollController,
              padding: _catalogSheetVerticalPadding(context),
              children: const [
                Center(
                  child: CircularProgressIndicator(color: Color(0xFF00796B)),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _CatalogSheetShell(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(16, 48, 16, _catalogBottomReserve(context)),
              children: [
                _CatalogErrorCard(error: '${snapshot.error}'),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final verticals = data.verticals;
        final branches = data.branches;

        if (verticals.isEmpty && branches.isEmpty) {
          return _CatalogSheetShell(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(16, 48, 16, _catalogBottomReserve(context)),
              children: const [
                _CatalogEmptyCard(
                  message: 'No hay verticales ni tiendas disponibles. Revisa tu conexión o vuelve más tarde.',
                ),
              ],
            ),
          );
        }

        final appFlow = AppFlowScope.of(context);
        final userLat = appFlow.deliveryLat;
        final userLng = appFlow.deliveryLng;

        final orderedBranches = List<VendorBranchModel>.of(branches);
        if (userLat != null && userLng != null && orderedBranches.isNotEmpty) {
          orderedBranches.sort((a, b) {
            final da = calculateDistanceInKm(
              LatLng(userLat, userLng),
              LatLng(a.latitude, a.longitude),
            );
            final db = calculateDistanceInKm(
              LatLng(userLat, userLng),
              LatLng(b.latitude, b.longitude),
            );
            return da.compareTo(db);
          });
        }

        return _CatalogSheetShell(
          child: _HomeDiscoverSheetContent(
            verticals: verticals,
            branches: orderedBranches,
            scrollController: scrollController,
            userLat: userLat,
            userLng: userLng,
            onVerticalTap: (verticalId, verticalName) {
              Navigator.of(context).push(
                _fullScreenRoute(
                  StoresByVerticalPage(
                    verticalId: verticalId,
                    verticalName: verticalName,
                  ),
                ),
              );
            },
            onBranchTap: (branch) {
              Navigator.of(context).push(
                _fullScreenRoute(
                  StoreDetailsPage(
                    storeId: branch.id,
                    storeName: branch.name,
                    storeLogoUrl: branch.iconUrl,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

}

/// Cabecera fija: ubicación, acciones y búsqueda (no se oculta al mover el sheet).
class _FixedHomeHeader extends StatelessWidget {
  const _FixedHomeHeader({
    required this.addressLabel,
    required this.slate900,
    required this.onLocationTap,
    required this.onCartTap,
    required this.cartBadgeCount,
  });

  final String addressLabel;
  final Color slate900;
  final VoidCallback onLocationTap;
  final VoidCallback onCartTap;
  final int cartBadgeCount;

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
                  onTap: onLocationTap,
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
                badgeCount: cartBadgeCount,
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
                    'Busca tiendas o categorías en Trujillo...',
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
  final BranchService _branchService = BranchService();
  GoogleMapController? _mapController;
  Set<Marker> _branchMarkers = {};
  LatLng? _userLatLng;
  static const LatLng _defaultCenter = LatLng(-8.1091, -79.0215);

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (!_mapLoaded) {
        setState(() => _showMapError = true);
      }
    });
    _bootstrapMapData();
  }

  Future<void> _bootstrapMapData() async {
    final userLatLng = await _loadUserLocation();
    if (!mounted) return;
    setState(() => _userLatLng = userLatLng);
    if (userLatLng != null) {
      AppFlowScope.of(context).setDeliveryLocation(
        lat: userLatLng.latitude,
        lng: userLatLng.longitude,
      );
      unawaited(_applyReverseGeocode(userLatLng));
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(userLatLng, 13.8),
      );
    }
    await _loadBranches();
  }

  Future<LatLng?> _loadUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition();
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _applyReverseGeocode(LatLng pos) async {
    final label = await reverseGeocodeShortLabel(pos.latitude, pos.longitude);
    if (!mounted || label == null || label.trim().isEmpty) return;
    AppFlowScope.of(context).setDeliveryLocation(
      lat: pos.latitude,
      lng: pos.longitude,
      addressLabel: label.trim(),
    );
  }

  Future<void> _loadBranches() async {
    try {
      final list = await _branchService.getActiveBranches();

      final markers = <Marker>{};
      for (final VendorBranchModel b in list) {
        final customIcon = (b.iconUrl != null && b.iconUrl!.trim().isNotEmpty)
            ? await MapMarkerIconHelper.fromNetworkUrl(b.iconUrl!, size: 46)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        markers.add(
          Marker(
            markerId: MarkerId('branch_${b.id}'),
            position: LatLng(b.latitude, b.longitude),
            icon: customIcon,
            infoWindow: InfoWindow(
              title: b.name,
              snippet: b.address,
            ),
            onTap: () {
              CartScope.of(context).selectBranch(b);
            },
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _branchMarkers = markers;
      });
    } catch (_) {
      // Tabla o RLS: el mapa sigue mostrándose sin marcadores de tiendas.
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _userLatLng ?? _defaultCenter,
            zoom: 13.8,
          ),
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          compassEnabled: false,
          markers: _branchMarkers,
          onMapCreated: (controller) async {
            _mapController = controller;
            final target = _userLatLng ?? _defaultCenter;
            await controller.animateCamera(
              CameraUpdate.newLatLngZoom(target, 13.8),
            );
          },
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

/// Panel del home: verticales (grid) + tiendas destacadas (carrusel). Sin productos sueltos.
class _HomeDiscoverSheetContent extends StatelessWidget {
  const _HomeDiscoverSheetContent({
    required this.verticals,
    required this.branches,
    required this.scrollController,
    required this.userLat,
    required this.userLng,
    required this.onVerticalTap,
    required this.onBranchTap,
  });

  final List<VerticalModel> verticals;
  final List<VendorBranchModel> branches;
  final ScrollController scrollController;
  final double? userLat;
  final double? userLng;
  final void Function(String verticalId, String verticalName) onVerticalTap;
  final ValueChanged<VendorBranchModel> onBranchTap;

  @override
  Widget build(BuildContext context) {
    final bottom = _catalogBottomReserve(context);

    return CustomScrollView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
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
              const SizedBox(height: 16),
              if (verticals.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Verticales',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        if (verticals.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final v = verticals[index];
                  return _VerticalGridTile(
                    vertical: v,
                    onTap: () => onVerticalTap(v.id, v.name),
                  );
                },
                childCount: verticals.length,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, branches.isEmpty ? 8 : 12),
            child: Row(
              children: [
                Text(
                  'Tiendas cerca de ti',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Icon(Icons.storefront_outlined, size: 20, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
        if (branches.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Aún no hay tiendas disponibles en el mapa.',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: SizedBox(
              height: 124,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemCount: branches.length,
                itemBuilder: (context, i) {
                  final b = branches[i];
                  final km = (userLat != null && userLng != null)
                      ? calculateDistanceInKm(
                          LatLng(userLat!, userLng!),
                          LatLng(b.latitude, b.longitude),
                        )
                      : null;
                  return _FeaturedBranchChip(
                    branch: b,
                    distanceKm: km,
                    onTap: () => onBranchTap(b),
                  );
                },
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: bottom + 8)),
      ],
    );
  }
}

class _VerticalGridTile extends StatelessWidget {
  const _VerticalGridTile({
    required this.vertical,
    required this.onTap,
  });

  final VerticalModel vertical;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = vertical.imageUrl?.trim();
    final hasImage = url != null && url.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (context, u) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF00796B),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, u, e) => _verticalPlaceholder(),
                          )
                        : _verticalPlaceholder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vertical.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ver tiendas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _verticalPlaceholder() {
    return Container(
      color: const Color(0xFFE6FFFA),
      child: const Center(
        child: Icon(Icons.apps_rounded, color: Color(0xFF00796B), size: 36),
      ),
    );
  }
}

class _FeaturedBranchChip extends StatelessWidget {
  const _FeaturedBranchChip({
    required this.branch,
    required this.onTap,
    this.distanceKm,
  });

  final VendorBranchModel branch;
  final VoidCallback onTap;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Hero(
                tag: 'branch-logo-${branch.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: branch.iconUrl != null && branch.iconUrl!.isNotEmpty
                      ? Image.network(
                          branch.iconUrl!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _branchPlaceholder(),
                        )
                      : _branchPlaceholder(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      branch.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (distanceKm != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${distanceKm!.toStringAsFixed(1)} km',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF00796B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _branchPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.storefront, color: Color(0xFF94A3B8), size: 28),
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
  const _CatalogEmptyCard({this.message = 'No hay productos activos para mostrar.'});

  final String message;

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
          message,
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


