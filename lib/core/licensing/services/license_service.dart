import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/license_info.dart';

/// Cryptographic offline license verification and tier activation service.
class LicenseService {
  static const String _prefKey = 'apertix_license_data';
  static const String _salt = 'APERTIX_CORE_SECRET_SALT_2026_HMAC';

  /// Generates a hardware/platform fingerprint for machine binding.
  String generateDeviceFingerprint() {
    try {
      final host = Platform.localHostname;
      final os = Platform.operatingSystem;
      final version = Platform.operatingSystemVersion;
      final raw = '$host::$os::$version';
      return sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
    } catch (_) {
      return 'generic_device';
    }
  }

  /// Cryptographically generates a valid license key for a given seed and optional email.
  static String generateKey({required String block1, required String block2, String? email}) {
    final b1 = block1.trim().toUpperCase().padRight(4, 'X').substring(0, 4);
    final b2 = block2.trim().toUpperCase().padRight(4, 'Y').substring(0, 4);
    final payload = '$b1$b2${email?.trim().toLowerCase() ?? 'ANY'}';
    final hmac = Hmac(sha256, utf8.encode(_salt));
    final checksum = hmac.convert(utf8.encode(payload)).toString().toUpperCase().substring(0, 4);
    return 'APTX-PRO-$b1-$b2-$checksum';
  }

  /// Verifies whether [key] is a valid offline license key.
  bool verifyKey(String key, {String? email}) {
    final cleanKey = key.trim().toUpperCase();
    final regex = RegExp(r'^APTX-PRO-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
    if (!regex.hasMatch(cleanKey)) return false;

    final parts = cleanKey.split('-');
    if (parts.length != 5) return false;

    final b1 = parts[2];
    final b2 = parts[3];
    final checksum = parts[4];

    // Master / developer keys
    if (b1 == 'DEMO' || b1 == 'BETA' || b1 == 'TEST') return true;

    // Cryptographic HMAC-SHA256 checksum verification
    final expectedChecksumWithEmail = _calculateChecksum(b1, b2, email?.trim().toLowerCase());
    final expectedChecksumWithoutEmail = _calculateChecksum(b1, b2, 'ANY');

    return checksum == expectedChecksumWithEmail || checksum == expectedChecksumWithoutEmail;
  }

  static String _calculateChecksum(String b1, String b2, String? emailQualifier) {
    final payload = '$b1$b2${emailQualifier ?? 'ANY'}';
    final hmac = Hmac(sha256, utf8.encode(_salt));
    return hmac.convert(utf8.encode(payload)).toString().toUpperCase().substring(0, 4);
  }

  /// Loads current active license from disk.
  Future<LicenseInfo> getActiveLicense() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) {
        return const LicenseInfo(tier: LicenseTier.free);
      }
      final info = LicenseInfo.deserialize(raw);
      if (info.isPro && info.key != null) {
        // Double-check stored key integrity
        if (!verifyKey(info.key!, email: info.email)) {
          return const LicenseInfo(tier: LicenseTier.free);
        }
      }
      return info;
    } catch (_) {
      return const LicenseInfo(tier: LicenseTier.free);
    }
  }

  /// Activates Pro license with verified [key].
  Future<bool> activateLicense({required String key, String? email}) async {
    if (!verifyKey(key, email: email)) {
      return false;
    }

    final info = LicenseInfo(
      tier: LicenseTier.pro,
      key: key.trim().toUpperCase(),
      email: email?.trim(),
      activatedAt: DateTime.now(),
      deviceFingerprint: generateDeviceFingerprint(),
      isPerpetual: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, info.serialize());
    return true;
  }

  /// Deactivates and resets to free open-source core tier.
  Future<void> deactivateLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
