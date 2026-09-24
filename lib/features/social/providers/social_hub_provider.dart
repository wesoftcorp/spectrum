import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../models/social_platform.dart';
import '../models/social_account.dart';
import '../models/publish_history_item.dart';
import '../services/social_publish_service.dart';
import '../services/token_vault_service.dart';
import '../services/publish_history_service.dart';

class SocialHubState {
  const SocialHubState({
    required this.draft,
    this.isPublishing = false,
    this.lastResult,
    this.optimizedExportPath,
    this.history = const [],
  });

  final SocialPostDraft draft;
  final bool isPublishing;
  final SocialPublishResult? lastResult;
  final String? optimizedExportPath;
  final List<PublishHistoryItem> history;

  SocialHubState copyWith({
    SocialPostDraft? draft,
    bool? isPublishing,
    SocialPublishResult? Function()? lastResult,
    String? Function()? optimizedExportPath,
    List<PublishHistoryItem>? history,
  }) {
    return SocialHubState(
      draft: draft ?? this.draft,
      isPublishing: isPublishing ?? this.isPublishing,
      lastResult: lastResult != null ? lastResult() : this.lastResult,
      optimizedExportPath:
          optimizedExportPath != null ? optimizedExportPath() : this.optimizedExportPath,
      history: history ?? this.history,
    );
  }
}

final socialHubProvider =
    StateNotifierProvider.autoDispose.family<SocialHubNotifier, SocialHubState, String>(
  (ref, imagePath) {
    final service = ref.watch(socialPublishServiceProvider);
    final vault = ref.watch(tokenVaultServiceProvider);
    final history = ref.watch(publishHistoryServiceProvider);
    return SocialHubNotifier(
      imagePath: imagePath,
      service: service,
      vault: vault,
      historyService: history,
    );
  },
);

class SocialHubNotifier extends StateNotifier<SocialHubState> {
  SocialHubNotifier({
    required String imagePath,
    required SocialPublishService service,
    required TokenVaultService vault,
    required PublishHistoryService historyService,
  })  : _service = service,
        _vault = vault,
        _historyService = historyService,
        super(
          SocialHubState(
            draft: SocialPostDraft(
              imagePath: imagePath,
              platform: SocialPlatform.instagram,
              preset: SocialPlatform.instagram.presets.first,
              tags: List.from(SocialPlatform.instagram.defaultTags),
            ),
          ),
        ) {
    _init();
  }

  final SocialPublishService _service;
  final TokenVaultService _vault;
  final PublishHistoryService _historyService;

  Future<void> _init() async {
    await loadHistory();
    await _loadAccountForPlatform(state.draft.platform);
  }

  Future<void> loadHistory() async {
    final list = await _historyService.getHistory();
    state = state.copyWith(history: list);
  }

  Future<void> _loadAccountForPlatform(SocialPlatform platform) async {
    final account = await _vault.getAccount(platform);
    if (account != null) {
      state = state.copyWith(
        draft: state.draft.copyWith(
          discordWebhookUrl: account.webhookUrl,
          telegramBotToken: account.token,
          telegramChatId: account.channelOrChatId,
        ),
      );
    }
  }

  Future<void> setPlatform(SocialPlatform platform) async {
    state = state.copyWith(
      draft: state.draft.copyWith(
        platform: platform,
        preset: platform.presets.first,
        tags: List.from(platform.defaultTags),
      ),
      lastResult: () => null,
    );
    await _loadAccountForPlatform(platform);
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

  Future<void> setDiscordWebhook(String url) async {
    state = state.copyWith(
      draft: state.draft.copyWith(discordWebhookUrl: url),
    );
    if (url.trim().isNotEmpty) {
      await _vault.saveAccount(
        SocialAccount(
          id: 'discord_${DateTime.now().millisecondsSinceEpoch}',
          platform: SocialPlatform.discord,
          displayName: 'Discord Webhook',
          webhookUrl: url.trim(),
          connectedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> setTelegramCredentials(String token, String chatId) async {
    state = state.copyWith(
      draft: state.draft.copyWith(telegramBotToken: token, telegramChatId: chatId),
    );
    if (token.trim().isNotEmpty && chatId.trim().isNotEmpty) {
      await _vault.saveAccount(
        SocialAccount(
          id: 'telegram_${DateTime.now().millisecondsSinceEpoch}',
          platform: SocialPlatform.telegram,
          displayName: 'Telegram Channel',
          token: token.trim(),
          channelOrChatId: chatId.trim(),
          connectedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<SocialPublishResult> shareViaSystem() async {
    state = state.copyWith(isPublishing: true);
    try {
      final res = await _service.shareViaSystem(
        imagePath: state.draft.imagePath,
        text: state.draft.fullFormattedText,
      );
      state = state.copyWith(lastResult: () => res);

      await _historyService.addRecord(
        PublishHistoryItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          platform: state.draft.platform,
          imagePath: state.draft.imagePath,
          caption: state.draft.caption,
          publishedAt: DateTime.now(),
          success: res.success,
          resultMessage: res.message,
        ),
      );
      await loadHistory();
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

      await _historyService.addRecord(
        PublishHistoryItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          platform: SocialPlatform.discord,
          imagePath: state.draft.imagePath,
          caption: state.draft.caption,
          publishedAt: DateTime.now(),
          success: res.success,
          resultMessage: res.message,
        ),
      );
      await loadHistory();
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

      await _historyService.addRecord(
        PublishHistoryItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          platform: SocialPlatform.telegram,
          imagePath: state.draft.imagePath,
          caption: state.draft.caption,
          publishedAt: DateTime.now(),
          success: res.success,
          resultMessage: res.message,
        ),
      );
      await loadHistory();
      return res;
    } finally {
      state = state.copyWith(isPublishing: false);
    }
  }

  Future<SocialPublishResult> openPlatformAppOrWeb() async {
    final res = await _service.openPlatform(
      state.draft.platform,
      caption: state.draft.fullFormattedText,
    );
    await _historyService.addRecord(
      PublishHistoryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        platform: state.draft.platform,
        imagePath: state.draft.imagePath,
        caption: state.draft.caption,
        publishedAt: DateTime.now(),
        success: res.success,
        resultMessage: res.message,
        postUrl: res.url,
      ),
    );
    await loadHistory();
    return res;
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
