import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/viewer/screens/viewer_screen.dart';
import '../../features/gallery/screens/gallery_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/editor/screens/editor_screen.dart';
import '../../features/comparison/screens/comparison_screen.dart';

/// Provider for optional image file path passed when launching the app.
final initialFilePathProvider = StateProvider<String?>((ref) => null);

/// GoRouter provider — referencing it in ConsumerWidget ensures proper lifecycle.
final appRouterProvider = Provider<GoRouter>((ref) {
  final initialFile = ref.watch(initialFilePathProvider);
  final hasInitialImage = initialFile != null &&
      initialFile.isNotEmpty &&
      File(initialFile).existsSync();

  return GoRouter(
    initialLocation: hasInitialImage ? '/viewer' : '/gallery',
    debugLogDiagnostics: false,
    routes: [
      // Gallery — folder browser & thumbnail grid
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        builder: (context, state) => const GalleryScreen(),
      ),

      // Viewer — full-screen image view
      GoRoute(
        path: '/viewer',
        name: 'viewer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final filePath = extra?['filePath'] as String? ?? (initialFile ?? '');
          final fileList = (extra?['fileList'] as List?)?.cast<String>() ?? [];
          final index = extra?['index'] as int? ?? 0;
          return ViewerScreen(
            filePath: filePath,
            fileList: fileList,
            initialIndex: index,
          );
        },
      ),

      // Editor — full-featured canvas editor
      GoRoute(
        path: '/editor',
        name: 'editor',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final filePath = extra?['filePath'] as String? ?? '';
          return EditorScreen(filePath: filePath);
        },
      ),

      // Comparison Studio — Before/After & Dual Image Analysis
      GoRoute(
        path: '/comparison',
        name: 'comparison',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final imagePathA = extra?['imagePathA'] as String? ?? '';
          final imagePathB = extra?['imagePathB'] as String? ?? '';
          final labelA = extra?['labelA'] as String?;
          final labelB = extra?['labelB'] as String?;
          return ComparisonScreen(
            imagePathA: imagePathA,
            imagePathB: imagePathB,
            labelA: labelA,
            labelB: labelB,
          );
        },
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.error}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
  );
});
