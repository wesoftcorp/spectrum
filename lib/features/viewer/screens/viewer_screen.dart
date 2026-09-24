import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/viewer_provider.dart';
import '../widgets/picasa_dock.dart';
import '../widgets/thumbnail_strip.dart';
import '../widgets/animation_controls_bar.dart';
import '../../metadata/widgets/metadata_drawer.dart';
import '../../social/widgets/social_hub_dialog.dart';
import '../../../core/licensing/widgets/license_dialog.dart';
import '../../../core/licensing/providers/license_provider.dart';
import '../../analysis/widgets/histogram_overlay.dart';
import '../../collections/providers/collections_provider.dart';
import '../../cloud/widgets/cloud_vault_dialog.dart';

/// Iconic Google Picasa-style borderless photo viewer player.
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

  // Animated Media state
  bool _isAnimationPlaying = true;
  double _animationSpeed = 1.0;

  bool _isAnimatedMedia(String? path) {
    if (path == null) return false;
    final ext = p.extension(path).toLowerCase();
    return ext == '.gif' || ext == '.apng';
  }

  // Transformations
  final Map<int, int> _rotations = {}; // index -> quarter turns (0, 1, 2, 3)
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _photoViewController = PhotoViewController()
      ..outputStateStream.listen((state) {
        if (state.scale != null && mounted) {
          setState(() => _currentScale = state.scale!);
        }
      });

    // Make window borderless for authentic Picasa experience on desktop
    _enableBorderlessWindow();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(viewerProvider.notifier).init(
            filePaths: widget.fileList,
            initialIndex: widget.initialIndex,
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
    final newIndex = notifier.navigate(delta);
    if (newIndex != null) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      _resetZoom();
    }
  }

  void _rotate(int quarterTurnsDelta) {
    _resetInactivityTimer();
    final currentIndex = ref.read(viewerProvider).valueOrNull?.currentIndex ?? 0;
    setState(() {
      final current = _rotations[currentIndex] ?? 0;
      _rotations[currentIndex] = (current + quarterTurnsDelta) % 4;
    });
  }

  void _zoomIn() {
    _resetInactivityTimer();
    final newScale = (_currentScale * 1.25).clamp(0.5, 4.0);
    _photoViewController.scale = newScale;
    setState(() => _currentScale = newScale);
  }

  void _zoomOut() {
    _resetInactivityTimer();
    final newScale = (_currentScale / 1.25).clamp(0.5, 4.0);
    _photoViewController.scale = newScale;
    setState(() => _currentScale = newScale);
  }

  void _setZoom(double scale) {
    _resetInactivityTimer();
    _photoViewController.scale = scale;
    setState(() => _currentScale = scale);
  }

  void _resetZoom() {
    _resetInactivityTimer();
    final target = _currentScale > 1.05 ? 1.0 : 2.5;
    _photoViewController.scale = target;
    setState(() => _currentScale = target);
  }

  void _toggleSlideshow() {
    _resetInactivityTimer();
    setState(() {
      _isPlayingSlideshow = !_isPlayingSlideshow;
    });

    if (_isPlayingSlideshow) {
      _slideshowTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        final state = ref.read(viewerProvider).valueOrNull;
        if (state != null) {
          if (state.currentIndex < state.filePaths.length - 1) {
            _navigate(1);
          } else {
            // Loop back to start
            ref.read(viewerProvider.notifier).setIndex(0);
            _pageController.jumpToPage(0);
          }
        }
      });
    } else {
      _slideshowTimer?.cancel();
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

  void _exitViewer() {
    _restoreStandardWindow();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(viewerProvider);

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(err.toString(), style: const TextStyle(color: Colors.white)),
            ),
            data: (viewerState) {
              final currentIndex = viewerState.currentIndex;
              final currentPath = viewerState.currentPath;
              final fileName = currentPath != null ? p.basename(currentPath) : '';

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Picasa Frosted Background Scrim
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xEE12141A)
                          : const Color(0xEEF4F6F9),
                    ),
                  ),

                  // Main Photo View Gallery
                  GestureDetector(
                    onTap: () {
                      setState(() => _showUi = !_showUi);
                    },
                    onDoubleTap: _resetZoom,
                    child: PhotoViewGallery.builder(
                      pageController: _pageController,
                      itemCount: viewerState.filePaths.length,
                      onPageChanged: (index) {
                        ref.read(viewerProvider.notifier).setIndex(index);
                      },
                      builder: (context, index) {
                        final path = viewerState.filePaths[index];
                        final rot = _rotations[index] ?? 0;

                        return PhotoViewGalleryPageOptions.customChild(
                          child: RotatedBox(
                            quarterTurns: rot,
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
                          controller: index == currentIndex ? _photoViewController : null,
                          minScale: PhotoViewComputedScale.contained * 0.75,
                          maxScale: PhotoViewComputedScale.covered * AppConstants.maxZoom,
                          initialScale: PhotoViewComputedScale.contained,
                          heroAttributes: PhotoViewHeroAttributes(tag: path),
                        );
                      },
                      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                    ),
                  ),

                  // Top Borderless Bar with Drag-to-Move area & Window controls
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    top: _showUi ? 0 : -64,
                    left: 0,
                    right: 0,
                    child: _buildTopBorderlessBar(fileName, currentIndex + 1, viewerState.filePaths.length, viewerState),
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

                  // Bottom Filmstrip (Auto-scrolls, togglable)
                  if (_showFilmstrip && viewerState.filePaths.length > 1)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      bottom: _showUi ? 86 : -100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.6),
                                padding: const EdgeInsets.all(8),
                                child: ThumbnailStrip(
                                  paths: viewerState.filePaths,
                                  currentIndex: currentIndex,
                                  onTap: (index) {
                                    ref.read(viewerProvider.notifier).setIndex(index);
                                    _pageController.animateToPage(
                                      index,
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                    );
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
                      bottom: _showUi ? (_showFilmstrip ? 170 : 86) : -80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimationControlsBar(
                          isPlaying: _isAnimationPlaying,
                          playbackSpeed: _animationSpeed,
                          onTogglePlayPause: () => setState(() => _isAnimationPlaying = !_isAnimationPlaying),
                          onSpeedChanged: (spd) => setState(() => _animationSpeed = spd),
                        ),
                      ),
                    ),

                  // Picasa Floating Bottom Control Dock
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    bottom: _showUi ? 24 : -80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _isHoveringControls = true),
                        onExit: (_) => setState(() => _isHoveringControls = false),
                        child: PicasaDock(
                          currentIndex: currentIndex,
                          totalCount: viewerState.filePaths.length,
                          zoomLevel: _currentScale,
                          onZoomChanged: _setZoom,
                          onZoomIn: _zoomIn,
                          onZoomOut: _zoomOut,
                          onResetZoom: _resetZoom,
                          onNavigatePrev: () => _navigate(-1),
                          onNavigateNext: () => _navigate(1),
                          onRotateLeft: () => _rotate(-1),
                          onRotateRight: () => _rotate(1),
                          onToggleSlideshow: _toggleSlideshow,
                          isPlayingSlideshow: _isPlayingSlideshow,
                          onToggleFilmstrip: () => setState(() => _showFilmstrip = !_showFilmstrip),
                          isFilmstripVisible: _showFilmstrip,
                          onOpenEditor: () {
                            if (currentPath != null) {
                              context.push('/editor', extra: {'filePath': currentPath});
                            }
                          },
                          onOpenMetadata: () => _scaffoldKey.currentState?.openEndDrawer(),
                          onOpenSocialHub: currentPath != null ? () => _openSocialHub(currentPath) : null,
                          onToggleFullscreen: _toggleFullscreen,
                          isFullscreen: _isFullscreen,
                          onClose: _exitViewer,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBorderlessBar(String fileName, int current, int total, ViewerState viewerState) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            tooltip: 'Return to Gallery (Esc)',
            onPressed: _exitViewer,
          ),
          const SizedBox(width: 8),

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
                  letterSpacing: 0.2,
                ),
              ),
              if (total > 0)
                Text(
                  '$current of $total',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
            ],
          ),

          // Draggable window area in the center
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) async {
                try {
                  await windowManager.startDragging();
                } catch (_) {}
              },
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
                final prevIndex = (viewerState.currentIndex - 1 + paths.length) % paths.length;
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

          // Favorite Heart Toggle
          IconButton(
            icon: Icon(
              ref.watch(favoritesProvider).contains(viewerState.currentPath)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: ref.watch(favoritesProvider).contains(viewerState.currentPath)
                  ? const Color(0xFFFF4757)
                  : Colors.white70,
              size: 18,
            ),
            tooltip: 'Favorite (F)',
            onPressed: () {
              if (viewerState.currentPath != null) {
                ref.read(favoritesProvider.notifier).toggle(viewerState.currentPath!);
              }
            },
          ),

          // Cloud Vault Backup
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: ApertixColors.cyanAccent, size: 18),
            tooltip: 'Backup to Cloud Vault',
            onPressed: () {
              if (viewerState.currentPath != null) {
                showDialog(
                  context: context,
                  builder: (_) => CloudVaultDialog(filePaths: [viewerState.currentPath!]),
                );
              }
            },
          ),

          // Social Hub 1-tap launcher
          IconButton(
            icon: const Icon(Icons.share_rounded, color: ApertixColors.cyanAccent, size: 18),
            tooltip: 'Social Hub (S)',
            onPressed: () {
              final currentPath = ref.read(viewerProvider).valueOrNull?.currentPath;
              _openSocialHub(currentPath);
            },
          ),

          // Apertix Pro License
          IconButton(
            icon: Icon(
              ref.watch(isProActiveProvider) ? Icons.verified_rounded : Icons.workspace_premium_rounded,
              color: ref.watch(isProActiveProvider) ? ApertixColors.secondary : ApertixColors.primaryLight,
              size: 18,
            ),
            tooltip: ref.watch(isProActiveProvider) ? 'Apertix Pro Active' : 'Unlock Apertix Pro',
            onPressed: () => showDialog(context: context, builder: (_) => const LicenseDialog()),
          ),

          // Window Management controls (Minimize, Maximize, Close)
          IconButton(
            icon: const Icon(Icons.remove_rounded, color: Colors.white70, size: 18),
            tooltip: 'Minimize',
            onPressed: () async {
              try {
                await windowManager.minimize();
              } catch (_) {}
            },
          ),
          IconButton(
            icon: Icon(
              _isFullscreen ? Icons.crop_square_rounded : Icons.square_outlined,
              color: Colors.white70,
              size: 16,
            ),
            tooltip: _isFullscreen ? 'Restore' : 'Maximize',
            onPressed: _toggleFullscreen,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
            tooltip: 'Close Viewer (Esc)',
            hoverColor: Colors.red.withValues(alpha: 0.3),
            onPressed: _exitViewer,
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
        _navigate(-1);
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowDown:
        _navigate(1);
      case LogicalKeyboardKey.escape:
        _exitViewer();
      case LogicalKeyboardKey.f11:
      case LogicalKeyboardKey.keyF:
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
          final prevIdx = (vState.currentIndex - 1 + vState.filePaths.length) % vState.filePaths.length;
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
        _rotate(1); // 90° clockwise
      case LogicalKeyboardKey.keyL:
        _rotate(-1); // 90° counter-clockwise
      case LogicalKeyboardKey.keyT:
        setState(() => _showFilmstrip = !_showFilmstrip);
      case LogicalKeyboardKey.space:
        _toggleSlideshow();
      case LogicalKeyboardKey.digit0:
        _setZoom(1.0);
      case LogicalKeyboardKey.digit1:
        _setZoom(2.5);
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.add:
        _zoomIn();
      case LogicalKeyboardKey.minus:
        _zoomOut();
    }
  }
}
