import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apertix/features/viewer/widgets/picasa_dock.dart';
import 'package:apertix/features/viewer/widgets/picasa_loupe_map.dart';
import 'package:apertix/features/viewer/widgets/thumbnail_strip.dart';
import 'package:apertix/features/viewer/providers/viewer_provider.dart';

void main() {
  group('Google Picasa Borderless Viewer UI Tests', () {
    testWidgets('PicasaDock renders navigation, zoom, star, slideshow, and actions',
        (tester) async {
      bool prevTapped = false;
      bool nextTapped = false;
      bool zoomResetTapped = false;
      bool starTapped = false;
      bool slideshowTapped = false;
      bool rotateLeftTapped = false;
      bool rotateRightTapped = false;
      bool zoomInTapped = false;
      bool zoomOutTapped = false;
      bool filmstripTapped = false;
      bool editorTapped = false;
      bool metadataTapped = false;
      bool socialHubTapped = false;
      bool deleteTapped = false;
      bool fullscreenTapped = false;
      bool closeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: PicasaDock(
                currentIndex: 2,
                totalCount: 10,
                zoomLevel: 1.0,
                onZoomChanged: (_) {},
                onZoomIn: () => zoomInTapped = true,
                onZoomOut: () => zoomOutTapped = true,
                onResetZoom: () => zoomResetTapped = true,
                onNavigatePrev: () => prevTapped = true,
                onNavigateNext: () => nextTapped = true,
                onRotateLeft: () => rotateLeftTapped = true,
                onRotateRight: () => rotateRightTapped = true,
                onToggleSlideshow: () => slideshowTapped = true,
                isPlayingSlideshow: false,
                onToggleFilmstrip: () => filmstripTapped = true,
                isFilmstripVisible: false,
                isFavorite: false,
                onToggleFavorite: () => starTapped = true,
                onOpenEditor: () => editorTapped = true,
                onOpenMetadata: () => metadataTapped = true,
                onOpenSocialHub: () => socialHubTapped = true,
                onDelete: () => deleteTapped = true,
                onToggleFullscreen: () => fullscreenTapped = true,
                isFullscreen: false,
                onClose: () => closeTapped = true,
              ),
            ),
          ),
        ),
      );

      // Verify Previous button
      final prevBtn = find.byTooltip('Previous Image (← or A)');
      expect(prevBtn, findsOneWidget);
      await tester.tap(prevBtn);
      expect(prevTapped, isTrue);

      // Verify Next button
      final nextBtn = find.byTooltip('Next Image (→ or D)');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      expect(nextTapped, isTrue);

      // Verify 1:1 / Fit button
      expect(find.text('1:1'), findsOneWidget);
      await tester.tap(find.text('1:1'));
      expect(zoomResetTapped, isTrue);

      // Verify Zoom in / out
      final zoomInBtn = find.byTooltip('Zoom In (+ / Wheel Up)');
      expect(zoomInBtn, findsOneWidget);
      await tester.tap(zoomInBtn);
      expect(zoomInTapped, isTrue);

      final zoomOutBtn = find.byTooltip('Zoom Out (- / Wheel Down)');
      expect(zoomOutBtn, findsOneWidget);
      await tester.tap(zoomOutBtn);
      expect(zoomOutTapped, isTrue);

      // Verify Zoom percentage tag
      expect(find.text('100%'), findsOneWidget);

      // Verify Rotation buttons
      final rotLeftBtn = find.byTooltip('Rotate Left 90° (L or [)');
      expect(rotLeftBtn, findsOneWidget);
      await tester.tap(rotLeftBtn);
      expect(rotateLeftTapped, isTrue);

      final rotRightBtn = find.byTooltip('Rotate Right 90° (R or ])');
      expect(rotRightBtn, findsOneWidget);
      await tester.tap(rotRightBtn);
      expect(rotateRightTapped, isTrue);

      // Verify Picasa Star button
      final starBtn = find.byTooltip('Add Favorite (F)');
      expect(starBtn, findsOneWidget);
      await tester.tap(starBtn);
      expect(starTapped, isTrue);

      // Verify Slideshow button
      final slideBtn = find.byTooltip('Play Slideshow (Space)');
      expect(slideBtn, findsOneWidget);
      await tester.tap(slideBtn);
      expect(slideshowTapped, isTrue);

      // Verify Filmstrip button
      final filmBtn = find.byTooltip('Filmstrip Carousel (T)');
      expect(filmBtn, findsOneWidget);
      await tester.tap(filmBtn);
      expect(filmstripTapped, isTrue);

      // Verify Editor button
      final editBtn = find.byTooltip('Open in Editor (E)');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      expect(editorTapped, isTrue);

      // Verify Metadata button
      final metaBtn = find.byTooltip('Image EXIF Info (I)');
      expect(metaBtn, findsOneWidget);
      await tester.tap(metaBtn);
      expect(metadataTapped, isTrue);

      // Verify Social Hub button
      final socialBtn = find.byTooltip('Social Hub (S)');
      expect(socialBtn, findsOneWidget);
      await tester.tap(socialBtn);
      expect(socialHubTapped, isTrue);

      // Verify Delete button
      final delBtn = find.byTooltip('Delete Photo (Delete)');
      expect(delBtn, findsOneWidget);
      await tester.tap(delBtn);
      expect(deleteTapped, isTrue);

      // Verify Fullscreen button
      final fsBtn = find.byTooltip('Fullscreen (F11)');
      expect(fsBtn, findsOneWidget);
      await tester.tap(fsBtn);
      expect(fullscreenTapped, isTrue);

      // Verify Close button
      final closeBtn = find.byTooltip('Close (Esc)');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      expect(closeTapped, isTrue);
    });

    testWidgets('PicasaDock displays active star and FIT label when zoomed in',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: PicasaDock(
                currentIndex: 0,
                totalCount: 5,
                zoomLevel: 2.5,
                onZoomChanged: (_) {},
                onZoomIn: () {},
                onZoomOut: () {},
                onResetZoom: () {},
                onNavigatePrev: () {},
                onNavigateNext: () {},
                onRotateLeft: () {},
                onRotateRight: () {},
                onToggleSlideshow: () {},
                isPlayingSlideshow: true,
                onToggleFilmstrip: () {},
                isFilmstripVisible: true,
                isFavorite: true,
                onToggleFavorite: () {},
                onOpenEditor: () {},
                onOpenMetadata: () {},
                onToggleFullscreen: () {},
                isFullscreen: false,
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      // FIT should be shown when zoomed in
      expect(find.text('FIT'), findsOneWidget);
      // Zoom % should show 250%
      expect(find.text('250%'), findsOneWidget);
      // Star should show active remove tooltip
      expect(find.byTooltip('Remove Favorite (F)'), findsOneWidget);
      // Slideshow button should show pause tooltip
      expect(find.byTooltip('Pause Slideshow (Space)'), findsOneWidget);
    });

    testWidgets('PicasaLoupeMap renders zoom overview badge and FIT action',
        (tester) async {
      bool resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PicasaLoupeMap(
              imagePath: 'test_path.jpg',
              scale: 2.0,
              quarterTurns: 0,
              onResetZoom: () => resetCalled = true,
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('NAVIGATOR 200%'), findsOneWidget);
      expect(find.text('FIT'), findsOneWidget);
      await tester.tap(find.text('FIT'));
      expect(resetCalled, isTrue);
    });

    testWidgets('ThumbnailStrip renders list items with correct count',
        (tester) async {
      final paths = ['/a.jpg', '/b.jpg', '/c.jpg'];
      int selectedIdx = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThumbnailStrip(
              paths: paths,
              currentIndex: 1,
              onTap: (idx) => selectedIdx = idx,
            ),
          ),
        ),
      );

      expect(find.byType(ThumbnailStrip), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(selectedIdx, -1);
    });

    test('ViewerNotifier handles loop wrap navigation and file removal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(viewerProvider.notifier);
      notifier.init(
        filePaths: ['/img1.jpg', '/img2.jpg', '/img3.jpg'],
        initialIndex: 0,
      );

      // Test Prev wrapping from 0 to 2
      final prevIndex = notifier.navigate(-1, loop: true);
      expect(prevIndex, 2);

      // Test Next wrapping from 2 to 0
      final nextIndex = notifier.navigate(1, loop: true);
      expect(nextIndex, 0);

      // Test removePath
      final afterDelete = notifier.removePath('/img1.jpg');
      expect(afterDelete, 0);
      expect(container.read(viewerProvider).valueOrNull?.filePaths.length, 2);
    });
  });
}
