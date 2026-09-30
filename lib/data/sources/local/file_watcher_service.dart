import 'dart:async';
import 'dart:io';
import '../../../core/constants/app_constants.dart';

/// Service that watches an open image folder on disk and emits debounced change notifications.
class FileWatcherService {
  StreamSubscription<FileSystemEvent>? _subscription;
  Timer? _debounceTimer;
  final _changeController = StreamController<void>.broadcast();

  Stream<void> get onFolderChanged => _changeController.stream;

  /// Start watching [folderPath].
  void watch(String folderPath) {
    stop();

    final dir = Directory(folderPath);
    if (!dir.existsSync()) return;

    try {
      _subscription = dir.watch(recursive: false).listen((event) {
        if (SupportedFormats.isSupported(event.path)) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 400), () {
            if (!_changeController.isClosed) {
              _changeController.add(null);
            }
          });
        }
      }, onError: (_) {
        stop();
      }, cancelOnError: true);
    } catch (_) {
      // Platform may not support file watching on certain restricted mount points
    }
  }

  /// Stop watching active folder.
  void stop() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stop();
    _changeController.close();
  }
}
