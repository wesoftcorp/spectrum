import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../data/sources/local/image_file_service.dart';

/// Currently open folder path.
final currentFolderProvider = StateProvider<String?>((ref) => null);

/// Gallery state — async list of images in the current folder.
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
    state = const AsyncLoading();
    ref.read(currentFolderProvider.notifier).state = folderPath;

    // Start live directory watcher
    final watcher = ref.read(fileWatcherServiceProvider);
    watcher.watch(folderPath);

    _watcherSub?.cancel();
    _watcherSub = watcher.onFolderChanged.listen((_) async {
      await refresh();
    });

    // Save as last-used folder
    await ref.read(settingsServiceProvider).setLastFolder(folderPath);
    state = await AsyncValue.guard(
      () => ref.read(imageFileServiceProvider).listImages(folderPath),
    );
  }

  /// Refresh current folder (after file changes or disk events).
  Future<void> refresh() async {
    final folder = ref.read(currentFolderProvider);
    if (folder != null) {
      final images = await ref.read(imageFileServiceProvider).listImages(folder);
      state = AsyncData(images);
    }
  }
}
