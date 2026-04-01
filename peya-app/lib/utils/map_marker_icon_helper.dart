import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerIconHelper {
  static final Map<String, BitmapDescriptor> _cache = {};
  static final BitmapDescriptor _fallback =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

  static Future<BitmapDescriptor> fromNetworkUrl(
    String url, {
    int size = 84,
  }) async {
    final cacheKey = '$url|$size';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return _fallback;
    }

    try {
      final bundle = NetworkAssetBundle(uri);
      final data = await bundle.load(url);
      final bytes = data.buffer.asUint8List();
      // No forzamos width/height para evitar deformar el logo original.
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final markerBytes = await _buildBrandedPin(frame.image, size: size);
      if (markerBytes == null) return _fallback;
      final descriptor = BitmapDescriptor.bytes(markerBytes);
      _cache[cacheKey] = descriptor;
      return descriptor;
    } catch (_) {
      return _fallback;
    }
  }

  static Future<Uint8List?> _buildBrandedPin(
    ui.Image logo, {
    required int size,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final s = size.toDouble();
    final centerX = s / 2;
    final topCenter = ui.Offset(centerX, s * 0.44);
    final circleRadius = s * 0.28;
    final pointerHalf = s * 0.12;
    final pointerTopY = topCenter.dy + circleRadius - 1;
    final pointerTip = ui.Offset(centerX, s * 0.96);

    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x33000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    final pinPath = ui.Path()
      ..moveTo(topCenter.dx - pointerHalf, pointerTopY)
      ..lineTo(topCenter.dx + pointerHalf, pointerTopY)
      ..lineTo(pointerTip.dx, pointerTip.dy)
      ..close();
    canvas.drawPath(pinPath.shift(const ui.Offset(0, 1.5)), shadowPaint);

    final pinPaint = ui.Paint()..color = const ui.Color(0xFF00796B);
    canvas.drawPath(pinPath, pinPaint);

    final ringPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(topCenter, circleRadius + (s * 0.036), ringPaint);

    // Radio útil para el logo: más pequeño si el PNG es muy apaisado o muy alto,
    // para dejar margen blanco dentro del círculo (misma idea que en la web).
    final iw = math.max(1.0, logo.width.toDouble());
    final ih = math.max(1.0, logo.height.toDouble());
    final ar = iw / ih;
    final maxAr = math.max(ar, 1.0 / ar);
    double logoPaintRadius = circleRadius;
    if (maxAr > 1.12) {
      final t = ((maxAr - 1.12) / 2.8).clamp(0.0, 1.0);
      logoPaintRadius = circleRadius * (1.0 - 0.22 * t);
    }

    final logoClip = ui.Path()..addOval(ui.Rect.fromCircle(center: topCenter, radius: circleRadius));
    canvas.save();
    canvas.clipPath(logoClip);
    final innerBg = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(topCenter, circleRadius, innerBg);
    paintImage(
      canvas: canvas,
      rect: ui.Rect.fromCircle(center: topCenter, radius: logoPaintRadius),
      image: logo,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    canvas.restore();

    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFFE2E8F0)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = s * 0.018;
    canvas.drawCircle(topCenter, circleRadius, borderPaint);

    final image = await recorder.endRecording().toImage(size, size);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return png?.buffer.asUint8List();
  }
}

