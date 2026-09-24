import 'package:flutter_test/flutter_test.dart';
import 'package:apertix/features/analysis/models/histogram_data.dart';
import 'package:apertix/features/editor/services/auto_enhance_service.dart';

void main() {
  group('Histogram Engine & Analysis Tests', () {
    test('Empty fallback histogram has safe zero/default bounds', () {
      final hist = HistogramData.empty();
      expect(hist.totalPixels, 0);
      expect(hist.maxCount, 1);
      expect(hist.hasShadowClipping, false);
      expect(hist.hasHighlightClipping, false);
      expect(hist.red.length, 256);
      expect(hist.green.length, 256);
      expect(hist.blue.length, 256);
      expect(hist.luminance.length, 256);
    });

    test('Computes clipping metrics correctly for shadow/highlight clipped data', () {
      final red = List<int>.filled(256, 0);
      final green = List<int>.filled(256, 0);
      final blue = List<int>.filled(256, 0);
      final lum = List<int>.filled(256, 0);

      // Add 100 shadow pixels (indices 0..4) and 900 midtones (index 128)
      for (int i = 0; i <= 4; i++) {
        lum[i] = 20;
      }
      lum[128] = 900;
      const total = 1000;

      final hist = HistogramData.fromBins(
        red: red,
        green: green,
        blue: blue,
        luminance: lum,
        totalPixels: total,
      );

      // 100 / 1000 = 10.0% shadow clipping
      expect(hist.shadowClipPercentage, closeTo(10.0, 0.01));
      expect(hist.hasShadowClipping, true);
      expect(hist.hasHighlightClipping, false);
    });
  });

  group('AutoEnhanceService Engine Tests', () {
    const service = AutoEnhanceService();

    test('Underexposed image produces positive exposure boost', () {
      final red = List<int>.filled(256, 0);
      final green = List<int>.filled(256, 0);
      final blue = List<int>.filled(256, 0);
      final lum = List<int>.filled(256, 0);

      // Concentration in dark shadows (intensity 40)
      lum[40] = 1000;
      red[40] = 1000;
      green[40] = 1000;
      blue[40] = 1000;

      final hist = HistogramData.fromBins(
        red: red,
        green: green,
        blue: blue,
        luminance: lum,
        totalPixels: 1000,
      );

      final result = service.calculateEnhancement(hist);
      expect(result.exposure > 0, true, reason: 'Underexposed photo must receive positive exposure boost');
      expect(result.exposure <= 0.45, true);
    });

    test('Overexposed image produces negative exposure compensation', () {
      final red = List<int>.filled(256, 0);
      final green = List<int>.filled(256, 0);
      final blue = List<int>.filled(256, 0);
      final lum = List<int>.filled(256, 0);

      // Concentration in bright highlights (intensity 220)
      lum[220] = 1000;
      red[220] = 1000;
      green[220] = 1000;
      blue[220] = 1000;

      final hist = HistogramData.fromBins(
        red: red,
        green: green,
        blue: blue,
        luminance: lum,
        totalPixels: 1000,
      );

      final result = service.calculateEnhancement(hist);
      expect(result.exposure < 0, true, reason: 'Overexposed photo must receive negative exposure compensation');
    });

    test('Narrow dynamic range produces positive contrast boost', () {
      final red = List<int>.filled(256, 0);
      final green = List<int>.filled(256, 0);
      final blue = List<int>.filled(256, 0);
      final lum = List<int>.filled(256, 0);

      // Concentrated flat midtones (range 120..130 -> dynamic range only 10)
      for (int i = 120; i <= 130; i++) {
        lum[i] = 100;
        red[i] = 100;
        green[i] = 100;
        blue[i] = 100;
      }

      final hist = HistogramData.fromBins(
        red: red,
        green: green,
        blue: blue,
        luminance: lum,
        totalPixels: 1100,
      );

      final result = service.calculateEnhancement(hist);
      expect(result.contrast > 0, true, reason: 'Flat low-contrast photo must receive positive contrast boost');
    });
  });
}
