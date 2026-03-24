import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peya_app/features/client/client_home_page.dart';
import 'package:peya_app/state/app_flow_state.dart';
import 'dart:async';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const LatLng _trujillo = LatLng(-8.1091, -79.0215);
  LatLng _selectedPoint = _trujillo;
  bool _isLoadingLocation = true;
  bool _locationDenied = false;
  bool _mapLoaded = false;
  bool _showMapError = false;
  GoogleMapController? _mapController;
  Timer? _mapTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _mapTimeoutTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (!_mapLoaded) {
        setState(() => _showMapError = true);
      }
    });
    _requestAndLoadLocation();
  }

  Future<void> _requestAndLoadLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationDenied = true;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationDenied = true;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _selectedPoint = point;
        _isLoadingLocation = false;
      });
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationDenied = true;
      });
    }
  }

  @override
  void dispose() {
    _mapTimeoutTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _trujillo,
                zoom: 13.8,
              ),
              myLocationEnabled: !_locationDenied,
              myLocationButtonEnabled: !_locationDenied,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onCameraMove: (position) {
                _selectedPoint = position.target;
              },
              onCameraIdle: () {
                if (_mapLoaded) return;
                _mapTimeoutTimer?.cancel();
                if (!mounted) return;
                setState(() {
                  _mapLoaded = true;
                  _showMapError = false;
                });
              },
            ),
          ),
          if (_showMapError)
            Positioned(
              top: 18,
              left: 16,
              right: 16,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No se pudieron cargar los mosaicos del mapa. Verifica API Key de Google Maps, package name y SHA-1.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF334155),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          if (_isLoadingLocation)
            const Positioned(
              top: 70,
              left: 16,
              right: 16,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Expanded(child: Text('Obteniendo tu ubicacion actual...')),
                    ],
                  ),
                ),
              ),
            ),
          if (_locationDenied && !_isLoadingLocation)
            Positioned(
              top: 70,
              left: 16,
              right: 16,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('No se pudo acceder a tu ubicacion.'),
                      const SizedBox(height: 6),
                      Text(
                        'Usaremos Trujillo por defecto.',
                        style: GoogleFonts.inter(color: const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Center(
            child: IgnorePointer(
              child: Icon(
                Icons.location_pin,
                size: 62,
                color: Color(0xFF00796B),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
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
                      AppFlowScope.of(
                        context,
                      ).setDeliveryLocation(
                        lat: _selectedPoint.latitude,
                        lng: _selectedPoint.longitude,
                      );

                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder<void>(
                          transitionDuration: const Duration(milliseconds: 360),
                          pageBuilder: (context, animation, secondaryAnimation) {
                            return const ClientHomePage();
                          },
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            );
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(position: slide, child: child),
                            );
                          },
                        ),
                      );
                    },
                    child: Text(
                      'Confirmar Punto de Entrega',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
