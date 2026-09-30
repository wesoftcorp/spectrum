import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/viewer_provider.dart';
import '../widgets/picasa_dock.dart';
import '../widgets/thumbnail_strip.dart';
import '../widgets/animation_controls_bar.dart';
import '../widgets/picasa_loupe_map.dart';
import '../../metadata/widgets/metadata_drawer.dart';
import '../../metadata/providers/metadata_provider.dart';
import '../../social/widgets/social_hub_dialog.dart';
import '../../analysis/widgets/histogram_overlay.dart';
import '../../collections/providers/collections_provider.dart';
import '../../cloud/widgets/cloud_vault_dialog.dart';

/// Iconic Google Picasa-style borderless photo viewer player.
/// Features a deep vignette frameless canvas, draggable backdrop,
/// silky mouse wheel zooming, floating capsule dock, Loupe navigator,
/// filmstrip preview, full right-click context menu, and auto-hiding HUD.
class ViewerScreen extends ConsumerStatefulWidget {
  const ViewerScreen({
    super.key,
    required this.filePath,
    required this.fileList,
    required this.initialIndex,
  });

  final String filePath;
  final List<String> fileList;
  final int initialIndex;

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _pageController;
  late PhotoViewController _photoViewController;
  StreamSubscription<PhotoViewControllerValue>? _photoViewSubscription;
  late final FocusNode _focusNode;

  // Inactivity auto-fade
  Timer? _inactivityTimer;
  bool _showUi = true;
  bool _isHoveringControls = false;

  // Window & UI state
  bool _isFullscreen = false;
  bool _showFilmstrip = false;
  bool _isPlayingSlideshow = false;
  bool _showHistogram = false;
  Timer? _slideshowTimer;

  // Animated Media state (GIF / APNG)
  bool _isAnimationPlaying = true;
  double _animationSpeed = 1.0;

  bool _isAnimatedMedia(String? path) {
    if (path == null) return false;
    final ext = p.extension(path).toLowerCase();
    return ext == '.gif' || ext == '.apng';
  }

  // Transformations (filePath -> quarter turns 0, 1, 2, 3)
  final Map<String, int> _rotations = {};
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _pageController = PageController(initialPage: widget.initialIndex);
    _photoViewController = PhotoViewController();
    _photoViewSubscription = _photoViewController.outputStateStream.listen((state) {
      if (state.scale != null && mounted) {
        setState(() => _currentScale = state.scale!);
      }
    });

    // Make window borderless for authentic Google Picasa experience on desktop
    _enableBorderlessWindow();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      List<String> files = List<String>.from(widget.fileList);
      int index = widget.initialIndex;

      // Auto-discover sibling photos if opened directly with a single file
      if (files.isEmpty && widget.filePath.isNotEmpty) {
        final file = File(widget.filePath);
        if (file.existsSync()) {
          try {
            final parentDir = file.parent.path;
            final images =
                await ref.read(imageFileServiceProvider).listImages(parentDir);
            files = images.map((f) => f.path).toList();
            index = files.indexOf(widget.filePath);
            if (index == -1) {
              files.insert(0, widget.filePath);
              index = 0;
            }
          } catch (_) {
            files = [widget.filePath];
            index = 0;
          }
        } else {
          files = [widget.filePath];
          index = 0;
        }
      }

      ref.read(viewerProvider.notifier).init(
            filePaths: files,
            initialIndex: index,
          );
      _resetInactivityTimer();
    });
  }

  Future<void> _enableBorderlessWindow() async {
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: false,
        );
      }
    } catch (_) {}
  }

  Future<void> _restoreStandardWindow() async {
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _slideshowTimer?.cancel();
    _photoViewSubscription?.cancel();
    _focusNode.dispose();
    _pageController.dispose();
    _photoViewController.dispose();
    _restoreStandardWindow();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!_showUi) {
      setState(() => _showUi = true);
    }
    if (!_isHoveringControls && !_isPlayingSlideshow) {
      _inactivityTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isHoveringControls) {
          setState(() => _showUi = false);
        }
      });
    }
  }

  void _navigate(int delta) {
    _resetInactivityTimer();
    final notifier = ref.read(viewerProvider.notifier);
    final prevIndex = ref.read(viewerProvider).valueOrNull?.currentIndex ?? 0;
    final total = ref.read(viewerProvider).valueOrNull?.filePaths.length ?? 0;
    final newIndex = notifier.navigate(delta);
    if (newIndex != null) {
      if (_pageController.hasClients) {
        if ((prevIndex == 0 && newIndex == total - 1) ||
            (prevIndex == total - 1 && newIndex == 0)) {
          _pageController.jumpToPage(newIndex);
        } else {
          _pageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      }
      _resetZoomToFit();
    }
  }

  void _rotate(int quarterTurnsDelta) {
    _resetInactivityTimer();
    final currentPath = ref.read(viewerProvider).valueOrNull?.currentPath;
    if (currentPath == null) return;
    setState(() {
      final current = _rotations[currentPath] ?? 0;
      _rotations[currentPath] = (current + quarterTurnsDelta) % 4;
    });
  }

  void _zoomIn() {
    _resetInactivityTimer();
    final newScale = (_currentScale * 1.2).clamp(0.5, 4.0);
    _photoViewController.scale = newScale;
    setState(() => _currentScale = newScale);
  }

  void _zoomOut() {
    _resetInactivityTimer();
    final newScale = (_currentScale / 1.2).clamp(0.5, 4.0);
    _photoViewController.scale = newScale;
    setState(() => _currentScale = newScale);
  }

  void _setZoom(double scale) {
    _resetInactivityTimer();
    final target = scale.clamp(0.5, 4.0);
    _photoViewController.scale = target;
    setState(() => _currentScale = target);
  }

  void _resetZoomToFit() {
    _resetInactivityTimer();
    try {
      _photoViewController.reset();
    } catch (_) {
      _photoViewController.scale = 1.0;
    }
    setState(() => _currentScale = 1.0);
  }

  void _toggleZoomActualOrFit() {
    _resetInactivityTimer();
    if (_currentScale > 1.05) {
      _resetZoomToFit();
    } else {
      _setZoom(2.5); // 1:1 actual pixels
    }
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    _resetInactivityTimer();
    final dy = event.scrollDelta.dy;
    if (dy < 0) {
      _zoomIn();
    } else if (dy > 0) {
      _zoomOut();
    }
  }

  void _toggleSlideshow() {
    _resetInactivityTimer();
    setState(() {
      _isPlayingSlideshow = !_isPlayingSlideshow;
    });

    _slideshowTimer?.cancel();
    if (_isPlayingSlideshow) {
      _slideshowTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        final state = ref.read(viewerProvider).valueOrNull;
        if (state != null && state.filePaths.length > 1) {
          _navigate(1);
        }
      });
    }
  }

  Future<void> _toggleFullscreen() async {
    _resetInactivityTimer();
    setState(() => _isFullscreen = !_isFullscreen);
    try {
      final isFs = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!isFs);
    } catch (_) {}
  }

  void _openSocialHub(String? currentPath) {
    if (currentPath == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => SocialHubDialog(imagePath: currentPath),
    );
  }

  Future<void> _revealInExplorer(String filePath) async {
    try {
      if (!File(filePath).existsSync() && !Directory(filePath).existsSync()) return;
      if (Platform.isWindows) {
        // Windows Explorer expects /select,"path" without a space after comma
        await Process.run('explorer.exe', ['/select,$filePath']);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [p.dirname(filePath)]);
      }
    } catch (_) {}
  }

  Future<void> _copyPathToClipboard(String filePath) async {
    await Clipboard.setData(ClipboardData(text: filePath));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File path copied to clipboard'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmAndDeleteCurrentPhoto(String? currentPath) async {
    if (currentPath == null) return;
    final file = File(currentPath);
    if (!file.existsSync()) return;
    if (FileSystemEntity.typeSync(currentPath) != FileSystemEntityType.file) return;
    if (!SupportedFormats.isSupported(currentPath)) return;

    final fileName = p.basename(currentPath);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E212B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 30),
        ),
        title: const Text(
          'Delete Photo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to permanently delete "$fileName" from your computer?\nThis action cannot be undone.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
            fontSize: 13.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        if (file.existsSync()) {
          await file.delete();
        }
        _rotations.remove(currentPath);
        if (!mounted) return;
        final nextIndex = ref.read(viewerProvider.notifier).removePath(currentPath);
        if (nextIndex == null) {
          _exitViewer();
        } else {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(nextIndex);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted $fileName'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showContextMenu(TapDownDetails details, String? currentPath, bool isDark) async {
    if (currentPath == null) return;
    final favorites = ref.read(favoritesProvider);
    final isFav = favorites.contains(currentPath);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & MediaQuery.of(context).size,
      ),
      color: isDark ? const Color(0xF0181A24) : Colors.white,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black12,
        ),
      ),
      items: [
        _buildContextMenuItem('fit', 'Fit to Screen', Icons.fit_screen_rounded, '0', isDark),
        _buildContextMenuItem('actual', 'Actual Size (100%)', Icons.zoom_in_rounded, '1', isDark),
        const PopupMenuDivider(height: 8),
        _buildContextMenuItem('rotate_cw', 'Rotate Clockwise 90°', Icons.rotate_right_rounded, 'R', isDark),
        _buildContextMenuItem('rotate_ccw', 'Rotate Counter-Clockwise 90°', Icons.rotate_left_rounded, 'L', isDark),
        const PopupMenuDivider(height: 8),
        _buildContextMenuItem(
          'favorite',
          isFav ? 'Remove from Favorites' : 'Add to Favorites',
          isFav ? Icons.star_rounded : Icons.star_outline_rounded,
          'F',
          isDark,
          highlightColor: isFav ? const Color(0xFFFFC107) : null,
        ),
        _buildContextMenuItem(
          'slideshow',
          _isPlayingSlideshow ? 'Pause Slideshow' : 'Play Slideshow',
          _isPlayingSlideshow ? Icons.pause_rounded : Icons.play_arrow_rounded,
          'Space',
          isDark,
        ),
        _buildContextMenuItem(
          'filmstrip',
          _showFilmstrip ? 'Hide Filmstrip' : 'Show Filmstrip',
          Icons.view_carousel_rounded,
          'T',
          isDark,
        ),
        const PopupMenuDivider(height: 8),
        _buildContextMenuItem('editor', 'Edit in Spectrum Studio', Icons.tune_rounded, 'E', isDark),
        _buildContextMenuItem('exif', 'Image Information (EXIF)', Icons.info_outline_rounded, 'I', isDark),
        const PopupMenuDivider(height: 8),
        _buildContextMenuItem('copy_path', 'Copy File Path', Icons.copy_rounded, 'Ctrl+C', isDark),
        _buildContextMenuItem('reveal', 'Show in File Explorer', Icons.folder_open_rounded, null, isDark),
        const PopupMenuDivider(height: 8),
        _buildContextMenuItem(
          'delete',
          'Delete Photo',
          Icons.delete_outline_rounded,
          'Del',
          isDark,
          highlightColor: Colors.redAccent,
        ),
      ],
    );

    if (!mounted || selected == null) return;

    switch (selected) {
      case 'fit':
        _resetZoomToFit();
      case 'actual':
        _setZoom(2.5);
      case 'rotate_cw':
        _rotate(1);
      case 'rotate_ccw':
        _rotate(-1);
      case 'favorite':
        ref.read(favoritesProvider.notifier).toggle(currentPath);
      case 'slideshow':
        _toggleSlideshow();
      case 'filmstrip':
        setState(() => _showFilmstrip = !_showFilmstrip);
      case 'editor':
        context.push('/editor', extra: {'filePath': currentPath});
      case 'exif':
        _scaffoldKey.currentState?.openEndDrawer();
      case 'copy_path':
        _copyPathToClipboard(currentPath);
      case 'reveal':
        _revealInExplorer(currentPath);
      case 'delete':
        _confirmAndDeleteCurrentPhoto(currentPath);
    }
  }

  PopupMenuItem<String> _buildContextMenuItem(
    String value,
    String label,
    IconData icon,
    String? shortcut,
    bool isDark, {
    Color? highlightColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: highlightColor ?? (isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: highlightColor ??
                    (isDark ? ApertixColors.darkTextPrimary : ApertixColors.lightTextPrimary),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (shortcut != null)
            Text(
              shortcut,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  void _exitViewer() {
    _restoreStandardWindow();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/gallery');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(viewerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KeyboardListener(
      focusNode: _focusNode..requestFocus(),
      onKeyEvent: _handleKey,
      child: MouseRegion(
        onHover: (_) => _resetInactivityTimer(),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          endDrawer: state.valueOrNull?.currentPath != null
              ? MetadataDrawer(filePath: state.valueOrNull!.currentPath!)
              : null,
          body: state.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: ApertixColors.cyanAccent),
            ),
            error: (err, _) => Center(
              child: Text(err.toString(), style: const TextStyle(color: Colors.white)),
            ),
            data: (viewerState) {
              if (viewerState.filePaths.isEmpty) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.3,
                          colors: isDark
                              ? const [
                                  Color(0xEE161822),
                                  Color(0xFA0C0D12),
                                  Color(0xFF030406),
                                ]
                              : const [
                                  Color(0xEEF3F5FA),
                                  Color(0xFADDE1EC),
                                  Color(0xFFC8CEDD),
                                ],
                          stops: const [0.0, 0.65, 1.0],
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          const Text(
                            'No images in playlist',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select an image to view, or return to the gallery.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: ApertixColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: const Text('Return to Gallery'),
                            onPressed: _exitViewer,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final currentIndex = viewerState.currentIndex;
              final currentPath = viewerState.currentPath;
              final fileName = currentPath != null ? p.basename(currentPath) : '';
              final isFav = currentPath != null &&
                  ref.watch(favoritesProvider).contains(currentPath);
              final isZoomed = _currentScale > 1.05;

              return Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    _handlePointerScroll(pointerSignal);
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Picasa Frosted Radial Vignette Background
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.3,
                          colors: isDark
                              ? const [
                                  Color(0xEE161822),
                                  Color(0xFA0C0D12),
                                  Color(0xFF030406),
                                ]
                              : const [
                                  Color(0xEEF3F5FA),
                                  Color(0xFADDE1EC),
                                  Color(0xFFC8CEDD),
                                ],
                          stops: const [0.0, 0.65, 1.0],
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: const SizedBox.expand(),
                      ),
                    ),

                    // Draggable Window Backdrop Area (when image is fit or click is outside)
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (details) async {
                        if (!isZoomed) {
                          try {
                            await windowManager.startDragging();
                          } catch (_) {}
                        }
                      },
                      onDoubleTap: () async {
                        try {
                          final isMax = await windowManager.isMaximized();
                          if (isMax) {
                            await windowManager.unmaximize();
                          } else {
                            await windowManager.maximize();
                          }
                        } catch (_) {}
                      },
                      child: const SizedBox.expand(),
                    ),

                    // Main Photo View Gallery
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onSecondaryTapDown: (details) =>
                          _showContextMenu(details, currentPath, isDark),
                      onDoubleTap: _toggleZoomActualOrFit,
                      onTap: () {
                        setState(() => _showUi = !_showUi);
                      },
                      child: PhotoViewGallery.builder(
                        pageController: _pageController,
                        itemCount: viewerState.filePaths.length,
                        onPageChanged: (index) {
                          ref.read(viewerProvider.notifier).setIndex(index);
                          _resetZoomToFit();
                        },
                        builder: (context, index) {
                          final path = viewerState.filePaths[index];
                          final rot = _rotations[path] ?? 0;

                          return PhotoViewGalleryPageOptions.customChild(
                            child: RotatedBox(
                              quarterTurns: rot,
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Image.file(
                                  File(path),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 72,
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            controller:
                                index == currentIndex ? _photoViewController : null,
                            minScale: PhotoViewComputedScale.contained * 0.75,
                            maxScale: PhotoViewComputedScale.covered * AppConstants.maxZoom,
                            initialScale: PhotoViewComputedScale.contained,
                            heroAttributes: PhotoViewHeroAttributes(tag: path),
                          );
                        },
                        backgroundDecoration:
                            const BoxDecoration(color: Colors.transparent),
                      ),
                    ),

                    // Top Borderless Bar with Drag Area & Window Controls
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      top: _showUi ? 0 : -64,
                      left: 0,
                      right: 0,
                      child: _buildTopBorderlessBar(
                        fileName,
                        currentIndex + 1,
                        viewerState.filePaths.length,
                        viewerState,
                        currentPath,
                        isDark,
                      ),
                    ),

                    // Floating Histogram HUD
                    if (_showHistogram && currentPath != null)
                      Positioned(
                        top: 56,
                        right: 16,
                        child: HistogramOverlay(
                          filePath: currentPath,
                          onClose: () => setState(() => _showHistogram = false),
                        ),
                      ),

                    // Loupe Mini-Map (Google Picasa Viewport Navigator when zoomed)
                    if (isZoomed && currentPath != null)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        right: 20,
                        bottom: _showUi ? (_showFilmstrip ? 175 : 95) : 24,
                        child: PicasaLoupeMap(
                          imagePath: currentPath,
                          scale: _currentScale,
                          quarterTurns: _rotations[currentPath] ?? 0,
                          onResetZoom: _resetZoomToFit,
                          onClose: () => _resetZoomToFit(),
                        ),
                      ),

                    // Bottom Filmstrip Carousel (Picasa style, togglable)
                    if (_showFilmstrip && viewerState.filePaths.length > 1)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        bottom: _showUi ? 86 : -100,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 820),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xCC13151D)
                                        : Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : Colors.black.withValues(alpha: 0.08),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: ThumbnailStrip(
                                    paths: viewerState.filePaths,
                                    currentIndex: currentIndex,
                                    onTap: (index) {
                                      ref
                                          .read(viewerProvider.notifier)
                                          .setIndex(index);
                                      if (_pageController.hasClients) {
                                        _pageController.animateToPage(
                                          index,
                                          duration: const Duration(milliseconds: 220),
                                          curve: Curves.easeOutCubic,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Animated Media Floating Controls (GIF / APNG)
                    if (_isAnimatedMedia(currentPath))
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        bottom: _showUi ? (_showFilmstrip ? 172 : 88) : -80,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: AnimationControlsBar(
                            isPlaying: _isAnimationPlaying,
                            playbackSpeed: _animationSpeed,
                            onTogglePlayPause: () => setState(
                                () => _isAnimationPlaying = !_isAnimationPlaying),
                            onSpeedChanged: (spd) =>
                                setState(() => _animationSpeed = spd),
                          ),
                        ),
                      ),

                    // Iconic Google Picasa Floating Bottom Control Dock
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      bottom: _showUi ? 22 : -85,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: MouseRegion(
                          onEnter: (_) =>
                              setState(() => _isHoveringControls = true),
                          onExit: (_) =>
                              setState(() => _isHoveringControls = false),
                          child: PicasaDock(
                            currentIndex: currentIndex,
                            totalCount: viewerState.filePaths.length,
                            zoomLevel: _currentScale,
                            onZoomChanged: _setZoom,
                            onZoomIn: _zoomIn,
                            onZoomOut: _zoomOut,
                            onResetZoom: _toggleZoomActualOrFit,
                            onNavigatePrev: () => _navigate(-1),
                            onNavigateNext: () => _navigate(1),
                            onRotateLeft: () => _rotate(-1),
                            onRotateRight: () => _rotate(1),
                            onToggleSlideshow: _toggleSlideshow,
                            isPlayingSlideshow: _isPlayingSlideshow,
                            onToggleFilmstrip: () => setState(
                                () => _showFilmstrip = !_showFilmstrip),
                            isFilmstripVisible: _showFilmstrip,
                            isFavorite: isFav,
                            onToggleFavorite: currentPath != null
                                ? () => ref
                                    .read(favoritesProvider.notifier)
                                    .toggle(currentPath)
                                : null,
                            onDelete: currentPath != null
                                ? () => _confirmAndDeleteCurrentPhoto(currentPath)
                                : null,
                            onOpenEditor: () {
                              if (currentPath != null) {
                                context.push('/editor',
                                    extra: {'filePath': currentPath});
                              }
                            },
                            onOpenMetadata: () =>
                                _scaffoldKey.currentState?.openEndDrawer(),
                            onOpenSocialHub: currentPath != null
                                ? () => _openSocialHub(currentPath)
                                : null,
                            onToggleFullscreen: _toggleFullscreen,
                            isFullscreen: _isFullscreen,
                            onClose: _exitViewer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBorderlessBar(
    String fileName,
    int current,
    int total,
    ViewerState viewerState,
    String? currentPath,
    bool isDark,
  ) {
    final metaAsync =
        currentPath != null ? ref.watch(imageMetadataProvider(currentPath)) : null;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.82),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back to Gallery / Library button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            tooltip: 'Return to Gallery (Esc)',
            onPressed: _exitViewer,
          ),
          const SizedBox(width: 6),

          // File Title & Counter
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              if (total > 0)
                Text(
                  '$current of $total',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),

          // Metadata Badges (Dimensions & File Size)
          if (metaAsync != null)
            metaAsync.maybeWhen(
              data: (meta) => Row(
                children: [
                  const SizedBox(width: 14),
                  if (meta.dimensions != null)
                    _buildPillBadge(meta.dimensions!, Icons.aspect_ratio_rounded),
                  const SizedBox(width: 6),
                  _buildPillBadge(meta.formattedFileSize, Icons.storage_rounded),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),

          // Draggable window area in the center (Double-click to toggle maximize)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) async {
                try {
                  await windowManager.startDragging();
                } catch (_) {}
              },
              onDoubleTap: _toggleFullscreen,
              child: const SizedBox.expand(),
            ),
          ),

          // Comparison Studio Launcher
          if (total >= 2)
            IconButton(
              icon: const Icon(Icons.compare_rounded, color: ApertixColors.cyanAccent, size: 18),
              tooltip: 'Compare with Neighbor (C)',
              onPressed: () {
                final paths = viewerState.filePaths;
                final prevIndex =
                    (viewerState.currentIndex - 1 + paths.length) % paths.length;
                context.push('/comparison', extra: {
                  'imagePathA': paths[prevIndex],
                  'imagePathB': paths[viewerState.currentIndex],
                  'labelA': 'Previous Photo',
                  'labelB': 'Current Photo',
                });
              },
            ),

          // Histogram HUD Toggle
          IconButton(
            icon: Icon(
              Icons.bar_chart_rounded,
              color: _showHistogram ? ApertixColors.cyanAccent : Colors.white70,
              size: 18,
            ),
            tooltip: 'Histogram HUD (H)',
            onPressed: () => setState(() => _showHistogram = !_showHistogram),
          ),

          // Cloud Vault Backup
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: ApertixColors.cyanAccent, size: 18),
            tooltip: 'Backup to Cloud Vault',
            onPressed: () {
              if (viewerState.currentPath != null) {
                showDialog(
                  context: context,
                  builder: (_) =>
                      CloudVaultDialog(filePaths: [viewerState.currentPath!]),
                );
              }
            },
          ),

          const SizedBox(width: 8),

          // Picasa-style Window Management controls (Minimize, Maximize, Close)
          _PicasaWindowButton(
            icon: Icons.remove_rounded,
            tooltip: 'Minimize',
            onTap: () async {
              try {
                await windowManager.minimize();
              } catch (_) {}
            },
          ),
          _PicasaWindowButton(
            icon: _isFullscreen
                ? Icons.crop_square_rounded
                : Icons.square_outlined,
            tooltip: _isFullscreen ? 'Restore' : 'Maximize',
            onTap: _toggleFullscreen,
          ),
          _PicasaWindowButton(
            icon: Icons.close_rounded,
            tooltip: 'Close Viewer (Esc)',
            hoverColor: Colors.red.withValues(alpha: 0.8),
            onTap: _exitViewer,
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyA:
        _navigate(-1);
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyD:
        _navigate(1);
      case LogicalKeyboardKey.escape:
        _exitViewer();
      case LogicalKeyboardKey.f11:
        _toggleFullscreen();
      case LogicalKeyboardKey.keyI:
        _scaffoldKey.currentState?.openEndDrawer();
      case LogicalKeyboardKey.keyS:
        final currentPath = ref.read(viewerProvider).valueOrNull?.currentPath;
        _openSocialHub(currentPath);
      case LogicalKeyboardKey.keyF:
        final currentPath = ref.read(viewerProvider).valueOrNull?.currentPath;
        if (currentPath != null) {
          ref.read(favoritesProvider.notifier).toggle(currentPath);
        }
      case LogicalKeyboardKey.keyH:
        setState(() => _showHistogram = !_showHistogram);
      case LogicalKeyboardKey.keyC:
        final vState = ref.read(viewerProvider).valueOrNull;
        if (vState != null && vState.filePaths.length >= 2) {
          final prevIdx =
              (vState.currentIndex - 1 + vState.filePaths.length) % vState.filePaths.length;
          context.push('/comparison', extra: {
            'imagePathA': vState.filePaths[prevIdx],
            'imagePathB': vState.filePaths[vState.currentIndex],
            'labelA': 'Previous Photo',
            'labelB': 'Current Photo',
          });
        }
      case LogicalKeyboardKey.keyE:
        final current = ref.read(viewerProvider).valueOrNull?.currentPath;
        if (current != null) {
          context.push('/editor', extra: {'filePath': current});
        }
      case LogicalKeyboardKey.keyR:
      case LogicalKeyboardKey.bracketRight:
        _rotate(1); // 90° clockwise
      case LogicalKeyboardKey.keyL:
      case LogicalKeyboardKey.bracketLeft:
        _rotate(-1); // 90° counter-clockwise
      case LogicalKeyboardKey.keyT:
        setState(() => _showFilmstrip = !_showFilmstrip);
      case LogicalKeyboardKey.space:
        _toggleSlideshow();
      case LogicalKeyboardKey.digit0:
        _resetZoomToFit();
      case LogicalKeyboardKey.digit1:
        _setZoom(2.5);
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.add:
        _zoomIn();
      case LogicalKeyboardKey.minus:
        _zoomOut();
      case LogicalKeyboardKey.delete:
        final current = ref.read(viewerProvider).valueOrNull?.currentPath;
        _confirmAndDeleteCurrentPhoto(current);
    }
  }
}

/// Minimalist window control button for borderless title bar.
class _PicasaWindowButton extends StatelessWidget {
  const _PicasaWindowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.hoverColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? hoverColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          hoverColor: hoverColor ?? Colors.white.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Icon(icon, color: Colors.white70, size: 16),
          ),
        ),
      ),
    );
  }
}
