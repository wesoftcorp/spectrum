import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cloud_config.dart';

/// Secure cloud vault backup service for WebDAV, Supabase Storage, and Custom HTTP.
class CloudVaultService {
  CloudVaultService({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const _configPrefsKey = 'apertix_cloud_vault_config';
  static const _secretKey = 'apertix_cloud_vault_secret';

  /// Saves the CloudConfig with encrypted credentials.
  Future<void> saveConfig(CloudConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configPrefsKey, jsonEncode(config.toJson()));
    await _secureStorage.write(key: _secretKey, value: config.passwordOrToken);
  }

  /// Loads the saved CloudConfig.
  Future<CloudConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configPrefsKey);
    if (raw == null) return null;

    final secret = await _secureStorage.read(key: _secretKey) ?? '';
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return CloudConfig.fromJson(map, passwordOrToken: secret);
  }

  /// Tests connectivity to the configured cloud vault endpoint.
  Future<bool> testConnection(CloudConfig config) async {
    try {
      final cleanUrl = config.serverUrl.trim();
      if (cleanUrl.isEmpty) return false;
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null || (!uri.isScheme('https') && !uri.isScheme('http'))) {
        return false;
      }

      switch (config.providerType) {
        case CloudProviderType.webdav:
          final authStr = base64Encode(utf8.encode('${config.username}:${config.passwordOrToken}'));
          final response = await _dio.request(
            cleanUrl,
            options: Options(
              method: 'PROPFIND',
              headers: {
                'Authorization': 'Basic $authStr',
                'Depth': '0',
              },
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );
          return response.statusCode != null && response.statusCode! < 400;

        case CloudProviderType.supabase:
          final url = '$cleanUrl/storage/v1/bucket';
          final response = await _dio.get(
            url,
            options: Options(
              headers: {
                'apikey': config.passwordOrToken,
                'Authorization': 'Bearer ${config.passwordOrToken}',
              },
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );
          return response.statusCode != null && response.statusCode! < 400;

        case CloudProviderType.customHttp:
          final response = await _dio.head(
            cleanUrl,
            options: Options(
              headers: config.passwordOrToken.isNotEmpty
                  ? {'Authorization': 'Bearer ${config.passwordOrToken}'}
                  : null,
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );
          return response.statusCode != null && response.statusCode! < 400;
      }
    } catch (_) {
      return false;
    }
  }

  /// Uploads a single media file to the cloud vault.
  Future<void> uploadFile(
    String filePath,
    CloudConfig config, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    final fileName = p.basename(filePath);
    final encodedFileName = Uri.encodeComponent(fileName);
    final cleanUrl = config.serverUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(cleanUrl);
    if (uri == null || (!uri.isScheme('https') && !uri.isScheme('http'))) {
      throw const FormatException('Server URL must be a valid HTTP or HTTPS address');
    }
    final cleanTarget = config.targetBucketOrFolder
        .trim()
        .replaceAll(RegExp(r'^/+|/+$'), '')
        .split('/')
        .where((s) => s.isNotEmpty && s != '..' && s != '.')
        .map(Uri.encodeComponent)
        .join('/');

    switch (config.providerType) {
      case CloudProviderType.webdav:
        final uploadUrl = cleanTarget.isEmpty
            ? '$cleanUrl/$encodedFileName'
            : '$cleanUrl/$cleanTarget/$encodedFileName';
        final authStr = base64Encode(utf8.encode('${config.username}:${config.passwordOrToken}'));
        final stream = file.openRead();
        final length = await file.length();

        await _dio.put(
          uploadUrl,
          data: stream,
          options: Options(
            sendTimeout: const Duration(minutes: 5),
            headers: {
              'Authorization': 'Basic $authStr',
              'Content-Length': length,
            },
          ),
          onSendProgress: onProgress,
        );
        break;

      case CloudProviderType.supabase:
        final uploadUrl = cleanTarget.isEmpty
            ? '$cleanUrl/storage/v1/object/$encodedFileName'
            : '$cleanUrl/storage/v1/object/$cleanTarget/$encodedFileName';
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: fileName),
        });

        await _dio.post(
          uploadUrl,
          data: formData,
          options: Options(
            sendTimeout: const Duration(minutes: 5),
            headers: {
              'apikey': config.passwordOrToken,
              'Authorization': 'Bearer ${config.passwordOrToken}',
              'x-upsert': 'true',
            },
          ),
          onSendProgress: onProgress,
        );
        break;

      case CloudProviderType.customHttp:
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(filePath, filename: fileName),
          'folder': cleanTarget,
        });

        await _dio.post(
          cleanUrl,
          data: formData,
          options: Options(
            sendTimeout: const Duration(minutes: 5),
            headers: config.passwordOrToken.isNotEmpty
                ? {'Authorization': 'Bearer ${config.passwordOrToken}'}
                : null,
          ),
          onSendProgress: onProgress,
        );
        break;
    }
  }
}
