import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import '../models/batch_options.dart';

/// Single item task dispatched to background isolate.
class _BatchItemTask {
  const _BatchItemTask({
    required this.inputPath,
    required this.outputPath,
    required this.resizeOptions,
    required this.convertOptions,
  });

  final String inputPath;
  final String outputPath;
  final BatchResizeOptions resizeOptions;
  final BatchConvertOptions convertOptions;
}

/// Result returned from background isolate.
class _BatchItemResult {
  const _BatchItemResult({
    required this.inputPath,
    required this.outputPath,
    required this.isSuccess,
    required this.originalBytes,
    required this.newBytes,
    this.error,
  });

  final String inputPath;
  final String outputPath;
  final bool isSuccess;
  final int originalBytes;
  final int newBytes;
  final String? error;
}

/// Service executing batch processing across images in background isolates.
class BatchProcessorService {
  bool _isCancelled = false;

  void cancel() {
    _isCancelled = true;
  }

  /// Process all files in [config] and emit progress via [onProgress].
  Future<BatchSummary> process({
    required BatchConfig config,
    required void Function(BatchProgress progress) onProgress,
  }) async {
    _isCancelled = false;
    final stopwatch = Stopwatch()..start();
    final results = <BatchResultItem>[];

    // Determine output directory
    final firstPath = config.inputPaths.first;
    final defaultDir = p.join(p.dirname(firstPath), '_processed');
    final outDir = config.outputDirectory ?? defaultDir;

    final outDirectory = Directory(outDir);
    if (!outDirectory.existsSync()) {
      outDirectory.createSync(recursive: true);
    }

    final total = config.inputPaths.length;

    for (int i = 0; i < total; i++) {
      if (_isCancelled) {
        break;
      }

      final inputPath = config.inputPaths[i];
      final fileName = p.basename(inputPath);
      final fileStat = File(inputPath).statSync();

      onProgress(BatchProgress(
        current: i,
        total: total,
        currentFileName: fileName,
        isCompleted: false,
      ));

      // Calculate output filename & path
      final newName = config.renameOptions.computeNewName(
        originalPath: inputPath,
        index: i,
        date: fileStat.modified,
        newExtension: config.convertOptions.extension,
      );

      final outputPath = config.overwriteOriginals && config.convertOptions.format == TargetFormat.keepOriginal
          ? inputPath
          : p.join(outDir, newName);

      final task = _BatchItemTask(
        inputPath: inputPath,
        outputPath: outputPath,
        resizeOptions: config.resizeOptions,
        convertOptions: config.convertOptions,
      );

      try {
        final result = await compute(_processSingleFile, task);
        results.add(BatchResultItem(
          inputPath: result.inputPath,
          outputPath: result.outputPath,
          isSuccess: result.isSuccess,
          originalSizeBytes: result.originalBytes,
          newSizeBytes: result.newBytes,
          errorMessage: result.error,
        ));
      } catch (e) {
        results.add(BatchResultItem(
          inputPath: inputPath,
          outputPath: outputPath,
          isSuccess: false,
          originalSizeBytes: fileStat.size,
          newSizeBytes: 0,
          errorMessage: e.toString(),
        ));
      }
    }

    stopwatch.stop();

    onProgress(BatchProgress(
      current: total,
      total: total,
      currentFileName: 'Done',
      isCompleted: true,
    ));

    return BatchSummary(
      total: total,
      succeeded: results.where((r) => r.isSuccess).length,
      failed: results.where((r) => !r.isSuccess).length,
      duration: stopwatch.elapsed,
      results: results,
      outputDirectory: outDir,
    );
  }

  /// Headless isolate task executing decode, resize, format convert, and encode.
  static _BatchItemResult _processSingleFile(_BatchItemTask task) {
    try {
      final inputFile = File(task.inputPath);
      final originalBytes = inputFile.readAsBytesSync();
      var image = img.decodeImage(originalBytes);
      if (image == null) {
        return _BatchItemResult(
          inputPath: task.inputPath,
          outputPath: task.outputPath,
          isSuccess: false,
          originalBytes: originalBytes.length,
          newBytes: 0,
          error: 'Unsupported or corrupted image',
        );
      }

      image = img.bakeOrientation(image);

      // 1. Resize if configured
      switch (task.resizeOptions.mode) {
        case ResizeMode.none:
          break;
        case ResizeMode.percentage:
          final scale = task.resizeOptions.percentage / 100.0;
          final w = (image.width * scale).round().clamp(1, 16384);
          final h = (image.height * scale).round().clamp(1, 16384);
          image = img.copyResize(image, width: w, height: h, interpolation: img.Interpolation.linear);
          break;
        case ResizeMode.exactDimensions:
          if (task.resizeOptions.maintainAspectRatio) {
            final targetW = task.resizeOptions.targetWidth;
            final targetH = task.resizeOptions.targetHeight;
            final scaleW = targetW / image.width;
            final scaleH = targetH / image.height;
            final scale = scaleW < scaleH ? scaleW : scaleH;
            final w = (image.width * scale).round().clamp(1, 16384);
            final h = (image.height * scale).round().clamp(1, 16384);
            image = img.copyResize(image, width: w, height: h, interpolation: img.Interpolation.linear);
          } else {
            image = img.copyResize(
              image,
              width: task.resizeOptions.targetWidth,
              height: task.resizeOptions.targetHeight,
              interpolation: img.Interpolation.linear,
            );
          }
          break;
        case ResizeMode.fitLongestEdge:
          final longest = task.resizeOptions.longestEdge;
          if (image.width >= image.height && image.width > longest) {
            final h = (image.height * (longest / image.width)).round();
            image = img.copyResize(image, width: longest, height: h, interpolation: img.Interpolation.linear);
          } else if (image.height > image.width && image.height > longest) {
            final w = (image.width * (longest / image.height)).round();
            image = img.copyResize(image, width: w, height: longest, interpolation: img.Interpolation.linear);
          }
          break;
      }

      // 2. Format Encode
      final ext = p.extension(task.outputPath).toLowerCase().replaceFirst('.', '');
      List<int> encoded;

      switch (ext) {
        case 'png':
          encoded = img.encodePng(image);
          break;
        case 'bmp':
          encoded = img.encodeBmp(image);
          break;
        case 'gif':
          encoded = img.encodeGif(image);
          break;
        case 'webp':
        case 'jpg':
        case 'jpeg':
        default:
          encoded = img.encodeJpg(image, quality: task.convertOptions.quality);
          break;
      }

      final outFile = File(task.outputPath);
      outFile.writeAsBytesSync(encoded);

      return _BatchItemResult(
        inputPath: task.inputPath,
        outputPath: task.outputPath,
        isSuccess: true,
        originalBytes: originalBytes.length,
        newBytes: encoded.length,
      );
    } catch (e) {
      return _BatchItemResult(
        inputPath: task.inputPath,
        outputPath: task.outputPath,
        isSuccess: false,
        originalBytes: 0,
        newBytes: 0,
        error: e.toString(),
      );
    }
  }
}
