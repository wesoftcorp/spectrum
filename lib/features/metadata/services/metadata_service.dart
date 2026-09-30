import 'dart:io';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import '../models/image_metadata.dart';

class MetadataService {
  /// Extracts all EXIF, GPS, camera settings, and file attributes.
  static Future<ImageMetadata> extractMetadata(String filePath) async {
    return compute(_readMetadataIsolate, filePath);
  }

  /// Removes EXIF and GPS tags from an image, saving a sanitized version.
  static Future<String> stripExif(String inputPath, {String? outputPath}) async {
    return compute(_stripExifIsolate, {
      'input': inputPath,
      'output': outputPath ?? inputPath,
    });
  }

  static Future<ImageMetadata> _readMetadataIsolate(String path) async {
    final file = File(path);
    final stat = file.statSync();
    final bytes = file.readAsBytesSync();

    Map<String, IfdTag> data = {};
    try {
      data = await readExifFromBytes(bytes);
    } catch (_) {}

    final rawTags = <String, String>{};
    for (final entry in data.entries) {
      rawTags[entry.key] = entry.value.printable;
    }

    // Try fast EXIF dimensions first before falling back to full image decoding
    String? dimStr;
    final exifW = data['EXIF ExifImageWidth']?.printable ?? data['Image ImageWidth']?.printable;
    final exifH = data['EXIF ExifImageLength']?.printable ?? data['Image ImageLength']?.printable;
    if (exifW != null && exifH != null && int.tryParse(exifW) != null && int.tryParse(exifH) != null) {
      dimStr = '$exifW × $exifH px';
    } else {
      try {
        final header = img.decodeImage(bytes);
        if (header != null) {
          dimStr = '${header.width} × ${header.height} px';
        }
      } catch (_) {}
    }

    // Extract GPS
    double? lat;
    double? lon;
    double? alt;
    try {
      final latTag = data['GPS GPSLatitude'];
      final latRef = data['GPS GPSLatitudeRef']?.printable;
      final lonTag = data['GPS GPSLongitude'];
      final lonRef = data['GPS GPSLongitudeRef']?.printable;

      if (latTag != null && latRef != null) {
        lat = _parseGpsCoord(latTag, latRef);
      }
      if (lonTag != null && lonRef != null) {
        lon = _parseGpsCoord(lonTag, lonRef);
      }
      final altTag = data['GPS GPSAltitude'];
      if (altTag != null) {
        final val = altTag.values.toList();
        if (val.isNotEmpty) {
          alt = (val[0] as num).toDouble();
        }
      }
    } catch (_) {}

    return ImageMetadata(
      filePath: path,
      fileSizeBytes: stat.size,
      lastModified: stat.modified,
      dimensions: dimStr,
      cameraMake: data['Image Make']?.printable,
      cameraModel: data['Image Model']?.printable,
      lensModel: data['EXIF LensModel']?.printable,
      focalLength: data['EXIF FocalLength']?.printable,
      aperture: data['EXIF FNumber']?.printable,
      shutterSpeed: data['EXIF ExposureTime']?.printable,
      iso: data['EXIF ISOSpeedRatings']?.printable,
      dateTaken: data['Image DateTime']?.printable ?? data['EXIF DateTimeOriginal']?.printable,
      gpsLatitude: lat,
      gpsLongitude: lon,
      gpsAltitude: alt,
      software: data['Image Software']?.printable,
      colorSpace: data['EXIF ColorSpace']?.printable,
      rawTags: rawTags,
    );
  }

  static double? _parseGpsCoord(IfdTag tag, String ref) {
    try {
      final values = tag.values.toList();
      if (values.length < 3) return null;

      final deg = (values[0] as num).toDouble();
      final min = (values[1] as num).toDouble();
      final sec = (values[2] as num).toDouble();

      var coord = deg + (min / 60.0) + (sec / 3600.0);
      if (ref == 'S' || ref == 'W') {
        coord = -coord;
      }
      return coord;
    } catch (_) {
      return null;
    }
  }

  static String _stripExifIsolate(Map<String, String> paths) {
    final input = paths['input']!;
    final output = paths['output']!;

    final bytes = File(input).readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Could not decode image to sanitize EXIF');
    }

    // Re-encoding without EXIF payload strips GPS and camera metadata completely
    final ext = p.extension(output).toLowerCase().replaceFirst('.', '');
    final List<int> sanitized;
    if (ext == 'png') {
      sanitized = img.encodePng(decoded);
    } else {
      sanitized = img.encodeJpg(decoded, quality: 95);
    }

    final outFile = File(output);
    if (!outFile.parent.existsSync()) {
      outFile.parent.createSync(recursive: true);
    }
    outFile.writeAsBytesSync(sanitized);
    return output;
  }
}
