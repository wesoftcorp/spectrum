import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Viewer state model.
class ViewerState {
  const ViewerState({
    required this.filePaths,
    required this.currentIndex,
  });

  final List<String> filePaths;
  final int currentIndex;

  String? get currentPath =>
      (filePaths.isNotEmpty && currentIndex >= 0 && currentIndex < filePaths.length)
          ? filePaths[currentIndex]
          : null;

  ViewerState copyWith({List<String>? filePaths, int? currentIndex}) =>
      ViewerState(
        filePaths: filePaths ?? this.filePaths,
        currentIndex: currentIndex ?? this.currentIndex,
      );
}

/// Viewer state provider.
final viewerProvider =
    AsyncNotifierProvider<ViewerNotifier, ViewerState>(ViewerNotifier.new);

class ViewerNotifier extends AsyncNotifier<ViewerState> {
  @override
  Future<ViewerState> build() async =>
      const ViewerState(filePaths: [], currentIndex: 0);

  /// Initialise with a file list and starting index.
  void init({required List<String> filePaths, required int initialIndex}) {
    state = AsyncData(
      ViewerState(filePaths: filePaths, currentIndex: initialIndex),
    );
  }

  /// Set the current image index directly (e.g. thumbnail strip tap).
  void setIndex(int index) {
    state.whenData((vs) {
      if (index >= 0 && index < vs.filePaths.length) {
        state = AsyncData(vs.copyWith(currentIndex: index));
      }
    });
  }

  /// Navigate by [delta] (-1 = prev, +1 = next).
  /// Returns the new index if valid, null otherwise.
  int? navigate(int delta, {bool loop = true}) {
    int? newIndex;
    state.whenData((vs) {
      if (vs.filePaths.isEmpty) return;
      int candidate = vs.currentIndex + delta;
      if (loop && vs.filePaths.length > 1) {
        candidate = (candidate + vs.filePaths.length) % vs.filePaths.length;
      }
      if (candidate >= 0 && candidate < vs.filePaths.length) {
        newIndex = candidate;
        state = AsyncData(vs.copyWith(currentIndex: candidate));
      }
    });
    return newIndex;
  }

  /// Remove a deleted file path from the viewer playlist.
  /// Returns the new index, or null if no files remain.
  int? removePath(String path) {
    int? nextIndex;
    state.whenData((vs) {
      final updatedList = List<String>.from(vs.filePaths)..remove(path);
      if (updatedList.isEmpty) {
        state = const AsyncData(ViewerState(filePaths: [], currentIndex: 0));
        nextIndex = null;
      } else {
        final clampedIndex = vs.currentIndex.clamp(0, updatedList.length - 1);
        state = AsyncData(vs.copyWith(filePaths: updatedList, currentIndex: clampedIndex));
        nextIndex = clampedIndex;
      }
    });
    return nextIndex;
  }
}
