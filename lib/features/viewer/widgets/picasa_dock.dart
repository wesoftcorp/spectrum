import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Iconic Picasa-style curved floating control dock.
class PicasaDock extends StatelessWidget {
  const PicasaDock({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.zoomLevel,
    required this.onZoomChanged,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    required this.onNavigatePrev,
    required this.onNavigateNext,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onToggleSlideshow,
    required this.isPlayingSlideshow,
    required this.onToggleFilmstrip,
    required this.isFilmstripVisible,
    required this.onOpenEditor,
    required this.onOpenMetadata,
    required this.onToggleFullscreen,
    required this.isFullscreen,
    required this.onClose,
  });

  final int currentIndex;
  final int totalCount;
  final double zoomLevel; // e.g. 1.0 = fit
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final VoidCallback onNavigatePrev;
  final VoidCallback onNavigateNext;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onToggleSlideshow;
  final bool isPlayingSlideshow;
  final VoidCallback onToggleFilmstrip;
  final bool isFilmstripVisible;
  final VoidCallback onOpenEditor;
  final VoidCallback onOpenMetadata;
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final canPrev = currentIndex > 0;
    final canNext = currentIndex < totalCount - 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0E17).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: ApertixColors.cyanAccent.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Previous Arrow Button (Big Picasa Circular)
              _CircularNavButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous Image (←)',
                enabled: canPrev,
                onTap: onNavigatePrev,
              ),
              const SizedBox(width: 6),

              // 1:1 / Fit Toggle Button
              _PicasaPillButton(
                label: zoomLevel > 1.05 ? 'FIT' : '1:1',
                tooltip: zoomLevel > 1.05 ? 'Fit to Screen (0)' : 'Actual Size 100% (1)',
                isActive: zoomLevel > 1.05,
                onTap: onResetZoom,
              ),
              const SizedBox(width: 6),

              // Next Arrow Button (Big Picasa Circular)
              _CircularNavButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next Image (→)',
                enabled: canNext,
                onTap: onNavigateNext,
              ),

              const SizedBox(width: 14),
              _buildDivider(),
              const SizedBox(width: 14),

              // Zoom Controls: [-] [Slider] [+]
              _PicasaIconButton(
                icon: Icons.remove_rounded,
                tooltip: 'Zoom Out (-)',
                onTap: onZoomOut,
              ),
              SizedBox(
                width: 100,
                child: SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: ApertixColors.cyanAccent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: ApertixColors.cyanAccent,
                  ),
                  child: Slider(
                    value: zoomLevel.clamp(0.5, 4.0),
                    min: 0.5,
                    max: 4.0,
                    onChanged: onZoomChanged,
                  ),
                ),
              ),
              _PicasaIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Zoom In (+)',
                onTap: onZoomIn,
              ),

              const SizedBox(width: 12),
              _buildDivider(),
              const SizedBox(width: 12),

              // Rotation: Left & Right
              _PicasaIconButton(
                icon: Icons.rotate_left_rounded,
                tooltip: 'Rotate Left 90° (L)',
                onTap: onRotateLeft,
              ),
              _PicasaIconButton(
                icon: Icons.rotate_right_rounded,
                tooltip: 'Rotate Right 90° (R)',
                onTap: onRotateRight,
              ),

              const SizedBox(width: 8),
              _buildDivider(),
              const SizedBox(width: 8),

              // Filmstrip toggle
              _PicasaIconButton(
                icon: Icons.view_carousel_rounded,
                tooltip: 'Toggle Filmstrip (T)',
                highlightColor: isFilmstripVisible ? ApertixColors.cyanAccent : null,
                onTap: onToggleFilmstrip,
              ),

              // Slideshow
              _PicasaIconButton(
                icon: isPlayingSlideshow ? Icons.pause_rounded : Icons.play_arrow_rounded,
                tooltip: isPlayingSlideshow ? 'Pause Slideshow (Space)' : 'Play Slideshow (Space)',
                highlightColor: isPlayingSlideshow ? ApertixColors.secondary : null,
                onTap: onToggleSlideshow,
              ),

              // Studio Edit
              _PicasaIconButton(
                icon: Icons.tune_rounded,
                tooltip: 'Open in Editor (E)',
                highlightColor: ApertixColors.primaryLight,
                onTap: onOpenEditor,
              ),

              // EXIF Info
              _PicasaIconButton(
                icon: Icons.info_outline_rounded,
                tooltip: 'EXIF Info (I)',
                onTap: onOpenMetadata,
              ),

              // Fullscreen
              _PicasaIconButton(
                icon: isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                tooltip: isFullscreen ? 'Exit Fullscreen (F11)' : 'Fullscreen (F11)',
                onTap: onToggleFullscreen,
              ),

              const SizedBox(width: 6),
              _buildDivider(),
              const SizedBox(width: 6),

              // Close Viewer (Esc)
              _PicasaIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Close (Esc)',
                hoverBgColor: Colors.red.withValues(alpha: 0.3),
                onTap: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

/// Large Circular Button for Previous / Next (Authentic Picasa aesthetic).
class _CircularNavButton extends StatelessWidget {
  const _CircularNavButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.03),
              border: Border.all(
                color: enabled
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: enabled ? Colors.white : Colors.white24,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1:1 or Fit Pill Button.
class _PicasaPillButton extends StatelessWidget {
  const _PicasaPillButton({
    required this.label,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isActive
                  ? ApertixColors.cyanAccent.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: isActive
                    ? ApertixColors.cyanAccent
                    : Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? ApertixColors.cyanAccent : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact Icon button with hover effect.
class _PicasaIconButton extends StatelessWidget {
  const _PicasaIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlightColor,
    this.hoverBgColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? highlightColor;
  final Color? hoverBgColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          hoverColor: hoverBgColor ?? (highlightColor ?? Colors.white).withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              color: highlightColor ?? Colors.white.withValues(alpha: 0.88),
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}
