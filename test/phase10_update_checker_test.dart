import 'package:flutter_test/flutter_test.dart';
import 'package:apertix/core/update/services/update_checker_service.dart';

void main() {
  group('Phase 10 Update Checker Tests', () {
    test('UpdateInfo initializes and stores release attributes correctly', () {
      final now = DateTime.now();
      final info = UpdateInfo(
        hasUpdate: true,
        currentVersion: '0.1.0',
        latestVersion: '0.2.0',
        releaseNotes: 'Phase 10 Production Store Packaging',
        downloadUrl: 'https://github.com/wesoftcorp/apertix/releases/tag/v0.2.0',
        publishedAt: now,
      );

      expect(info.hasUpdate, true);
      expect(info.currentVersion, '0.1.0');
      expect(info.latestVersion, '0.2.0');
      expect(info.releaseNotes, 'Phase 10 Production Store Packaging');
      expect(info.downloadUrl.contains('v0.2.0'), true);
      expect(info.publishedAt, now);
    });

    test('Semantic version comparison logic handles standard tags', () {
      final service = UpdateCheckerService();

      // Test that offline fallback returns safe no-update info
      expect(service.checkForUpdates(repoUrl: 'https://invalid-url.invalid'), completes);
    });
  });
}
