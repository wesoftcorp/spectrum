import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';

/// Helper service for Windows desktop shell integration, file associations, and default app settings.
class WindowsShellService {
  /// Opens Windows 10/11 Settings directly to the "Default Apps" page.
  static Future<bool> openDefaultAppsSettings() async {
    if (!Platform.isWindows) return false;
    final uri = Uri.parse('ms-settings:defaultapps');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }

  /// Generates a customized Windows Registry (.reg) file that registers Apertix
  /// as the handler for all 80+ supported image formats with shell context menu integration.
  static Future<String> generateRegistryFile({String? destinationDir}) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('Registry generation is only supported on Windows.');
    }

    final exePath = Platform.resolvedExecutable.replaceAll('\\', '\\\\');
    final dir = destinationDir ?? p.join(Platform.environment['USERPROFILE'] ?? 'C:', 'Desktop');
    await Directory(dir).create(recursive: true);
    final outPath = p.join(dir, 'Spectrum_File_Associations.reg');

    final buffer = StringBuffer();
    buffer.writeln('Windows Registry Editor Version 5.00');
    buffer.writeln();
    buffer.writeln('; Spectrum Image Viewer & Editor — Shell Associations');
    buffer.writeln();

    // 1. Register ProgID
    buffer.writeln(r'[HKEY_CURRENT_USER\Software\Classes\Spectrum.Picture]');
    buffer.writeln('@="Spectrum Image File"');
    buffer.writeln('"FriendlyTypeName"="Spectrum Image"');
    buffer.writeln();

    buffer.writeln(r'[HKEY_CURRENT_USER\Software\Classes\Spectrum.Picture\DefaultIcon]');
    buffer.writeln('@="$exePath,0"');
    buffer.writeln();

    buffer.writeln(r'[HKEY_CURRENT_USER\Software\Classes\Spectrum.Picture\shell\open]');
    buffer.writeln('@="Open with Spectrum"');
    buffer.writeln();

    buffer.writeln(r'[HKEY_CURRENT_USER\Software\Classes\Spectrum.Picture\shell\open\command]');
    buffer.writeln('@="\\"$exePath\\" \\"%1\\""');
    buffer.writeln();

    // 2. Associate supported formats
    for (final ext in SupportedFormats.all) {
      buffer.writeln('[HKEY_CURRENT_USER\\Software\\Classes\\.$ext]');
      buffer.writeln('@="Spectrum.Picture"');
      buffer.writeln();
      buffer.writeln('[HKEY_CURRENT_USER\\Software\\Classes\\.$ext\\OpenWithProgids]');
      buffer.writeln('"Spectrum.Picture"=""');
      buffer.writeln();
    }

    // 3. Add to Explorer context menu for all images
    buffer.writeln(r'[HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\image\shell\Spectrum]');
    buffer.writeln('@="Open in Spectrum"');
    buffer.writeln('"Icon"="$exePath,0"');
    buffer.writeln();

    buffer.writeln(r'[HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\image\shell\Spectrum\command]');
    buffer.writeln('@="\\"$exePath\\" \\"%1\\""');
    buffer.writeln();

    await File(outPath).writeAsString(buffer.toString());
    return outPath;
  }
}
