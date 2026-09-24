import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/histogram_data.dart';

/// Fast background isolate service for computing 256-bin RGB and Luminance histograms.
class HistogramService {
  const HistogramService();

  /// Computes a 256-bin RGB and Luminance histogram from an image file path in a background isolate.
  Future<HistogramData> computeFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return HistogramData.empty();
    }
    final bytes = await file.readAsBytes();
    return computeFromBytes(bytes);
  }

  /// Computes histogram from image bytes in a background isolate.
  Future<HistogramData> computeFromBytes(Uint8List bytes) async {
    return compute(_computeHistogramIsolate, bytes);
  }
}

HistogramData _computeHistogramIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return HistogramData.empty();
  }

  // Downsample to max 480px dimension for ultra-fast sub-10ms calculation
  final img.Image sampled;
  if (decoded.width > 480 || decoded.height > 480) {
    sampled = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? 480 : null,
      height: decoded.height > decoded.width ? 480 : null,
      interpolation: img.Interpolation.nearest,
    );
  } else {
    sampled = decoded;
  }

  final redBins = List<int>.filled(256, 0);
  final greenBins = List<int>.filled(256, 0);
  final blueBins = List<int>.filled(256, 0);
  final lumBins = List<int>.filled(256, 0);

  int totalPixels = 0;
  for (final pixel in sampled) {
    final r = pixel.r.toInt().clamp(0, 255);
    final g = pixel.g.toInt().clamp(0, 255);
    final b = pixel.b.toInt().clamp(0, 255);
    final lum = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);

    redBins[r]++;
    greenBins[g]++;
    blueBins[b]++;
    lumBins[lum]++;
    totalPixels++;
  }

  return HistogramData.fromBins(
    red: redBins,
    green: greenBins,
    blue: blueBins,
    luminance: lumBins,
    totalPixels: totalPixels,
  );
}
