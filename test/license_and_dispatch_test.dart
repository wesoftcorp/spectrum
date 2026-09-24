import 'package:flutter_test/flutter_test.dart';
import 'package:apertix/core/licensing/models/license_info.dart';
import 'package:apertix/core/licensing/services/license_service.dart';
import 'package:apertix/features/social/models/social_platform.dart';
import 'package:apertix/features/social/services/publish_engine.dart';

void main() {
  group('Cryptographic Licensing Engine', () {
    final licenseService = LicenseService();

    test('Validates developer DEMO and BETA evaluation keys', () {
      expect(licenseService.verifyKey('APTX-PRO-DEMO-2026-F9A1'), true);
      expect(licenseService.verifyKey('aptx-pro-demo-2026-f9a1'), true); // Case-insensitive
      expect(licenseService.verifyKey('APTX-PRO-BETA-9999-ABCD'), true);
    });

    test('Generates and verifies cryptographic HMAC-SHA256 license keys', () {
      final key = LicenseService.generateKey(block1: 'PRO1', block2: '2026', email: 'user@example.com');
      expect(key.startsWith('APTX-PRO-PRO1-2026-'), true);
      expect(licenseService.verifyKey(key, email: 'user@example.com'), true);

      // Fails with mismatched email
      expect(licenseService.verifyKey(key, email: 'hacker@bad.com'), false);
    });

    test('Rejects invalid and malformed keys', () {
      expect(licenseService.verifyKey(''), false);
      expect(licenseService.verifyKey('INVALID-KEY-1234'), false);
      expect(licenseService.verifyKey('APTX-FREE-1111-2222-3333'), false);
      expect(licenseService.verifyKey('APTX-PRO-ABCD-EFGH-ZZZZ'), false);
    });

    test('Generates non-empty device hardware fingerprint', () {
      final fp = licenseService.generateDeviceFingerprint();
      expect(fp.isNotEmpty, true);
      expect(fp.length, 16);
    });

    test('LicenseInfo model serialization', () {
      const info = LicenseInfo(
        tier: LicenseTier.pro,
        key: 'APTX-PRO-DEMO-2026-F9A1',
        email: 'test@apertix.io',
      );
      final raw = info.serialize();
      final restored = LicenseInfo.deserialize(raw);

      expect(restored.isPro, true);
      expect(restored.key, 'APTX-PRO-DEMO-2026-F9A1');
      expect(restored.email, 'test@apertix.io');
    });
  });

  group('PublishEngine & Multi-Platform Models', () {
    test('SocialPlatform defines valid brand colors and presets', () {
      for (final p in SocialPlatform.values) {
        expect(p.brandColor.toARGB32(), isNotNull);
        expect(p.presets.isNotEmpty, true);
      }
    });

    test('PlatformDispatchState copyWith updates status accurately', () {
      const state = PlatformDispatchState(
        platform: SocialPlatform.instagram,
        status: DispatchStatus.idle,
      );

      final running = state.copyWith(status: DispatchStatus.inProgress, message: 'Uploading...');
      expect(running.status, DispatchStatus.inProgress);
      expect(running.message, 'Uploading...');

      final done = running.copyWith(status: DispatchStatus.success);
      expect(done.status, DispatchStatus.success);
    });
  });
}
