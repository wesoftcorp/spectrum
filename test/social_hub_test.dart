import 'package:flutter_test/flutter_test.dart';
import 'package:apertix/features/social/models/social_platform.dart';

void main() {
  group('SocialHub Models & Presets', () {
    test('All 8 platforms are defined with valid presets and char limits', () {
      expect(SocialPlatform.values.length, 8);

      for (final p in SocialPlatform.values) {
        expect(p.name.isNotEmpty, true);
        expect(p.maxChars, greaterThan(0));
        expect(p.presets.isNotEmpty, true);
        expect(p.defaultTags.isNotEmpty, true);
        expect(p.webUrl.startsWith('http'), true);
      }
    });

    test('Instagram presets include 4:5 portrait, 1:1 square, and 9:16 story', () {
      const ig = SocialPlatform.instagram;
      expect(ig.presets.any((p) => p.name.contains('4:5')), true);
      expect(ig.presets.any((p) => p.name.contains('1:1')), true);
      expect(ig.presets.any((p) => p.name.contains('9:16')), true);
    });

    test('Draft full text joins caption and hashtags', () {
      final draft = SocialPostDraft(
        imagePath: '/test/photo.jpg',
        platform: SocialPlatform.xTwitter,
        preset: SocialPlatform.xTwitter.presets.first,
        caption: 'Beautiful sunset in the mountains',
        tags: ['#sunset', '#mountains'],
      );

      expect(
        draft.fullFormattedText,
        'Beautiful sunset in the mountains\n\n#sunset #mountains',
      );
      expect(draft.remainingChars, SocialPlatform.xTwitter.maxChars - draft.fullFormattedText.length);
      expect(draft.isOverLimit, false);
    });

    test('Draft flags character limit overflow correctly', () {
      final longCaption = 'A' * 300;
      final draft = SocialPostDraft(
        imagePath: '/test/photo.jpg',
        platform: SocialPlatform.xTwitter, // 280 char limit
        preset: SocialPlatform.xTwitter.presets.first,
        caption: longCaption,
      );

      expect(draft.isOverLimit, true);
      expect(draft.remainingChars, lessThan(0));
    });
  });
}
