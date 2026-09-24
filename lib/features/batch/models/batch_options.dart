import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

enum ResizeMode {
  none,
  percentage,
  exactDimensions,
  fitLongestEdge,
}

enum TargetFormat {
  keepOriginal,
  jpeg,
  png,
  webp,
}

enum RenameMode {
  keepOriginal,
  template,
  prefixSuffix,
  findReplace,
}

class BatchResizeOptions {
  const BatchResizeOptions({
    this.mode = ResizeMode.none,
    this.percentage = 50,
    this.targetWidth = 1920,
    this.targetHeight = 1080,
    this.longestEdge = 2048,
    this.maintainAspectRatio = true,
  });

  final ResizeMode mode;
  final int percentage;
  final int targetWidth;
  final int targetHeight;
  final int longestEdge;
  final bool maintainAspectRatio;

  BatchResizeOptions copyWith({
    ResizeMode? mode,
    int? percentage,
    int? targetWidth,
    int? targetHeight,
    int? longestEdge,
    bool? maintainAspectRatio,
  }) {
    return BatchResizeOptions(
      mode: mode ?? this.mode,
      percentage: percentage ?? this.percentage,
      targetWidth: targetWidth ?? this.targetWidth,
      targetHeight: targetHeight ?? this.targetHeight,
      longestEdge: longestEdge ?? this.longestEdge,
      maintainAspectRatio: maintainAspectRatio ?? this.maintainAspectRatio,
    );
  }
}

class BatchConvertOptions {
  const BatchConvertOptions({
    this.format = TargetFormat.keepOriginal,
    this.quality = 85,
  });

  final TargetFormat format;
  final int quality; // 1 - 100

  String? get extension {
    switch (format) {
      case TargetFormat.keepOriginal:
        return null;
      case TargetFormat.jpeg:
        return 'jpg';
      case TargetFormat.png:
        return 'png';
      case TargetFormat.webp:
        return 'webp';
    }
  }

  BatchConvertOptions copyWith({
    TargetFormat? format,
    int? quality,
  }) {
    return BatchConvertOptions(
      format: format ?? this.format,
      quality: quality ?? this.quality,
    );
  }
}

class BatchRenameOptions {
  const BatchRenameOptions({
    this.mode = RenameMode.keepOriginal,
    this.template = '{name}_{index}',
    this.prefix = '',
    this.suffix = '',
    this.findText = '',
    this.replaceText = '',
    this.startCounter = 1,
    this.counterPadding = 3,
  });

  final RenameMode mode;
  final String template;
  final String prefix;
  final String suffix;
  final String findText;
  final String replaceText;
  final int startCounter;
  final int counterPadding;

  String computeNewName({
    required String originalPath,
    required int index,
    required DateTime date,
    String? newExtension,
  }) {
    final originalBase = p.basenameWithoutExtension(originalPath);
    final originalExt = p.extension(originalPath).replaceFirst('.', '');
    final finalExt = newExtension ?? originalExt;

    String baseName;
    switch (mode) {
      case RenameMode.keepOriginal:
        baseName = originalBase;
      case RenameMode.template:
        final counterStr = (startCounter + index).toString().padLeft(counterPadding, '0');
        final dateStr = DateFormat('yyyyMMdd').format(date);
        baseName = template
            .replaceAll('{name}', originalBase)
            .replaceAll('{index}', counterStr)
            .replaceAll('{date}', dateStr);
      case RenameMode.prefixSuffix:
        baseName = '$prefix$originalBase$suffix';
      case RenameMode.findReplace:
        baseName = findText.isNotEmpty
            ? originalBase.replaceAll(findText, replaceText)
            : originalBase;
    }

    return '$baseName.$finalExt';
  }

  BatchRenameOptions copyWith({
    RenameMode? mode,
    String? template,
    String? prefix,
    String? suffix,
    String? findText,
    String? replaceText,
    int? startCounter,
    int? counterPadding,
  }) {
    return BatchRenameOptions(
      mode: mode ?? this.mode,
      template: template ?? this.template,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      findText: findText ?? this.findText,
      replaceText: replaceText ?? this.replaceText,
      startCounter: startCounter ?? this.startCounter,
      counterPadding: counterPadding ?? this.counterPadding,
    );
  }
}

class BatchConfig {
  const BatchConfig({
    required this.inputPaths,
    this.outputDirectory,
    this.resizeOptions = const BatchResizeOptions(),
    this.convertOptions = const BatchConvertOptions(),
    this.renameOptions = const BatchRenameOptions(),
    this.overwriteOriginals = false,
  });

  final List<String> inputPaths;
  final String? outputDirectory; // null = alongside in '_processed' subfolder
  final BatchResizeOptions resizeOptions;
  final BatchConvertOptions convertOptions;
  final BatchRenameOptions renameOptions;
  final bool overwriteOriginals;
}

class BatchProgress {
  const BatchProgress({
    required this.current,
    required this.total,
    required this.currentFileName,
    required this.isCompleted,
    this.errorMessage,
  });

  final int current;
  final int total;
  final String currentFileName;
  final bool isCompleted;
  final String? errorMessage;

  double get percentage => total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
}

class BatchResultItem {
  const BatchResultItem({
    required this.inputPath,
    required this.outputPath,
    required this.isSuccess,
    required this.originalSizeBytes,
    required this.newSizeBytes,
    this.errorMessage,
  });

  final String inputPath;
  final String outputPath;
  final bool isSuccess;
  final int originalSizeBytes;
  final int newSizeBytes;
  final String? errorMessage;
}

class BatchSummary {
  const BatchSummary({
    required this.total,
    required this.succeeded,
    required this.failed,
    required this.duration,
    required this.results,
    required this.outputDirectory,
  });

  final int total;
  final int succeeded;
  final int failed;
  final Duration duration;
  final List<BatchResultItem> results;
  final String outputDirectory;

  int get totalOriginalBytes =>
      results.fold(0, (acc, r) => acc + r.originalSizeBytes);

  int get totalNewBytes =>
      results.fold(0, (acc, r) => acc + r.newSizeBytes);

  int get spaceSavedBytes => totalOriginalBytes - totalNewBytes;
}
