import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Available artistic filter presets.
enum FilterPreset {
  none('Original'),
  vivid('Vivid'),
  bw('Monochrome'),
  vintage('Vintage'),
  cyberpunk('Cyberpunk'),
  cinematic('Cinematic');

  final String label;
  const FilterPreset(this.label);
}

/// Supported aspect ratios for cropping.
enum CropAspectRatio {
  free('Freeform', null),
  original('Original', null),
  square('1:1 Square', 1.0),
  portrait45('4:5 Portrait', 4 / 5),
  story916('9:16 Story', 9 / 16),
  landscape169('16:9 Landscape', 16 / 9),
  standard43('4:3 Standard', 4 / 3);

  final String label;
  final double? ratio;
  const CropAspectRatio(this.label, this.ratio);
}

/// Immutable state holding non-destructive image adjustments.
@immutable
class EditorParameters {
  const EditorParameters({
    this.rotationQuarterTurns = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.brightness = 0.0, // -1.0 to 1.0
    this.contrast = 0.0,   // -1.0 to 1.0
    this.saturation = 0.0, // -1.0 to 1.0
    this.exposure = 0.0,   // -1.0 to 1.0
    this.vignette = 0.0,   // 0.0 to 1.0
    this.preset = FilterPreset.none,
    this.cropRect,
  });

  final int rotationQuarterTurns; // 0, 1, 2, 3 (each is 90 deg clockwise)
  final bool flipHorizontal;
  final bool flipVertical;
  final double brightness;
  final double contrast;
  final double saturation;
  final double exposure;
  final double vignette;
  final FilterPreset preset;
  final Rect? cropRect; // Normalized [0, 0, 1, 1]

  double get rotationDegrees => (rotationQuarterTurns % 4) * 90.0;
  double get rotationRadians => (rotationQuarterTurns % 4) * (math.pi / 2);

  bool get isModified =>
      rotationQuarterTurns % 4 != 0 ||
      flipHorizontal ||
      flipVertical ||
      brightness != 0.0 ||
      contrast != 0.0 ||
      saturation != 0.0 ||
      exposure != 0.0 ||
      vignette != 0.0 ||
      preset != FilterPreset.none ||
      cropRect != null;

  EditorParameters copyWith({
    int? rotationQuarterTurns,
    bool? flipHorizontal,
    bool? flipVertical,
    double? brightness,
    double? contrast,
    double? saturation,
    double? exposure,
    double? vignette,
    FilterPreset? preset,
    Rect? Function()? cropRect,
  }) {
    return EditorParameters(
      rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      exposure: exposure ?? this.exposure,
      vignette: vignette ?? this.vignette,
      preset: preset ?? this.preset,
      cropRect: cropRect != null ? cropRect() : this.cropRect,
    );
  }

  /// Calculates the 4x5 ColorMatrix corresponding to the adjustments and preset.
  List<double> calculateColorMatrix() {
    // 1. Identity Matrix
    var matrix = <double>[
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];

    // 2. Exposure & Brightness
    final b = (brightness + exposure) * 255;

    // 3. Contrast: scale around 128
    // factor = (259 * (c + 255)) / (255 * (259 - c)) where c in [-255, 255]
    final cVal = contrast.clamp(-1.0, 1.0) * 255;
    final cFactor = (259 * (cVal + 255)) / (255 * (259 - cVal).clamp(1.0, 514.0));
    final cOffset = 128 * (1 - cFactor);

    // 4. Saturation
    // s in [0, 2] where 0 is grayscale, 1 is normal, >1 oversaturated
    final s = (saturation + 1.0).clamp(0.0, 2.0);
    const lumR = 0.3086;
    const lumG = 0.6094;
    const lumB = 0.0820;

    final sr = (1 - s) * lumR;
    final sg = (1 - s) * lumG;
    final sb = (1 - s) * lumB;

    matrix = [
      (sr + s) * cFactor, sg * cFactor, sb * cFactor, 0, b + cOffset,
      sr * cFactor, (sg + s) * cFactor, sb * cFactor, 0, b + cOffset,
      sr * cFactor, sg * cFactor, (sb + s) * cFactor, 0, b + cOffset,
      0, 0, 0, 1, 0,
    ];

    // 5. Preset Multipliers
    switch (preset) {
      case FilterPreset.vivid:
        matrix[0] *= 1.15;
        matrix[6] *= 1.15;
        matrix[12] *= 1.15;
        break;
      case FilterPreset.bw:
        final r = matrix[0] * 0.299 + matrix[1] * 0.587 + matrix[2] * 0.114;
        matrix = [
          r, r, r, 0, matrix[4],
          r, r, r, 0, matrix[4],
          r, r, r, 0, matrix[4],
          0, 0, 0, 1, 0,
        ];
        break;
      case FilterPreset.vintage:
        matrix[0] *= 1.2;  // warmer red
        matrix[6] *= 1.05; // warm green
        matrix[12] *= 0.85; // muted blue
        matrix[4] += 15;
        break;
      case FilterPreset.cyberpunk:
        matrix[0] *= 1.3;  // neon pink/red
        matrix[6] *= 0.9;
        matrix[12] *= 1.4; // electric cyan/blue
        matrix[4] += 20;
        matrix[14] += 30;
        break;
      case FilterPreset.cinematic:
        matrix[0] *= 0.95;
        matrix[6] *= 1.05; // teal shadow
        matrix[12] *= 1.1; // teal tint
        matrix[4] += 5;
        break;
      case FilterPreset.none:
        break;
    }

    return matrix;
  }
}

/// State of the active Editor session.
@immutable
class EditorState {
  const EditorState({
    required this.filePath,
    required this.currentParams,
    this.undoStack = const [],
    this.redoStack = const [],
    this.isProcessing = false,
  });

  final String filePath;
  final EditorParameters currentParams;
  final List<EditorParameters> undoStack;
  final List<EditorParameters> redoStack;
  final bool isProcessing;

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  EditorState copyWith({
    String? filePath,
    EditorParameters? currentParams,
    List<EditorParameters>? undoStack,
    List<EditorParameters>? redoStack,
    bool? isProcessing,
  }) {
    return EditorState(
      filePath: filePath ?? this.filePath,
      currentParams: currentParams ?? this.currentParams,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
