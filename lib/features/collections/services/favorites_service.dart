import 'package:shared_preferences/shared_preferences.dart';

/// Service managing persistent user favorites across sessions.
class FavoritesService {
  static const _key = 'apertix_favorite_paths';

  /// Loads favorite image paths from persistent storage.
  Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  /// Checks if a file path is marked as favorite.
  Future<bool> isFavorite(String path) async {
    final favorites = await loadFavorites();
    return favorites.contains(path);
  }

  /// Toggles favorite status for a path. Returns updated boolean state.
  Future<bool> toggleFavorite(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? []).toSet();
    final isFav = current.contains(path);

    if (isFav) {
      current.remove(path);
    } else {
      current.add(path);
    }

    await prefs.setStringList(_key, current.toList());
    return !isFav;
  }

  /// Explicitly adds a favorite path.
  Future<void> addFavorite(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? []).toSet();
    current.add(path);
    await prefs.setStringList(_key, current.toList());
  }

  /// Removes a favorite path.
  Future<void> removeFavorite(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? []).toSet();
    current.remove(path);
    await prefs.setStringList(_key, current.toList());
  }
}
