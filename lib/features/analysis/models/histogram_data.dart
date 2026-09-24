import 'dart:math' as math;

/// Encapsulates 256-bin histogram distributions for RGB and Luminance channels.
class HistogramData {
  const HistogramData({
    required this.red,
    required this.green,
    required this.blue,
    required this.luminance,
    required this.maxCount,
    required this.totalPixels,
    required this.shadowClipPercentage,
    required this.highlightClipPercentage,
  });

  final List<int> red;
  final List<int> green;
  final List<int> blue;
  final List<int> luminance;
  final int maxCount;
  final int totalPixels;
  final double shadowClipPercentage;
  final double highlightClipPercentage;

  bool get hasShadowClipping => shadowClipPercentage > 2.0;
  bool get hasHighlightClipping => highlightClipPercentage > 2.0;

  /// Empty fallback histogram.
  factory HistogramData.empty() {
    return HistogramData(
      red: List.filled(256, 0),
      green: List.filled(256, 0),
      blue: List.filled(256, 0),
      luminance: List.filled(256, 0),
      maxCount: 1,
      totalPixels: 0,
      shadowClipPercentage: 0.0,
      highlightClipPercentage: 0.0,
    );
  }

  /// Builds histogram data from raw 256-element bins.
  factory HistogramData.fromBins({
    required List<int> red,
    required List<int> green,
    required List<int> blue,
    required List<int> luminance,
    required int totalPixels,
  }) {
    int maxVal = 1;
    for (int i = 0; i < 256; i++) {
      maxVal = math.max(maxVal, red[i]);
      maxVal = math.max(maxVal, green[i]);
      maxVal = math.max(maxVal, blue[i]);
      maxVal = math.max(maxVal, luminance[i]);
    }

    if (totalPixels <= 0) {
      return HistogramData.empty();
    }

    // Shadow clipping: pixels with luminance <= 4
    int shadowCount = 0;
    for (int i = 0; i <= 4; i++) {
      shadowCount += luminance[i];
    }

    // Highlight clipping: pixels with luminance >= 251
    int highlightCount = 0;
    for (int i = 251; i < 256; i++) {
      highlightCount += luminance[i];
    }

    final shadowClip = (shadowCount / totalPixels) * 100.0;
    final highlightClip = (highlightCount / totalPixels) * 100.0;

    return HistogramData(
      red: red,
      green: green,
      blue: blue,
      luminance: luminance,
      maxCount: maxVal,
      totalPixels: totalPixels,
      shadowClipPercentage: shadowClip,
      highlightClipPercentage: highlightClip,
    );
  }
}
