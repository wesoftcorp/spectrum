import 'dart:convert';
import 'social_platform.dart';

/// Item in the local social publishing audit history.
class PublishHistoryItem {
  const PublishHistoryItem({
    required this.id,
    required this.platform,
    required this.imagePath,
    required this.caption,
    required this.publishedAt,
    required this.success,
    required this.resultMessage,
    this.postUrl,
  });

  final String id;
  final SocialPlatform platform;
  final String imagePath;
  final String caption;
  final DateTime publishedAt;
  final bool success;
  final String resultMessage;
  final String? postUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform.name,
        'imagePath': imagePath,
        'caption': caption,
        'publishedAt': publishedAt.toIso8601String(),
        'success': success,
        'resultMessage': resultMessage,
        'postUrl': postUrl,
      };

  factory PublishHistoryItem.fromJson(Map<String, dynamic> map) {
    return PublishHistoryItem(
      id: map['id'] as String,
      platform: SocialPlatform.values.firstWhere(
        (p) => p.name == map['platform'],
        orElse: () => SocialPlatform.instagram,
      ),
      imagePath: map['imagePath'] as String? ?? '',
      caption: map['caption'] as String? ?? '',
      publishedAt: DateTime.tryParse(map['publishedAt'] as String? ?? '') ?? DateTime.now(),
      success: map['success'] as bool? ?? false,
      resultMessage: map['resultMessage'] as String? ?? '',
      postUrl: map['postUrl'] as String?,
    );
  }

  String serialize() => jsonEncode(toJson());

  static PublishHistoryItem? deserialize(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PublishHistoryItem.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
