import 'package:flutter_test/flutter_test.dart';
import 'package:apertix/features/collections/models/album.dart';
import 'package:apertix/features/cloud/models/cloud_config.dart';

void main() {
  group('Phase 9 Virtual Album Models & Serialization', () {
    test('Album serialization and deserialization retains all fields', () {
      final now = DateTime.now();
      final album = Album(
        id: 'test-album-1',
        name: 'Nordic Trip',
        description: 'Captured in Tromsø',
        coverPath: '/photos/aurora.jpg',
        imagePaths: ['/photos/aurora.jpg', '/photos/fjord.png'],
        createdAt: now,
      );

      final json = album.toJson();
      final restored = Album.fromJson(json);

      expect(restored.id, 'test-album-1');
      expect(restored.name, 'Nordic Trip');
      expect(restored.description, 'Captured in Tromsø');
      expect(restored.count, 2);
      expect(restored.contains('/photos/aurora.jpg'), true);
      expect(restored.contains('/photos/random.jpg'), false);
    });

    test('Album copyWith updates fields without mutating original', () {
      final album = Album(
        id: 'alb-2',
        name: 'Street Photography',
        createdAt: DateTime.now(),
      );

      final updated = album.copyWith(
        name: 'Monochrome Street',
        imagePaths: ['/street1.jpg'],
      );

      expect(album.name, 'Street Photography');
      expect(updated.name, 'Monochrome Street');
      expect(updated.count, 1);
    });
  });

  group('Phase 9 CloudConfig & Secure Vault Models', () {
    test('CloudConfig excludes sensitive password from plain JSON', () {
      const config = CloudConfig(
        providerType: CloudProviderType.webdav,
        serverUrl: 'https://nas.local/dav',
        username: 'photographer',
        passwordOrToken: 'super-secret-token',
        targetBucketOrFolder: 'vault-2026',
      );

      final json = config.toJson();
      expect(json['passwordOrToken'], isNull, reason: 'Secrets must not be stored in plain JSON config');
      expect(json['serverUrl'], 'https://nas.local/dav');
      expect(json['username'], 'photographer');
      expect(json['targetBucketOrFolder'], 'vault-2026');

      final restored = CloudConfig.fromJson(json, passwordOrToken: 'super-secret-token');
      expect(restored.passwordOrToken, 'super-secret-token');
      expect(restored.providerType, CloudProviderType.webdav);
    });

    test('CloudUploadItem tracks status and progress changes', () {
      final item = CloudUploadItem(filePath: '/photos/landscape.webp');
      expect(item.status, UploadStatus.pending);
      expect(item.progress, 0.0);

      item.status = UploadStatus.uploading;
      item.progress = 0.55;
      expect(item.status, UploadStatus.uploading);
      expect(item.progress, 0.55);

      item.status = UploadStatus.success;
      item.progress = 1.0;
      expect(item.status, UploadStatus.success);
    });
  });
}
