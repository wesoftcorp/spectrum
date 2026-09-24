import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';

/// Represents a single image file on disk.
class ImageFile {
  const ImageFile({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String path;
  final String name;
  final String extension;
  final int sizeBytes;
  final DateTime modifiedAt;

  /// Human-readable file size.
  String get sizeLabel {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  factory ImageFile.fromFile(File file) {
    final stat = file.statSync();
    return ImageFile(
      path: file.path,
      name: p.basename(file.path),
      extension: p.extension(file.path).replaceFirst('.', '').toLowerCase(),
      sizeBytes: stat.size,
      modifiedAt: stat.modified,
    );
  }
}

/// Service for discovering and navigating image files on the file system.
class ImageFileService {
  /// Returns all supported image files in [folderPath], sorted by name.
  /// Scans directory and file stats in a background isolate to eliminate UI stuttering.
  Future<List<ImageFile>> listImages(String folderPath) async {
    return Isolate.run(() => _scanFolderIsolate(folderPath));
  }

  static List<ImageFile> _scanFolderIsolate(String folderPath) {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) return [];

    final files = <ImageFile>[];
    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is File && SupportedFormats.isSupported(entity.path)) {
          try {
            final stat = entity.statSync();
            files.add(ImageFile(
              path: entity.path,
              name: p.basename(entity.path),
              extension: p.extension(entity.path).replaceFirst('.', '').toLowerCase(),
              sizeBytes: stat.size,
              modifiedAt: stat.modified,
            ));
          } catch (_) {
            // Ignore individual file lock/permission errors
          }
        }
      }
      files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (_) {
      // In case of directory access errors
    }
    return files;
  }

  /// Returns the folder of a given file path.
  String folderOf(String filePath) => p.dirname(filePath);

  /// Returns next/previous image paths in a folder given the current path.
  Future<({String? prev, String? next})> siblings(String filePath) async {
    final folder = folderOf(filePath);
    final images = await listImages(folder);
    final idx = images.indexWhere((f) => f.path == filePath);
    if (idx < 0) return (prev: null, next: null);
    return (
      prev: idx > 0 ? images[idx - 1].path : null,
      next: idx < images.length - 1 ? images[idx + 1].path : null,
    );
  }
}
