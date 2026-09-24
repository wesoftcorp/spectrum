import 'dart:math' as math;
import '../../analysis/models/histogram_data.dart';
import '../models/editor_state.dart';

/// Intelligent auto-tone adjustment analyzer based on histogram metrics.
class AutoEnhanceService {
  const AutoEnhanceService();

  /// Analyzes a HistogramData and computes balanced EditorParameters.
  EditorParameters calculateEnhancement(HistogramData histogram) {
    if (histogram.totalPixels == 0) {
      return const EditorParameters();
    }

    final total = histogram.totalPixels.toDouble();

    // 1. Calculate Mean Luminance
    double lumSum = 0;
    for (int i = 0; i < 256; i++) {
      lumSum += i * histogram.luminance[i];
    }
    final meanLum = lumSum / total;

    // 2. Percentile Analysis (5th and 95th percentiles)
    final p5Threshold = total * 0.05;
    final p95Threshold = total * 0.95;
    int p5 = 0;
    int p95 = 255;
    double cumulative = 0;

    for (int i = 0; i < 256; i++) {
      cumulative += histogram.luminance[i];
      if (p5 == 0 && cumulative >= p5Threshold) {
        p5 = i;
      }
      if (cumulative >= p95Threshold) {
        p95 = i;
        break;
      }
    }

    // 3. Exposure compensation
    // Target mean luminance ~128
    double exposureBoost = 0.0;
    if (meanLum < 118) {
      // Underexposed
      exposureBoost = ((128 - meanLum) / 128.0) * 0.35;
    } else if (meanLum > 145) {
      // Overexposed
      exposureBoost = -((meanLum - 128) / 128.0) * 0.25;
    }
    exposureBoost = exposureBoost.clamp(-0.4, 0.45);

    // 4. Contrast enhancement
    // Dynamic range = p95 - p5
    final dynamicRange = p95 - p5;
    double contrastBoost = 0.0;
    if (dynamicRange < 150) {
      // Low contrast / flat image -> boost contrast
      contrastBoost = ((150 - dynamicRange) / 150.0) * 0.30;
    } else if (dynamicRange > 220) {
      // Harsh contrast -> soften slightly
      contrastBoost = -0.05;
    }
    contrastBoost = contrastBoost.clamp(-0.1, 0.35);

    // 5. Brightness adjustment
    double brightnessBoost = 0.0;
    if (meanLum < 90) {
      brightnessBoost = 0.08;
    }

    // 6. Saturation enhancement
    // Check divergence between channels
    double rSum = 0, gSum = 0, bSum = 0;
    for (int i = 0; i < 256; i++) {
      rSum += i * histogram.red[i];
      gSum += i * histogram.green[i];
      bSum += i * histogram.blue[i];
    }
    final rMean = rSum / total;
    final gMean = gSum / total;
    final bMean = bSum / total;
    final colorVariance = math.sqrt(
      math.pow(rMean - meanLum, 2) +
      math.pow(gMean - meanLum, 2) +
      math.pow(bMean - meanLum, 2),
    );

    double saturationBoost = 0.12;
    if (colorVariance < 10) {
      // Washed out colors -> punch up saturation
      saturationBoost = 0.20;
    } else if (colorVariance > 40) {
      // Already vibrant
      saturationBoost = 0.05;
    }

    return EditorParameters(
      exposure: double.parse(exposureBoost.toStringAsFixed(2)),
      contrast: double.parse(contrastBoost.toStringAsFixed(2)),
      brightness: double.parse(brightnessBoost.toStringAsFixed(2)),
      saturation: double.parse(saturationBoost.toStringAsFixed(2)),
    );
  }
}
