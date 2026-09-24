import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/viewer_provider.dart';

/// Floating Nordic Frost Island toolbar for Viewer Screen.
class ViewerToolbar extends StatelessWidget {
  const ViewerToolbar({
    super.key,
    required this.viewerState,
    required this.onNavigatePrev,
    required this.onNavigateNext,
    required this.onToggleFullscreen,
    required this.isFullscreen,
    this.onOpenMetadata,
  });

  final ViewerState viewerState;
  final VoidCallback onNavigatePrev;
  final VoidCallback onNavigateNext;
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;
  final VoidCallback? onOpenMetadata;

  @override
  Widget build(BuildContext context) {
    final fileName = viewerState.currentPath != null
        ? p.basename(viewerState.currentPath!)
        : '';
    final count = viewerState.filePaths.length;
    final index = viewerState.currentIndex + 1;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? ApertixColors.darkSurfaceElevated : Colors.white).withValues(alpha: isDark ? 0.85 : 0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back button
                  _GlassToolbarButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back to Gallery (Esc)',
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 8),

                  // File name + index pill
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            fileName,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$index / $count',
                              style: TextStyle(
                                color: isDark ? Colors.white.withValues(alpha: 0.8) : ApertixColors.lightTextSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Previous Image
                  _GlassToolbarButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Previous (←)',
                    onTap: onNavigatePrev,
                  ),
                  const SizedBox(width: 4),

                  // Next Image
                  _GlassToolbarButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Next (→)',
                    onTap: onNavigateNext,
                  ),
                  const SizedBox(width: 8),

                  // Edit button
                  _GlassToolbarButton(
                    icon: Icons.tune_rounded,
                    tooltip: 'Edit & Color Grade (E)',
                    highlightColor: ApertixColors.primary,
                    onTap: () {
                      final current = viewerState.currentPath;
                      if (current != null) {
                        context.push('/editor', extra: {'filePath': current});
                      }
                    },
                  ),
                  const SizedBox(width: 4),

                  // EXIF Metadata button
                  if (onOpenMetadata != null) ...[
                    _GlassToolbarButton(
                      icon: Icons.info_outline_rounded,
                      tooltip: 'Image EXIF & Details (I)',
                      onTap: onOpenMetadata!,
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Fullscreen toggle
                  _GlassToolbarButton(
                    icon: isFullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    tooltip: isFullscreen ? 'Exit Fullscreen (F11)' : 'Fullscreen (F11)',
                    onTap: () async {
                      onToggleFullscreen();
                      final isFs = await windowManager.isFullScreen();
                      await windowManager.setFullScreen(!isFs);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassToolbarButton extends StatelessWidget {
  const _GlassToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlightColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white.withValues(alpha: 0.9) : ApertixColors.lightTextPrimary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: (highlightColor ?? defaultColor).withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              color: highlightColor ?? defaultColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
