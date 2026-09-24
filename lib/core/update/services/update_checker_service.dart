import 'package:dio/dio.dart';
import '../../constants/app_constants.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    this.releaseNotes = '',
    this.downloadUrl = '',
    this.publishedAt,
  });

  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final DateTime? publishedAt;
}

/// Service that checks GitHub Releases for new Apertix application versions.
class UpdateCheckerService {
  UpdateCheckerService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const _releasesApiUrl = 'https://api.github.com/repos/wesoftcorp/apertix/releases/latest';

  /// Compares current app version against GitHub latest release tag.
  Future<UpdateInfo> checkForUpdates({String repoUrl = _releasesApiUrl}) async {
    const current = AppConstants.appVersion;

    try {
      final response = await _dio.get(
        repoUrl,
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final tagName = (data['tag_name'] as String? ?? '').replaceFirst(RegExp(r'^[vV]'), '');
        final body = data['body'] as String? ?? '';
        final htmlUrl = data['html_url'] as String? ?? 'https://github.com/wesoftcorp/apertix/releases';
        final published = DateTime.tryParse(data['published_at'] as String? ?? '');

        final hasNewer = _isVersionGreater(tagName, current);

        return UpdateInfo(
          hasUpdate: hasNewer,
          currentVersion: current,
          latestVersion: tagName.isNotEmpty ? tagName : current,
          releaseNotes: body,
          downloadUrl: htmlUrl,
          publishedAt: published,
        );
      }
    } catch (_) {
      // Offline fallback: no update available
    }

    return const UpdateInfo(
      hasUpdate: false,
      currentVersion: current,
      latestVersion: current,
    );
  }

  /// Evaluates if versionA > versionB (e.g., "0.2.0" > "0.1.0").
  static bool _isVersionGreater(String versionA, String versionB) {
    if (versionA.isEmpty || versionB.isEmpty) return false;
    final partsA = versionA.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final partsB = versionB.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final maxLen = partsA.length > partsB.length ? partsA.length : partsB.length;
    for (int i = 0; i < maxLen; i++) {
      final a = i < partsA.length ? partsA[i] : 0;
      final b = i < partsB.length ? partsB[i] : 0;
      if (a > b) return true;
      if (a < b) return false;
    }
    return false;
  }
}
