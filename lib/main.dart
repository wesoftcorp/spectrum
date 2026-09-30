import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'app.dart';
import 'core/di/providers.dart';
import 'core/router/app_router.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production global exception handlers
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error\n$stack');
    return true;
  };

  final initialFile = args.isNotEmpty ? args.first : null;
  final hasDirectImage = initialFile != null &&
      initialFile.isNotEmpty &&
      File(initialFile).existsSync();

  // Desktop window setup (Windows, macOS, Linux only)
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    try {
      await windowManager.ensureInitialized();
      final windowOptions = WindowOptions(
        size: const Size(1280, 800),
        minimumSize: const Size(800, 500),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: hasDirectImage ? TitleBarStyle.hidden : TitleBarStyle.normal,
        title: 'Spectrum',
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('Window manager initialization notice: $e');
    }
  }

  // Bootstrap Riverpod container with all providers
  final container = await createProviderContainer();

  // If opened with an image file argument (e.g. from File Explorer), set initial file
  if (hasDirectImage) {
    container.read(initialFilePathProvider.notifier).state = initialFile;
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ApertixApp(),
    ),
  );
}
