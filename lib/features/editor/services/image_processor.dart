import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import '../models/editor_state.dart';

/// Lightweight, isolate-safe serialization for on-image annotations.
class AnnotationExportData {
  const AnnotationExportData({
    required this.typeIndex, // 0: pen, 1: arrow, 2: rect, 3: circle, 4: text
    required this.points,    // Normalized [0..1] [x, y] coordinates
    required this.r,
    required this.g,
    required this.b,
    required this.a,
    this.strokeWidth = 3.0,
    this.text,
    this.fontSize = 18.0,
  });

  final int typeIndex;
  final List<List<double>> points;
  final int r, g, b, a;
  final double strokeWidth;
  final String? text;
  final double fontSize;
}

/// Request parameters sent to the background isolate.
class ImageProcessingTask {
  const ImageProcessingTask({
    required this.inputPath,
    required this.outputPath,
    required this.params,
    this.annotations = const [],
    this.targetWidth,
    this.targetHeight,
    this.quality = 90,
  });

  final String inputPath;
  final String outputPath;
  final EditorParameters params;
  final List<AnnotationExportData> annotations;
  final int? targetWidth;
  final int? targetHeight;
  final int quality;
}

/// Headless image processing engine using the `image` package in a background isolate.
class ImageProcessorService {
  /// Executes the full non-destructive edit pipeline on the original file
  /// and writes the output file without blocking the UI thread.
  static Future<String> processAndSave(ImageProcessingTask task) async {
    return compute(_executeTask, task);
  }

  static String _executeTask(ImageProcessingTask task) {
    final bytes = File(task.inputPath).readAsBytesSync();
    var image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image at ${task.inputPath}');
    }

    // 1. Orient according to EXIF if available
    image = img.bakeOrientation(image);

    // 2. Crop
    if (task.params.cropRect != null) {
      final rect = task.params.cropRect!;
      final x = (rect.left * image.width).round().clamp(0, image.width - 1);
      final y = (rect.top * image.height).round().clamp(0, image.height - 1);
      final w = (rect.width * image.width).round().clamp(1, image.width - x);
      final h = (rect.height * image.height).round().clamp(1, image.height - y);
      image = img.copyCrop(image, x: x, y: y, width: w, height: h);
    }

    // 3. Rotation (Quarter turns: 0, 90, 180, 270)
    final turns = task.params.rotationQuarterTurns % 4;
    if (turns != 0) {
      image = img.copyRotate(image, angle: turns * 90);
    }

    // 4. Flips
    if (task.params.flipHorizontal) {
      image = img.copyFlip(image, direction: img.FlipDirection.horizontal);
    }
    if (task.params.flipVertical) {
      image = img.copyFlip(image, direction: img.FlipDirection.vertical);
    }

    // 5. Resize (optional)
    if (task.targetWidth != null || task.targetHeight != null) {
      image = img.copyResize(
        image,
        width: task.targetWidth,
        height: task.targetHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    // 6. Color Adjustments: Brightness, Contrast & Saturation
    final totalBrightness = (task.params.brightness + task.params.exposure).clamp(-1.0, 1.0);
    if (totalBrightness != 0.0) {
      image = img.adjustColor(image, brightness: 1.0 + totalBrightness);
    }
    if (task.params.contrast != 0.0) {
      image = img.adjustColor(image, contrast: 1.0 + task.params.contrast);
    }
    if (task.params.saturation != 0.0) {
      image = img.adjustColor(image, saturation: 1.0 + task.params.saturation);
    }

    // 7. Filter Presets
    switch (task.params.preset) {
      case FilterPreset.bw:
        image = img.grayscale(image);
        break;
      case FilterPreset.vintage:
        image = img.sepia(image, amount: 0.7);
        break;
      case FilterPreset.vivid:
        image = img.adjustColor(image, saturation: 1.3, contrast: 1.1);
        break;
      case FilterPreset.cyberpunk:
        image = img.adjustColor(image, saturation: 1.4, contrast: 1.25);
        break;
      case FilterPreset.cinematic:
        image = img.adjustColor(image, saturation: 1.1, contrast: 1.15);
        break;
      case FilterPreset.none:
        break;
    }

    // 8. Vignette Falloff
    if (task.params.vignette > 0) {
      final cx = image.width / 2.0;
      final cy = image.height / 2.0;
      final maxDist = math.sqrt(cx * cx + cy * cy);
      final vig = task.params.vignette;

      for (final pixel in image) {
        final dx = pixel.x - cx;
        final dy = pixel.y - cy;
        final dist = math.sqrt(dx * dx + dy * dy) / maxDist;
        if (dist > 0.4) {
          final factor = 1.0 - ((dist - 0.4) / 0.6 * vig * 0.85).clamp(0.0, 0.95);
          pixel.r = (pixel.r * factor).round();
          pixel.g = (pixel.g * factor).round();
          pixel.b = (pixel.b * factor).round();
        }
      }
    }

    // 9. Burn-in On-Image Annotations
    if (task.annotations.isNotEmpty) {
      final imgW = image.width;
      final imgH = image.height;

      for (final ann in task.annotations) {
        if (ann.points.isEmpty) continue;
        final color = img.ColorRgba8(ann.r, ann.g, ann.b, ann.a);
        final strokeThickness = ann.strokeWidth.round().clamp(1, 20);

        final pts = ann.points.map((p) => [
          (p[0] * imgW).round().clamp(0, imgW - 1),
          (p[1] * imgH).round().clamp(0, imgH - 1),
        ]).toList();

        switch (ann.typeIndex) {
          case 0: // Pen
            for (int i = 0; i < pts.length - 1; i++) {
              img.drawLine(
                image,
                x1: pts[i][0],
                y1: pts[i][1],
                x2: pts[i + 1][0],
                y2: pts[i + 1][1],
                color: color,
                thickness: strokeThickness,
                antialias: true,
              );
            }
            break;

          case 1: // Arrow
            if (pts.length >= 2) {
              final startX = pts[0][0];
              final startY = pts[0][1];
              final endX = pts[1][0];
              final endY = pts[1][1];

              img.drawLine(
                image,
                x1: startX,
                y1: startY,
                x2: endX,
                y2: endY,
                color: color,
                thickness: strokeThickness,
                antialias: true,
              );

              final angle = math.atan2(endY - startY, endX - startX);
              final arrowLen = 18.0 * (strokeThickness / 3.0).clamp(1.0, 4.0);
              const arrowAngle = math.pi / 6;

              final h1x = (endX - arrowLen * math.cos(angle - arrowAngle)).round();
              final h1y = (endY - arrowLen * math.sin(angle - arrowAngle)).round();
              final h2x = (endX - arrowLen * math.cos(angle + arrowAngle)).round();
              final h2y = (endY - arrowLen * math.sin(angle + arrowAngle)).round();

              img.drawLine(image, x1: endX, y1: endY, x2: h1x, y2: h1y, color: color, thickness: strokeThickness, antialias: true);
              img.drawLine(image, x1: endX, y1: endY, x2: h2x, y2: h2y, color: color, thickness: strokeThickness, antialias: true);
            }
            break;

          case 2: // Rectangle
            if (pts.length >= 2) {
              final x1 = math.min(pts[0][0], pts[1][0]);
              final y1 = math.min(pts[0][1], pts[1][1]);
              final x2 = math.max(pts[0][0], pts[1][0]);
              final y2 = math.max(pts[0][1], pts[1][1]);

              img.drawRect(
                image,
                x1: x1,
                y1: y1,
                x2: x2,
                y2: y2,
                color: color,
                thickness: strokeThickness,
              );
            }
            break;

          case 3: // Circle
            if (pts.length >= 2) {
              final cx = ((pts[0][0] + pts[1][0]) / 2).round();
              final cy = ((pts[0][1] + pts[1][1]) / 2).round();
              final rx = ((pts[1][0] - pts[0][0]).abs() / 2).round();
              final ry = ((pts[1][1] - pts[0][1]).abs() / 2).round();
              final radius = math.max(rx, ry);

              img.drawCircle(
                image,
                x: cx,
                y: cy,
                radius: radius,
                color: color,
              );
            }
            break;

          case 4: // Text
            if (ann.text != null && pts.isNotEmpty) {
              img.drawString(
                image,
                ann.text!,
                font: img.arial24,
                x: pts[0][0],
                y: pts[0][1],
                color: color,
              );
            }
            break;
        }
      }
    }

    // 10. Encode & Save according to output extension
    final ext = p.extension(task.outputPath).toLowerCase().replaceFirst('.', '');
    List<int> encodedBytes;
    switch (ext) {
      case 'png':
        encodedBytes = img.encodePng(image);
        break;
      case 'webp':
        encodedBytes = img.encodePng(image); // Fallback standard format
        break;
      case 'bmp':
        encodedBytes = img.encodeBmp(image);
        break;
      case 'gif':
        encodedBytes = img.encodeGif(image);
        break;
      case 'jpg':
      case 'jpeg':
      default:
        encodedBytes = img.encodeJpg(image, quality: task.quality);
        break;
    }

    File(task.outputPath).writeAsBytesSync(encodedBytes);
    return task.outputPath;
  }
}
