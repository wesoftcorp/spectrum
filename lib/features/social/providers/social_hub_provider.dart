import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../models/social_platform.dart';
import '../services/social_publish_service.dart';

class SocialHubState {
  const SocialHubState({
    required this.draft,
    this.isPublishing = false,
    this.lastResult,
    this.optimizedExportPath,
  });

  final SocialPostDraft draft;
  final bool isPublishing;
  final SocialPublishResult? lastResult;
  final String? optimizedExportPath;

  SocialHubState copyWith({
    SocialPostDraft? draft,
    bool? isPublishing,
    SocialPublishResult? Function()? lastResult,
    String? Function()? optimizedExportPath,
  }) {
    return SocialHubState(
      draft: draft ?? this.draft,
      isPublishing: isPublishing ?? this.isPublishing,
      lastResult: lastResult != null ? lastResult() : this.lastResult,
      optimizedExportPath:
          optimizedExportPath != null ? optimizedExportPath() : this.optimizedExportPath,
    );
  }
}

final socialHubProvider =
    StateNotifierProvider.autoDispose.family<SocialHubNotifier, SocialHubState, String>(
  (ref, imagePath) {
    final service = ref.watch(socialPublishServiceProvider);
    return SocialHubNotifier(imagePath: imagePath, service: service);
  },
);

class SocialHubNotifier extends StateNotifier<SocialHubState> {
  SocialHubNotifier({
    required String imagePath,
    required SocialPublishService service,
  })  : _service = service,
        super(
          SocialHubState(
            draft: SocialPostDraft(
              imagePath: imagePath,
              platform: SocialPlatform.instagram,
              preset: SocialPlatform.instagram.presets.first,
              tags: List.from(SocialPlatform.instagram.defaultTags),
            ),
          ),
        );

  final SocialPublishService _service;

  void setPlatform(SocialPlatform platform) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        platform: platform,
        preset: platform.presets.first,
        tags: List.from(platform.defaultTags),
      ),
      lastResult: () => null,
    );
  }

  void setPreset(SocialPreset preset) {
    state = state.copyWith(
      draft: state.draft.copyWith(preset: preset),
    );
  }

  void setCaption(String text) {
    state = state.copyWith(
      draft: state.draft.copyWith(caption: text),
    );
  }

  void setAltText(String text) {
    state = state.copyWith(
      draft: state.draft.copyWith(altText: text),
    );
  }

  void toggleTag(String tag) {
    final current = List<String>.from(state.draft.tags);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      current.add(tag);
    }
    state = state.copyWith(
      draft: state.draft.copyWith(tags: current),
    );
  }

  void setDiscordWebhook(String url) {
    state = state.copyWith(
      draft: state.draft.copyWith(discordWebhookUrl: url),
    );
  }

  void setTelegramCredentials(String token, String chatId) {
    state = state.copyWith(
      draft: state.draft.copyWith(telegramBotToken: token, telegramChatId: chatId),
    );
  }

  Future<SocialPublishResult> shareViaSystem() async {
    state = state.copyWith(isPublishing: true);
    try {
      final res = await _service.shareViaSystem(
        imagePath: state.draft.imagePath,
        text: state.draft.fullFormattedText,
      );
      state = state.copyWith(lastResult: () => res);
      return res;
    } finally {
      state = state.copyWith(isPublishing: false);
    }
  }

  Future<SocialPublishResult> publishToDiscord() async {
    final webhook = state.draft.discordWebhookUrl;
    if (webhook == null || webhook.trim().isEmpty) {
      const err = SocialPublishResult(success: false, message: 'Please provide a valid Discord Webhook URL');
      state = state.copyWith(lastResult: () => err);
      return err;
    }

    state = state.copyWith(isPublishing: true);
    try {
      final res = await _service.publishToDiscord(
        imagePath: state.draft.imagePath,
        webhookUrl: webhook.trim(),
        caption: state.draft.fullFormattedText,
        altText: state.draft.altText.isNotEmpty ? state.draft.altText : null,
      );
      state = state.copyWith(lastResult: () => res);
      return res;
    } finally {
      state = state.copyWith(isPublishing: false);
    }
  }

  Future<SocialPublishResult> publishToTelegram() async {
    final token = state.draft.telegramBotToken;
    final chatId = state.draft.telegramChatId;
    if (token == null || token.trim().isEmpty || chatId == null || chatId.trim().isEmpty) {
      const err = SocialPublishResult(success: false, message: 'Please provide Bot Token and Chat ID');
      state = state.copyWith(lastResult: () => err);
      return err;
    }

    state = state.copyWith(isPublishing: true);
    try {
      final res = await _service.publishToTelegram(
        imagePath: state.draft.imagePath,
        botToken: token.trim(),
        chatId: chatId.trim(),
        caption: state.draft.fullFormattedText,
      );
      state = state.copyWith(lastResult: () => res);
      return res;
    } finally {
      state = state.copyWith(isPublishing: false);
    }
  }

  Future<SocialPublishResult> openPlatformAppOrWeb() async {
    return _service.openPlatform(
      state.draft.platform,
      caption: state.draft.fullFormattedText,
    );
  }

  Future<void> copyCaption() async {
    await _service.copyCaptionToClipboard(state.draft.fullFormattedText);
  }

  Future<String> exportOptimized() async {
    state = state.copyWith(isPublishing: true);
    try {
      final out = await _service.exportPlatformOptimized(
        sourcePath: state.draft.imagePath,
        preset: state.draft.preset,
        platform: state.draft.platform,
      );
      state = state.copyWith(
        optimizedExportPath: () => out,
        lastResult: () => SocialPublishResult(
          success: true,
          message: 'Saved web-ready image: ${out.split(RegExp(r'[\\/]')).last}',
        ),
      );
      return out;
    } finally {
      state = state.copyWith(isPublishing: false);
    }
  }
}
