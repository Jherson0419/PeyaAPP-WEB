import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Línea legible tipo calle + distrito (para el selector de mapa).
Future<String?> reverseGeocodeStreetLine(double latitude, double longitude) async {
  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;
    final street = p.street?.trim();
    final thoroughfare = p.thoroughfare?.trim();
    final subThoroughfare = p.subThoroughfare?.trim();
    final name = p.name?.trim();
    final locality = p.locality?.trim();
    String? line;
    if (street != null && street.isNotEmpty) {
      line = street;
    } else if (thoroughfare != null && thoroughfare.isNotEmpty) {
      line = thoroughfare;
      if (subThoroughfare != null && subThoroughfare.isNotEmpty) {
        line = '$line $subThoroughfare';
      }
    } else if (name != null && name.isNotEmpty) {
      line = name;
    }
    if (line != null && line.isNotEmpty) {
      if (locality != null && locality.isNotEmpty && !line.toLowerCase().contains(locality.toLowerCase())) {
        return '$line, $locality';
      }
      return line;
    }
    if (locality != null && locality.isNotEmpty) return locality;
    final admin = p.administrativeArea?.trim();
    if (admin != null && admin.isNotEmpty) return admin;
    return null;
  } catch (_) {
    return null;
  }
}

/// Dirección corta para la cabecera (geocodificación inversa).
Future<String?> reverseGeocodeShortLabel(double latitude, double longitude) async {
  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;
    final street = p.street?.trim();
    final subLocal = p.subLocality?.trim();
    final locality = p.locality?.trim();
    final parts = <String>[];
    if (street != null && street.isNotEmpty) parts.add(street);
    if (subLocal != null && subLocal.isNotEmpty) parts.add(subLocal);
    if (locality != null && locality.isNotEmpty) parts.add(locality);
    if (parts.isEmpty) {
      final admin = p.administrativeArea?.trim();
      if (admin != null && admin.isNotEmpty) return admin;
      final country = p.country?.trim();
      if (country != null && country.isNotEmpty) return country;
      return null;
    }
    return parts.take(2).join(', ');
  } catch (_) {
    return null;
  }
}

double calculateDistanceInKm(LatLng pos1, LatLng pos2) {
  final meters = Geolocator.distanceBetween(
    pos1.latitude,
    pos1.longitude,
    pos2.latitude,
    pos2.longitude,
  );
  return meters / 1000;
}

