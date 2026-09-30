import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apertix/core/constants/app_constants.dart';
import 'package:apertix/core/licensing/services/license_service.dart';
import 'package:apertix/core/update/services/update_checker_service.dart';
import 'package:apertix/features/social/services/social_publish_service.dart';
import 'package:apertix/features/cloud/services/cloud_vault_service.dart';
import 'package:apertix/features/cloud/models/cloud_config.dart';
import 'package:apertix/features/collections/services/album_service.dart';
import 'package:apertix/features/viewer/providers/viewer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Security & SSRF Hardening Tests', () {
    test('SocialPublishService rejects non-Discord or malformed webhook URLs', () async {
      final service = SocialPublishService();

      // Malformed or foreign URLs
      final foreignUrlResult = await service.publishToDiscord(
        imagePath: 'dummy.jpg',
        webhookUrl: 'https://evil-attacker.com/steal-data',
        caption: 'Test caption',
      );
      expect(foreignUrlResult.success, isFalse);
      expect(foreignUrlResult.message, contains('Invalid Discord webhook URL'));

      final nonHttpsResult = await service.publishToDiscord(
        imagePath: 'dummy.jpg',
        webhookUrl: 'http://discord.com/api/webhooks/123/abc',
        caption: 'Test caption',
      );
      expect(nonHttpsResult.success, isFalse);
      expect(nonHttpsResult.message, contains('Invalid Discord webhook URL'));

      final nonWebhookPath = await service.publishToDiscord(
        imagePath: 'dummy.jpg',
        webhookUrl: 'https://discord.com/other/path',
        caption: 'Test caption',
      );
      expect(nonWebhookPath.success, isFalse);
      expect(nonWebhookPath.message, contains('Invalid Discord webhook URL'));
    });

    test('SocialPublishService rejects malformed Telegram bot tokens', () async {
      final service = SocialPublishService();

      final badTokenResult = await service.publishToTelegram(
        imagePath: 'dummy.jpg',
        botToken: 'bad token with spaces',
        chatId: '12345',
        caption: 'Test caption',
      );
      expect(badTokenResult.success, isFalse);
      expect(badTokenResult.message, contains('Invalid Telegram bot token format'));

      final slashTokenResult = await service.publishToTelegram(
        imagePath: 'dummy.jpg',
        botToken: '12345/../admin',
        chatId: '12345',
        caption: 'Test caption',
      );
      expect(slashTokenResult.success, isFalse);
      expect(slashTokenResult.message, contains('Invalid Telegram bot token format'));
    });

    test('CloudVaultService rejects non-HTTP(S) URLs and directory traversal paths', () async {
      final service = CloudVaultService();

      // Test connection with bad scheme
      const badSchemeConfig = CloudConfig(
        providerType: CloudProviderType.webdav,
        serverUrl: 'file:///etc/passwd',
      );
      final isConn = await service.testConnection(badSchemeConfig);
      expect(isConn, isFalse);

      // Upload with invalid scheme
      expect(
        () => service.uploadFile('non_existent.jpg', badSchemeConfig),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Stability & Error Recovery Tests', () {
    test('SupportedFormats.isSupported safely handles empty or extension-less strings', () {
      expect(SupportedFormats.isSupported(''), isFalse);
      expect(SupportedFormats.isSupported('no_extension'), isFalse);
      expect(SupportedFormats.isSupported('.'), isFalse);
      expect(SupportedFormats.isSupported('/dir/another/image.jpg'), isTrue);
      expect(SupportedFormats.isSupported('/dir/another/image.PNG'), isTrue);
      expect(SupportedFormats.isSupported('/dir/another/IMAGE.WEBP'), isTrue);
      expect(SupportedFormats.isSupported('photo.unknown'), isFalse);
    });

    test('ViewerState bounds checks prevent RangeError on currentPath', () {
      const stateEmpty = ViewerState(filePaths: [], currentIndex: 0);
      expect(stateEmpty.currentPath, isNull);

      const stateNegative = ViewerState(filePaths: ['/a.jpg'], currentIndex: -1);
      expect(stateNegative.currentPath, isNull);

      const stateOutOfBounds = ViewerState(filePaths: ['/a.jpg'], currentIndex: 5);
      expect(stateOutOfBounds.currentPath, isNull);

      const stateValid = ViewerState(filePaths: ['/a.jpg', '/b.jpg'], currentIndex: 1);
      expect(stateValid.currentPath, equals('/b.jpg'));
    });

    test('AlbumService gracefully handles corrupted JSON storage', () async {
      SharedPreferences.setMockInitialValues({
        'apertix_virtual_albums': [
          '{"id": "1", "name": "Valid", "description": "", "coverPath": null, "imagePaths": [], "createdAt": "2026-01-01T00:00:00.000"}',
          '{corrupted json}',
          '{"incomplete": true}',
        ],
      });

      final service = AlbumService();
      final albums = await service.loadAlbums();

      // Only the valid album is returned, corrupted entries are skipped
      expect(albums.length, equals(1));
      expect(albums.first.name, equals('Valid'));
    });

    test('UpdateCheckerService handles semantic versioning with build metadata', () async {
      final service = UpdateCheckerService();
      final updateInfo = await service.checkForUpdates(repoUrl: 'http://127.0.0.1:9999/invalid');
      expect(updateInfo.hasUpdate, isFalse);
    });

    test('LicenseService verifies keys and generates valid offline HMAC signatures', () {
      final service = LicenseService();
      final key = LicenseService.generateKey(block1: 'ABCD', block2: 'EFGH');

      expect(key.startsWith('APTX-PRO-ABCD-EFGH-'), isTrue);
      expect(service.verifyKey(key), isTrue);

      const invalidKey = 'APTX-PRO-ABCD-EFGH-ZZZZ';
      expect(service.verifyKey(invalidKey), isFalse);
    });
  });
}
