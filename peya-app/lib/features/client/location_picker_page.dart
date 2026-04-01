import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peya_app/features/client/client_home_page.dart';
import 'package:peya_app/state/app_flow_state.dart';
import 'package:peya_app/utils/location_utils.dart';
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
  bool _confirmingDelivery = false;
  GoogleMapController? _mapController;
  Timer? _mapTimeoutTimer;
  Timer? _geocodeDebounce;

  final TextEditingController _referenceController = TextEditingController();
  String? _streetPreview;
  bool _geocodingPreview = false;

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
        _scheduleGeocode();
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
        _scheduleGeocode();
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
      _scheduleGeocode();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationDenied = true;
      });
      _scheduleGeocode();
    }
  }

  void _scheduleGeocode() {
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _geocodingPreview = true);
      final line = await reverseGeocodeStreetLine(
        _selectedPoint.latitude,
        _selectedPoint.longitude,
      );
      if (!mounted) return;
      setState(() {
        _streetPreview = line;
        _geocodingPreview = false;
      });
    });
  }

  @override
  void dispose() {
    _mapTimeoutTimer?.cancel();
    _geocodeDebounce?.cancel();
    _referenceController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
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
                if (!_mapLoaded) {
                  _mapTimeoutTimer?.cancel();
                  if (mounted) {
                    setState(() {
                      _mapLoaded = true;
                      _showMapError = false;
                    });
                  }
                }
                _scheduleGeocode();
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
                        'Mueve el mapa y el pin indica el punto. Puedes escribir tu dirección abajo.',
                        style: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Pin fijo en el centro + dirección encima
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: _geocodingPreview
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00796B)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Buscando calle…',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _streetPreview ??
                                  'Mueve el mapa: aquí verás la calle o zona del pin.',
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                                height: 1.25,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const IgnorePointer(
                  child: Icon(
                    Icons.location_on,
                    size: 56,
                    color: Color(0xFF00796B),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  12 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _referenceController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Referencia (opcional): piso, color de portón, etc.',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF00796B), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      ),
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
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
                        onPressed: _confirmingDelivery
                            ? null
                            : () async {
                                setState(() => _confirmingDelivery = true);
                                final appState = AppFlowScope.of(context);
                                String? autoLabel = _streetPreview?.trim();
                                if (autoLabel == null || autoLabel.isEmpty) {
                                  autoLabel = await reverseGeocodeShortLabel(
                                    _selectedPoint.latitude,
                                    _selectedPoint.longitude,
                                  );
                                }
                                final note = _referenceController.text.trim();
                                final parts = <String>[];
                                if (autoLabel != null && autoLabel.isNotEmpty) {
                                  parts.add(autoLabel);
                                }
                                if (note.isNotEmpty) parts.add(note);
                                final combined = parts.join(' · ');
                                if (!mounted) return;
                                appState.setDeliveryLocation(
                                  lat: _selectedPoint.latitude,
                                  lng: _selectedPoint.longitude,
                                  addressLabel: combined.isEmpty ? null : combined,
                                );

                                if (!context.mounted) return;
                                final nav = Navigator.of(context);
                                if (nav.canPop()) {
                                  nav.pop();
                                } else {
                                  nav.pushReplacement(
                                    PageRouteBuilder<void>(
                                      transitionDuration: const Duration(milliseconds: 360),
                                      pageBuilder: (context, animation, secondaryAnimation) {
                                        return const ClientHomePage();
                                      },
                                      transitionsBuilder:
                                          (context, animation, secondaryAnimation, child) {
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
                                          child: SlideTransition(
                                            position: slide,
                                            child: child,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }
                              },
                        child: _confirmingDelivery
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Confirmar Punto de Entrega',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
