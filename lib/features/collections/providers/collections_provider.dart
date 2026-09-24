import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../services/favorites_service.dart';
import '../services/album_service.dart';

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

final albumServiceProvider = Provider<AlbumService>((ref) {
  return AlbumService();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._service) : super({}) {
    _load();
  }

  final FavoritesService _service;

  Future<void> _load() async {
    final favs = await _service.loadFavorites();
    state = favs;
  }

  Future<void> toggle(String path) async {
    final updated = await _service.toggleFavorite(path);
    if (updated) {
      state = {...state, path};
    } else {
      state = state.where((p) => p != path).toSet();
    }
  }

  bool isFavorite(String path) => state.contains(path);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref.watch(favoritesServiceProvider));
});

class AlbumsNotifier extends StateNotifier<List<Album>> {
  AlbumsNotifier(this._service) : super([]) {
    _load();
  }

  final AlbumService _service;

  Future<void> _load() async {
    final list = await _service.loadAlbums();
    state = list;
  }

  Future<Album> createAlbum({
    required String name,
    String description = '',
    List<String> initialPaths = const [],
  }) async {
    final newAlbum = await _service.createAlbum(
      name: name,
      description: description,
      initialPaths: initialPaths,
    );
    state = [newAlbum, ...state];
    return newAlbum;
  }

  Future<void> addImagesToAlbum(String albumId, List<String> paths) async {
    await _service.addImagesToAlbum(albumId, paths);
    await _load();
  }

  Future<void> deleteAlbum(String albumId) async {
    await _service.deleteAlbum(albumId);
    state = state.where((a) => a.id != albumId).toList();
  }
}

final albumsProvider = StateNotifierProvider<AlbumsNotifier, List<Album>>((ref) {
  return AlbumsNotifier(ref.watch(albumServiceProvider));
});
