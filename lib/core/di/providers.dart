import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sources/local/image_file_service.dart';
import '../../data/sources/local/settings_service.dart';
import '../../data/sources/local/file_watcher_service.dart';
import '../../data/cache/image_cache_manager.dart';
import '../../features/social/services/social_publish_service.dart';
import '../../features/social/services/token_vault_service.dart';
import '../../features/social/services/publish_history_service.dart';
import '../../features/social/services/publish_engine.dart';

/// Isar database singleton provider (lazy / optional until Phase 3 schema).
final isarProvider = Provider<dynamic>((ref) => null);

/// Image file service — browses folders and lists images.
final imageFileServiceProvider = Provider<ImageFileService>((ref) {
  return ImageFileService();
});

/// App-wide image cache.
final imageCacheManagerProvider = Provider<ImageCacheManager>((ref) {
  return ImageCacheManager();
});

/// Settings service backed by SharedPreferences.
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// File watcher service for real-time folder updates.
final fileWatcherServiceProvider = Provider<FileWatcherService>((ref) {
  final service = FileWatcherService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Social publishing service (Social Hub - Phase 6).
final socialPublishServiceProvider = Provider<SocialPublishService>((ref) {
  return SocialPublishService();
});

/// Encrypted token vault service for social credentials.
final tokenVaultServiceProvider = Provider<TokenVaultService>((ref) {
  return TokenVaultService();
});

/// Publish history audit service.
final publishHistoryServiceProvider = Provider<PublishHistoryService>((ref) {
  return PublishHistoryService();
});

/// Parallel multi-platform publish engine (Phase 7).
final publishEngineProvider = Provider<PublishEngine>((ref) {
  final publishService = ref.watch(socialPublishServiceProvider);
  final historyService = ref.watch(publishHistoryServiceProvider);
  return PublishEngine(publishService: publishService, historyService: historyService);
});

/// Bootstrap all providers that need async init.
Future<ProviderContainer> createProviderContainer() async {
  return ProviderContainer();
}
