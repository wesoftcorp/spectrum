import 'dart:io';
import 'package:flutter/foundation.dart' show compute;
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
  static const int _maxDepth = 10;
  static const int _maxDiscoveredImages = 30000;

  static const _ignoredDirNames = {
    'node_modules',
    r'$recycle.bin',
    r'$windows.~bt',
    r'$windows.~ws',
    'system volume information',
    'appdata',
    'application data',
    'windows',
    'winnt',
    'program files',
    'program files (x86)',
    'programdata',
    'recovery',
    'msocache',
    'config.msi',
    '__pycache__',
    '.git', '.svn', '.hg',
    'bootmgr', 'boot', 'efi',
    '.vs', 'obj', 'bin',
  };

  /// Returns all supported image files under [folderPath] (recursive).
  /// Uses a background isolate via [compute] so the UI stays responsive.
  Future<List<ImageFile>> listImages(String folderPath) async {
    try {
      // compute() uses a Flutter-managed isolate pool — safer than Isolate.run
      // and handles serialization of plain Dart objects correctly.
      return await compute(_scanFolder, folderPath);
    } catch (_) {
      // If the isolate fails for any reason, fall back to synchronous scan
      try {
        return _scanFolder(folderPath);
      } catch (_) {
        return [];
      }
    }
  }

  /// Top-level static function required by [compute].
  /// BFS scan with depth-limit, cycle detection, and full exception guarding.
  static List<ImageFile> _scanFolder(String folderPath) {
    final rootDir = Directory(folderPath);
    try {
      if (!rootDir.existsSync()) return [];
    } catch (_) {
      return [];
    }

    final files = <ImageFile>[];
    final queue = <(Directory, int)>[(rootDir, 0)];
    final visited = <String>{};
    try {
      visited.add(p.normalize(folderPath).toLowerCase());
    } catch (_) {
      return [];
    }

    while (queue.isNotEmpty && files.length < _maxDiscoveredImages) {
      final (currentDir, depth) = queue.removeLast();

      List<FileSystemEntity> entities;
      try {
        entities = currentDir.listSync(followLinks: false);
      } catch (_) {
        continue; // Permission denied — skip
      }

      for (final entity in entities) {
        if (files.length >= _maxDiscoveredImages) break;

        String baseName;
        String lowerName;
        try {
          baseName = p.basename(entity.path);
          lowerName = baseName.toLowerCase();
        } catch (_) {
          continue;
        }

        // Skip hidden items and system directories
        if (lowerName.startsWith('.') || _ignoredDirNames.contains(lowerName)) {
          continue;
        }

        // Skip NTFS junctions and symlinks
        try {
          if (FileSystemEntity.isLinkSync(entity.path)) continue;
        } catch (_) {
          continue;
        }

        if (entity is Directory) {
          if (depth < _maxDepth) {
            try {
              final canon = p.normalize(entity.path).toLowerCase();
              if (visited.add(canon)) {
                queue.add((entity, depth + 1));
              }
            } catch (_) {}
          }
        } else if (entity is File) {
          try {
            if (!SupportedFormats.isSupported(entity.path)) continue;
            final stat = entity.statSync();
            if (stat.size <= 0) continue;
            files.add(ImageFile(
              path: entity.path,
              name: baseName,
              extension: p.extension(entity.path).replaceFirst('.', '').toLowerCase(),
              sizeBytes: stat.size,
              modifiedAt: stat.modified,
            ));
          } catch (_) {}
        }
      }
    }

    // Sort newest first
    files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return files;
  }

  String folderOf(String filePath) => p.dirname(filePath);

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
