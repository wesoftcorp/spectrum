import 'package:flutter/material.dart';

/// Aspect ratio preset for social platforms with recommended pixel dimensions.
class SocialPreset {
  const SocialPreset(this.name, this.width, this.height, this.ratio);

  final String name;
  final int? width;
  final int? height;
  final double? ratio;

  String get resolutionLabel =>
      (width != null && height != null) ? '$width×$height' : 'Original';
}

/// 8 supported social publishing platforms with brand metadata, character limits, and presets.
enum SocialPlatform {
  instagram(
    name: 'Instagram',
    brandColor: Color(0xFFE1306C),
    gradientColors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
    icon: Icons.camera_alt_rounded,
    maxChars: 2200,
    webUrl: 'https://www.instagram.com/',
    urlScheme: 'instagram://app',
    presets: [
      SocialPreset('Portrait (4:5)', 1080, 1350, 4 / 5),
      SocialPreset('Square (1:1)', 1080, 1080, 1.0),
      SocialPreset('Story (9:16)', 1080, 1920, 9 / 16),
    ],
    defaultTags: ['#photography', '#photooftheday', '#visualsoflife', '#art'],
  ),

  xTwitter(
    name: 'X (Twitter)',
    brandColor: Color(0xFF1DA1F2),
    gradientColors: [Color(0xFF1DA1F2), Color(0xFF0E71C8)],
    icon: Icons.tag_rounded,
    maxChars: 280,
    webUrl: 'https://x.com/intent/tweet',
    urlScheme: 'twitter://post',
    presets: [
      SocialPreset('Landscape (16:9)', 1200, 675, 16 / 9),
      SocialPreset('Square (1:1)', 1200, 1200, 1.0),
    ],
    defaultTags: ['#photography', '#streetphotography', '#shotonapertix'],
  ),

  bluesky(
    name: 'Bluesky',
    brandColor: Color(0xFF0085FF),
    gradientColors: [Color(0xFF0085FF), Color(0xFF208BFE)],
    icon: Icons.cloud_outlined,
    maxChars: 300,
    webUrl: 'https://bsky.app/',
    urlScheme: 'bluesky://app',
    presets: [
      SocialPreset('Square (1:1)', 1200, 1200, 1.0),
      SocialPreset('Landscape (16:9)', 1200, 675, 16 / 9),
    ],
    defaultTags: ['#photography', '#nature', '#art', '#sky'],
  ),

  telegram(
    name: 'Telegram',
    brandColor: Color(0xFF229ED9),
    gradientColors: [Color(0xFF229ED9), Color(0xFF2AABEE)],
    icon: Icons.send_rounded,
    maxChars: 1024,
    webUrl: 'https://web.telegram.org/',
    urlScheme: 'tg://msg',
    presets: [
      SocialPreset('Original Resolution', null, null, null),
      SocialPreset('Square (1:1)', 1080, 1080, 1.0),
    ],
    defaultTags: ['#photos', '#apertix'],
  ),

  discord(
    name: 'Discord',
    brandColor: Color(0xFF5865F2),
    gradientColors: [Color(0xFF5865F2), Color(0xFF7983F5)],
    icon: Icons.forum_rounded,
    maxChars: 2000,
    webUrl: 'https://discord.com/channels/@me',
    urlScheme: 'discord://app',
    presets: [
      SocialPreset('Original Resolution', null, null, null),
      SocialPreset('Landscape (16:9)', 1280, 720, 16 / 9),
    ],
    defaultTags: ['#showcase', '#art', '#wallpaper'],
  ),

  pinterest(
    name: 'Pinterest',
    brandColor: Color(0xFFBD081C),
    gradientColors: [Color(0xFFBD081C), Color(0xFFE60023)],
    icon: Icons.push_pin_rounded,
    maxChars: 500,
    webUrl: 'https://pinterest.com/pin-builder/',
    urlScheme: 'pinterest://',
    presets: [
      SocialPreset('Optimal Pin (2:3)', 1000, 1500, 2 / 3),
      SocialPreset('Story (9:16)', 1080, 1920, 9 / 16),
      SocialPreset('Square (1:1)', 1000, 1000, 1.0),
    ],
    defaultTags: ['#inspo', '#aesthetic', '#design', '#photography'],
  ),

  reddit(
    name: 'Reddit',
    brandColor: Color(0xFFFF4500),
    gradientColors: [Color(0xFFFF4500), Color(0xFFFF5700)],
    icon: Icons.bubble_chart_rounded,
    maxChars: 300,
    webUrl: 'https://www.reddit.com/submit',
    urlScheme: 'reddit://',
    presets: [
      SocialPreset('Landscape (16:9)', 1200, 675, 16 / 9),
      SocialPreset('Square (1:1)', 1080, 1080, 1.0),
    ],
    defaultTags: ['[OC]', '#amateurphotography', '#photocritique'],
  ),

  mastodon(
    name: 'Mastodon',
    brandColor: Color(0xFF6364FF),
    gradientColors: [Color(0xFF6364FF), Color(0xFF563ACC)],
    icon: Icons.all_inclusive_rounded,
    maxChars: 500,
    webUrl: 'https://mastodon.social/',
    urlScheme: 'mastodon://',
    presets: [
      SocialPreset('Original Resolution', null, null, null),
      SocialPreset('Landscape (16:9)', 1200, 675, 16 / 9),
    ],
    defaultTags: ['#fediverse', '#photomonday', '#landscape'],
  );

  const SocialPlatform({
    required this.name,
    required this.brandColor,
    required this.gradientColors,
    required this.icon,
    required this.maxChars,
    required this.webUrl,
    required this.urlScheme,
    required this.presets,
    required this.defaultTags,
  });

  final String name;
  final Color brandColor;
  final List<Color> gradientColors;
  final IconData icon;
  final int maxChars;
  final String webUrl;
  final String urlScheme;
  final List<SocialPreset> presets;
  final List<String> defaultTags;
}

/// Draft data model for a social post.
class SocialPostDraft {
  const SocialPostDraft({
    required this.imagePath,
    required this.platform,
    required this.preset,
    this.caption = '',
    this.altText = '',
    this.tags = const [],
    this.discordWebhookUrl,
    this.telegramBotToken,
    this.telegramChatId,
  });

  final String imagePath;
  final SocialPlatform platform;
  final SocialPreset preset;
  final String caption;
  final String altText;
  final List<String> tags;
  final String? discordWebhookUrl;
  final String? telegramBotToken;
  final String? telegramChatId;

  int get remainingChars => platform.maxChars - fullFormattedText.length;
  bool get isOverLimit => remainingChars < 0;

  String get fullFormattedText {
    final sb = StringBuffer(caption);
    if (tags.isNotEmpty) {
      if (sb.isNotEmpty) sb.write('\n\n');
      sb.write(tags.join(' '));
    }
    return sb.toString();
  }

  SocialPostDraft copyWith({
    String? imagePath,
    SocialPlatform? platform,
    SocialPreset? preset,
    String? caption,
    String? altText,
    List<String>? tags,
    String? discordWebhookUrl,
    String? telegramBotToken,
    String? telegramChatId,
  }) {
    return SocialPostDraft(
      imagePath: imagePath ?? this.imagePath,
      platform: platform ?? this.platform,
      preset: preset ?? this.preset,
      caption: caption ?? this.caption,
      altText: altText ?? this.altText,
      tags: tags ?? this.tags,
      discordWebhookUrl: discordWebhookUrl ?? this.discordWebhookUrl,
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      telegramChatId: telegramChatId ?? this.telegramChatId,
    );
  }
}
