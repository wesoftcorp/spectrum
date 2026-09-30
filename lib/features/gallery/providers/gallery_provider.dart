import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../data/sources/local/image_file_service.dart';

/// Currently open folder path.
final currentFolderProvider = StateProvider<String?>((ref) => null);

/// Gallery state - async list of images in the current folder.
final galleryProvider =
    AsyncNotifierProvider<GalleryNotifier, List<ImageFile>>(GalleryNotifier.new);

class GalleryNotifier extends AsyncNotifier<List<ImageFile>> {
  StreamSubscription<void>? _watcherSub;

  @override
  Future<List<ImageFile>> build() async {
    ref.onDispose(() {
      _watcherSub?.cancel();
    });
    return [];
  }

  /// Load all supported images from [folderPath] and watch for filesystem changes.
  Future<void> loadFolder(String folderPath) async {
    // Cancel previous watcher
    await _watcherSub?.cancel();
    _watcherSub = null;

    state = const AsyncLoading();
    ref.read(currentFolderProvider.notifier).state = folderPath;

    // Save as last-used folder
    try {
      await ref.read(settingsServiceProvider).setLastFolder(folderPath);
    } catch (_) {}

    // Load image list - fully guarded
    try {
      final images = await ref.read(imageFileServiceProvider).listImages(folderPath);
      state = AsyncData(images);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return;
    }

    // Initialize watcher only after scan completes
    try {
      final watcher = ref.read(fileWatcherServiceProvider);
      watcher.watch(folderPath);
      _watcherSub = watcher.onFolderChanged.listen(
        (_) async => await refresh(),
        onError: (_) {}, // ignore watch errors silently
        cancelOnError: false,
      );
    } catch (_) {
      // File watching is optional - ignore failures
    }
  }

  /// Refresh current folder (after file changes or disk events).
  Future<void> refresh() async {
    final folder = ref.read(currentFolderProvider);
    if (folder == null) return;
    try {
      final images = await ref.read(imageFileServiceProvider).listImages(folder);
      state = AsyncData(images);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}
