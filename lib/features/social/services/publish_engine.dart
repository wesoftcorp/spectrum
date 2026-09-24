import 'dart:async';
import '../models/social_platform.dart';
import '../models/publish_history_item.dart';
import 'social_publish_service.dart';
import 'publish_history_service.dart';

enum DispatchStatus { idle, queued, inProgress, success, failed }

class PlatformDispatchState {
  const PlatformDispatchState({
    required this.platform,
    this.status = DispatchStatus.idle,
    this.message,
    this.postUrl,
  });

  final SocialPlatform platform;
  final DispatchStatus status;
  final String? message;
  final String? postUrl;

  PlatformDispatchState copyWith({
    DispatchStatus? status,
    String? message,
    String? postUrl,
  }) {
    return PlatformDispatchState(
      platform: platform,
      status: status ?? this.status,
      message: message ?? this.message,
      postUrl: postUrl ?? this.postUrl,
    );
  }
}

/// Concurrent multi-platform publishing engine with per-target status tracking.
class PublishEngine {
  PublishEngine({
    required SocialPublishService publishService,
    required PublishHistoryService historyService,
  })  : _publishService = publishService,
        _historyService = historyService;

  final SocialPublishService _publishService;
  final PublishHistoryService _historyService;

  /// Dispatches [draft] simultaneously across all [targetPlatforms].
  Future<Map<SocialPlatform, SocialPublishResult>> publishMulti({
    required SocialPostDraft draft,
    required Set<SocialPlatform> targetPlatforms,
    required void Function(SocialPlatform platform, PlatformDispatchState state) onProgress,
  }) async {
    final results = <SocialPlatform, SocialPublishResult>{};

    // 1. Mark all queued
    for (final p in targetPlatforms) {
      onProgress(p, PlatformDispatchState(platform: p, status: DispatchStatus.queued));
    }

    // 2. Execute parallel dispatches
    final futures = targetPlatforms.map((platform) async {
      onProgress(
        platform,
        PlatformDispatchState(platform: platform, status: DispatchStatus.inProgress, message: 'Publishing...'),
      );

      SocialPublishResult res;
      try {
        if (platform == SocialPlatform.discord) {
          final webhook = draft.discordWebhookUrl;
          if (webhook != null && webhook.isNotEmpty) {
            res = await _publishService.publishToDiscord(
              imagePath: draft.imagePath,
              webhookUrl: webhook,
              caption: draft.fullFormattedText,
              altText: draft.altText.isNotEmpty ? draft.altText : null,
            );
          } else {
            res = const SocialPublishResult(success: false, message: 'No Discord webhook configured');
          }
        } else if (platform == SocialPlatform.telegram) {
          final token = draft.telegramBotToken;
          final chatId = draft.telegramChatId;
          if (token != null && chatId != null && token.isNotEmpty && chatId.isNotEmpty) {
            res = await _publishService.publishToTelegram(
              imagePath: draft.imagePath,
              botToken: token,
              chatId: chatId,
              caption: draft.fullFormattedText,
            );
          } else {
            res = const SocialPublishResult(success: false, message: 'No Telegram bot token or chat ID');
          }
        } else {
          // Native system share or app launcher fallback
          res = await _publishService.shareViaSystem(
            imagePath: draft.imagePath,
            text: draft.fullFormattedText,
          );
        }
      } catch (e) {
        res = SocialPublishResult(success: false, message: e.toString());
      }

      results[platform] = res;

      // Update progress state
      onProgress(
        platform,
        PlatformDispatchState(
          platform: platform,
          status: res.success ? DispatchStatus.success : DispatchStatus.failed,
          message: res.message,
          postUrl: res.url,
        ),
      );

      // Save to audit history
      await _historyService.addRecord(
        PublishHistoryItem(
          id: '${platform.name}_${DateTime.now().microsecondsSinceEpoch}',
          platform: platform,
          imagePath: draft.imagePath,
          caption: draft.caption,
          publishedAt: DateTime.now(),
          success: res.success,
          resultMessage: res.message,
          postUrl: res.url,
        ),
      );
    });

    await Future.wait(futures);
    return results;
  }
}
