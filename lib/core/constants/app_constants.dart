/// Supported image format extensions that Apertix can open.
abstract final class SupportedFormats {
  /// All supported image formats (lowercase, no leading dot).
  static const all = {
    // Tier 1 — Native Flutter decoding
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'ico', 'tiff', 'tif',
    'tga', 'pbm', 'pgm', 'ppm',
    // Tier 2 — via `image` package
    'psd', 'exr', 'hdr', 'pcx', 'cur',
    // Tier 3 — platform codecs / FFI
    'avif', 'jxl', 'heic', 'heif', 'svg', 'svgz',
    // RAW formats
    'cr2', 'nef', 'arw', 'dng', 'orf', 'rw2', 'raf', 'srw', 'pef',
  };

  /// Animated formats that have frame-level controls.
  static const animated = {'gif', 'webp', 'apng', 'svg'};

  /// Formats that support lossless rotation (no re-encode).
  static const losslessRotatable = {'jpg', 'jpeg'};

  /// Check if a file path has a supported extension.
  static bool isSupported(String path) {
    if (path.isEmpty || !path.contains('.')) return false;
    final ext = path.split('.').last.toLowerCase();
    return all.contains(ext);
  }

  /// File picker filter: returns glob patterns for each format.
  static List<String> get pickerExtensions => all.toList();
}

/// Global app-wide constants.
abstract final class AppConstants {
  static const appName = 'Spectrum';
  static const appVersion = '0.1.0';
  static const recentFilesLimit = 50;
  static const cacheMaxImages = 20;
  static const preloadAhead = 3; // images to preload in each direction
  static const thumbnailSize = 160.0;
  static const minZoom = 0.1;
  static const maxZoom = 32.0;
  static const defaultSlideshowIntervalSec = 3;
}
