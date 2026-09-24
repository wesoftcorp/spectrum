// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/social_platform.dart';

class SocialPublishResult {
  const SocialPublishResult({
    required this.success,
    required this.message,
    this.url,
  });

  final bool success;
  final String message;
  final String? url;
}

/// Service providing multi-platform social dispatch, webhooks, system share, and platform optimization.
class SocialPublishService {
  SocialPublishService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 25),
              ),
            );

  final Dio _dio;

  /// Invokes native OS share sheet (Windows & Android) with the image file and caption.
  Future<SocialPublishResult> shareViaSystem({
    required String imagePath,
    required String text,
  }) async {
    try {
      final file = XFile(imagePath);
      final result = await Share.shareXFiles(
        [file],
        text: text.isNotEmpty ? text : null,
      );

      if (result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed) {
        return const SocialPublishResult(
          success: true,
          message: 'Shared successfully via system sheet',
        );
      }
      return const SocialPublishResult(
        success: true,
        message: 'System share opened',
      );
    } catch (e) {
      return SocialPublishResult(
        success: false,
        message: 'System share failed: $e',
      );
    }
  }

  /// Direct webhook dispatch to Discord server channel.
  Future<SocialPublishResult> publishToDiscord({
    required String imagePath,
    required String webhookUrl,
    required String caption,
    String? altText,
  }) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        return const SocialPublishResult(success: false, message: 'Image file does not exist');
      }

      final fileName = p.basename(imagePath);
      final formData = FormData.fromMap({
        'content': caption,
        'file': await MultipartFile.fromFile(
          imagePath,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        webhookUrl,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return const SocialPublishResult(
          success: true,
          message: 'Successfully posted to Discord channel!',
        );
      } else {
        return SocialPublishResult(
          success: false,
          message: 'Discord returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return SocialPublishResult(
        success: false,
        message: 'Discord webhook error: $e',
      );
    }
  }

  /// Direct post to Telegram Chat/Channel via official Telegram Bot API.
  Future<SocialPublishResult> publishToTelegram({
    required String imagePath,
    required String botToken,
    required String chatId,
    required String caption,
  }) async {
    try {
      final url = 'https://api.telegram.org/bot$botToken/sendPhoto';
      final fileName = p.basename(imagePath);

      final formData = FormData.fromMap({
        'chat_id': chatId,
        'caption': caption,
        'photo': await MultipartFile.fromFile(
          imagePath,
          filename: fileName,
        ),
      });

      final response = await _dio.post(url, data: formData);

      if (response.statusCode == 200 && response.data['ok'] == true) {
        return const SocialPublishResult(
          success: true,
          message: 'Successfully posted photo to Telegram!',
        );
      } else {
        final desc = response.data['description'] ?? 'Telegram API error';
        return SocialPublishResult(
          success: false,
          message: 'Telegram: $desc',
        );
      }
    } catch (e) {
      return SocialPublishResult(
        success: false,
        message: 'Telegram dispatch failed: $e',
      );
    }
  }

  /// Launch platform app via URI scheme or open official web publisher in default browser.
  Future<SocialPublishResult> openPlatform(
    SocialPlatform platform, {
    String? caption,
  }) async {
    try {
      final appUri = Uri.parse(platform.urlScheme);
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return SocialPublishResult(
          success: true,
          message: 'Opened ${platform.name} application',
        );
      }

      // Fallback to web publisher
      var targetUrl = platform.webUrl;
      if (platform == SocialPlatform.xTwitter && caption != null && caption.isNotEmpty) {
        targetUrl = 'https://x.com/intent/tweet?text=${Uri.encodeComponent(caption)}';
      }

      final webUri = Uri.parse(targetUrl);
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return SocialPublishResult(
        success: true,
        message: 'Opened ${platform.name} web portal',
        url: targetUrl,
      );
    } catch (e) {
      return SocialPublishResult(
        success: false,
        message: 'Failed to launch ${platform.name}: $e',
      );
    }
  }

  /// Copies formatted caption and hashtags to the system clipboard.
  Future<void> copyCaptionToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Generates a platform-optimized image cropped to the exact target ratio,
  /// resized to platform dimension specs, and stripped of EXIF metadata for privacy.
  Future<String> exportPlatformOptimized({
    required String sourcePath,
    required SocialPreset preset,
    required SocialPlatform platform,
  }) async {
    return compute(_optimizeImageTask, _OptimizeParams(sourcePath, preset, platform));
  }

  static String _optimizeImageTask(_OptimizeParams params) {
    final bytes = File(params.sourcePath).readAsBytesSync();
    var image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode source image');
    }

    image = img.bakeOrientation(image);

    // 1. Crop to target aspect ratio (centered) if preset defines one
    if (params.preset.ratio != null) {
      final targetRatio = params.preset.ratio!;
      final currentRatio = image.width / image.height;

      int cropW = image.width;
      int cropH = image.height;

      if (currentRatio > targetRatio) {
        // Image is wider than desired -> trim sides
        cropW = (image.height * targetRatio).round().clamp(1, image.width);
      } else {
        // Image is taller than desired -> trim top/bottom
        cropH = (image.width / targetRatio).round().clamp(1, image.height);
      }

      final cropX = ((image.width - cropW) / 2).round();
      final cropY = ((image.height - cropH) / 2).round();

      image = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );
    }

    // 2. Resize to platform optimal target resolution
    if (params.preset.width != null && params.preset.height != null) {
      image = img.copyResize(
        image,
        width: params.preset.width,
        height: params.preset.height,
        interpolation: img.Interpolation.linear,
      );
    }

    // 3. Strip EXIF metadata for privacy and encode as high-quality web JPEG
    final encoded = img.encodeJpg(image, quality: 92);

    final dir = p.dirname(params.sourcePath);
    final baseName = p.basenameWithoutExtension(params.sourcePath);
    final outPath = p.join(
      dir,
      '${baseName}_${params.platform.name.toLowerCase()}_${params.preset.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}.jpg',
    );

    File(outPath).writeAsBytesSync(encoded);
    return outPath;
  }
}

class _OptimizeParams {
  const _OptimizeParams(this.sourcePath, this.preset, this.platform);
  final String sourcePath;
  final SocialPreset preset;
  final SocialPlatform platform;
}
