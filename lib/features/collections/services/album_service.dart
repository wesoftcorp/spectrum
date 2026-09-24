import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/album.dart';

/// Service managing virtual zero-duplication photo albums.
class AlbumService {
  static const _key = 'apertix_virtual_albums';
  final _uuid = const Uuid();

  /// Loads all saved albums.
  Future<List<Album>> loadAlbums() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    return rawList.map((str) {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return Album.fromJson(map);
    }).toList();
  }

  /// Creates a new virtual album.
  Future<Album> createAlbum({
    required String name,
    String description = '',
    String? coverPath,
    List<String> initialPaths = const [],
  }) async {
    final albums = await loadAlbums();
    final newAlbum = Album(
      id: _uuid.v4(),
      name: name.trim(),
      description: description.trim(),
      coverPath: coverPath ?? (initialPaths.isNotEmpty ? initialPaths.first : null),
      imagePaths: initialPaths,
      createdAt: DateTime.now(),
    );

    albums.insert(0, newAlbum);
    await _saveAlbums(albums);
    return newAlbum;
  }

  /// Deletes an album by id.
  Future<void> deleteAlbum(String albumId) async {
    final albums = await loadAlbums();
    albums.removeWhere((a) => a.id == albumId);
    await _saveAlbums(albums);
  }

  /// Adds a list of image paths to an existing album.
  Future<void> addImagesToAlbum(String albumId, List<String> paths) async {
    final albums = await loadAlbums();
    final index = albums.indexWhere((a) => a.id == albumId);
    if (index == -1) return;

    final target = albums[index];
    final updatedPaths = target.imagePaths.toSet()..addAll(paths);
    albums[index] = target.copyWith(
      imagePaths: updatedPaths.toList(),
      coverPath: target.coverPath ?? (paths.isNotEmpty ? paths.first : null),
    );
    await _saveAlbums(albums);
  }

  /// Removes an image from an album.
  Future<void> removeImageFromAlbum(String albumId, String path) async {
    final albums = await loadAlbums();
    final index = albums.indexWhere((a) => a.id == albumId);
    if (index == -1) return;

    final target = albums[index];
    final updatedPaths = target.imagePaths.where((p) => p != path).toList();
    albums[index] = target.copyWith(
      imagePaths: updatedPaths,
      coverPath: target.coverPath == path
          ? (updatedPaths.isNotEmpty ? updatedPaths.first : null)
          : target.coverPath,
    );
    await _saveAlbums(albums);
  }

  Future<void> _saveAlbums(List<Album> albums) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = albums.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_key, rawList);
  }
}
