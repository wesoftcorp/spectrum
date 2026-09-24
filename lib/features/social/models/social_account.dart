import 'dart:convert';
import 'social_platform.dart';

/// Securely stored connected social account or webhook endpoint.
class SocialAccount {
  const SocialAccount({
    required this.id,
    required this.platform,
    required this.displayName,
    this.token,
    this.secretOrKey,
    this.webhookUrl,
    this.channelOrChatId,
    required this.connectedAt,
  });

  final String id;
  final SocialPlatform platform;
  final String displayName;
  final String? token;
  final String? secretOrKey;
  final String? webhookUrl;
  final String? channelOrChatId;
  final DateTime connectedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform.name,
      'displayName': displayName,
      'token': token,
      'secretOrKey': secretOrKey,
      'webhookUrl': webhookUrl,
      'channelOrChatId': channelOrChatId,
      'connectedAt': connectedAt.toIso8601String(),
    };
  }

  factory SocialAccount.fromJson(Map<String, dynamic> map) {
    return SocialAccount(
      id: map['id'] as String,
      platform: SocialPlatform.values.firstWhere(
        (p) => p.name == map['platform'],
        orElse: () => SocialPlatform.instagram,
      ),
      displayName: map['displayName'] as String? ?? 'Connected Account',
      token: map['token'] as String?,
      secretOrKey: map['secretOrKey'] as String?,
      webhookUrl: map['webhookUrl'] as String?,
      channelOrChatId: map['channelOrChatId'] as String?,
      connectedAt: DateTime.tryParse(map['connectedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String serialize() => jsonEncode(toJson());

  static SocialAccount? deserialize(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SocialAccount.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
