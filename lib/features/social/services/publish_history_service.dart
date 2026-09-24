import 'package:shared_preferences/shared_preferences.dart';
import '../models/publish_history_item.dart';

/// Local audit history for published posts across all platforms.
class PublishHistoryService {
  static const String _prefKey = 'apertix_publish_history';
  static const int _maxRecords = 100;

  Future<List<PublishHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey) ?? [];
      return list
          .map((raw) => PublishHistoryItem.deserialize(raw))
          .whereType<PublishHistoryItem>()
          .toList()
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> addRecord(PublishHistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey) ?? [];
      list.insert(0, item.serialize());
      if (list.length > _maxRecords) {
        list.removeRange(_maxRecords, list.length);
      }
      await prefs.setStringList(_prefKey, list);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
