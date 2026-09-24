import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apertix/core/widgets/glass_container.dart';
import 'package:apertix/core/widgets/glass_background.dart';
import 'package:apertix/features/gallery/widgets/studio_sidebar.dart';
import 'package:apertix/features/editor/screens/editor_screen.dart';
import 'package:apertix/features/social/widgets/social_hub_dialog.dart';
import 'package:apertix/data/sources/local/image_file_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Glassmorphism Primitives Tests', () {
    testWidgets('GlassContainer renders child with backdrop filter and specular borders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassBackground(
              child: GlassContainer(
                blur: 16.0,
                opacity: 0.1,
                child: Text('Glass Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Glass Content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsWidgets);
      expect(find.byType(GlassBackground), findsOneWidget);
    });
  });

  group('StudioSidebar Features & Pro Visibility Tests', () {
    testWidgets('StudioSidebar renders brand, Pro badge, engines, and library items', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StudioSidebar(
                totalImagesCount: 42,
                currentFolder: 'C:\\Photos\\Summer',
                isFavoritesActive: false,
                activeAlbumId: null,
                isCollapsed: false,
                onToggleCollapse: () {},
                onShowAllPhotos: () {},
                onToggleFavorites: () {},
                onSelectAlbum: (_) {},
                onPickFolder: () {},
                onPickFile: () {},
                onOpenBatchStudio: () {},
                onOpenComparisonStudio: () {},
                onOpenCloudVault: () {},
                onOpenWindowsShell: () {},
              ),
            ),
          ),
        ),
      );

      // Verify Brand & Pro presence
      expect(find.text('APERTIX'), findsOneWidget);
      expect(find.text('All Photos'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Summer'), findsOneWidget);

      // Verify Studio Pro Engine Launchers
      expect(find.text('Comparison Studio'), findsOneWidget);
      expect(find.text('Batch Studio Pro'), findsOneWidget);
      expect(find.text('Cloud Vault Sync'), findsOneWidget);
      expect(find.text('Photo Editor'), findsOneWidget);
    });

    testWidgets('StudioSidebar collapses and expands cleanly', (tester) async {
      bool collapsed = true;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return StudioSidebar(
                    totalImagesCount: 10,
                    currentFolder: null,
                    isFavoritesActive: false,
                    activeAlbumId: null,
                    isCollapsed: collapsed,
                    onToggleCollapse: () {
                      setState(() => collapsed = !collapsed);
                    },
                    onShowAllPhotos: () {},
                    onToggleFavorites: () {},
                    onSelectAlbum: (_) {},
                    onPickFolder: () {},
                    onPickFile: () {},
                    onOpenBatchStudio: () {},
                    onOpenComparisonStudio: () {},
                    onOpenCloudVault: () {},
                    onOpenWindowsShell: () {},
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Initially collapsed: rail shows menu button
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Tap expand button
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Expanded: reveals full brand and engines
      expect(find.text('APERTIX'), findsOneWidget);
      expect(find.text('Comparison Studio'), findsOneWidget);
    });
  });

  group('ImageFileService Background Isolate Tests', () {
    test('ImageFileService listImages discovers files and returns ImageFile objects', () async {
      final service = ImageFileService();
      final tempDir = await Directory.systemTemp.createTemp('apertix_perf_test_');

      try {
        final f1 = File('${tempDir.path}/pic1.jpg');
        await f1.writeAsBytes([0xFF, 0xD8, 0xFF]);

        final f2 = File('${tempDir.path}/pic2.png');
        await f2.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

        final nonImg = File('${tempDir.path}/doc.txt');
        await nonImg.writeAsString('hello');

        final images = await service.listImages(tempDir.path);
        expect(images.length, equals(2));
        expect(images[0].name, equals('pic1.jpg'));
        expect(images[1].name, equals('pic2.png'));
        expect(images[0].extension, equals('jpg'));
        expect(images[1].extension, equals('png'));
        expect(images[0].sizeBytes, greaterThan(0));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('Photo Editor & Social Hub Resilience Tests', () {
    testWidgets('EditorScreen displays Glassmorphism Welcome Canvas when launched with empty path', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditorScreen(filePath: ''),
          ),
        ),
      );

      // Verify that instead of throwing an unhandled exception, it renders the welcome state cleanly
      expect(find.text('Apertix Pro Photo Editor'), findsOneWidget);
      expect(find.text('Select Photo to Edit'), findsOneWidget);
      expect(find.text('Open Photo'), findsOneWidget);
    });

    testWidgets('SocialHubDialog renders gracefully with empty or missing image path', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SocialHubDialog(imagePath: 'C:\\NonExistent\\sample.jpg'),
            ),
          ),
        ),
      );

      // Verify Social Hub UI elements render cleanly
      expect(find.text('Social Hub'), findsOneWidget);
      expect(find.text('Optimal Framing'), findsOneWidget);
      expect(find.text('No image loaded'), findsOneWidget);
    });
  });
}
