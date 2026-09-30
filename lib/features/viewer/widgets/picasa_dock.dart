import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Iconic Google Picasa-style curved floating control dock.
/// Features the signature frosted capsule, circular navigation buttons,
/// interactive zoom slider with percentage badge, rotation, golden star favorite,
/// pulsing slideshow indicator, filmstrip toggle, editor launcher, trash, and window controls.
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
    this.onOpenSocialHub,
    required this.onToggleFullscreen,
    required this.isFullscreen,
    required this.onClose,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.onDelete,
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
  final VoidCallback? onOpenSocialHub;
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;
  final VoidCallback onClose;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final canPrev = totalCount > 1;
    final canNext = totalCount > 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isZoomed = zoomLevel > 1.05;

    return ClipRRect(
      borderRadius: BorderRadius.circular(38),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xF0252834),
                      const Color(0xF012141C),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.95),
                      const Color(0xFFF1F3F8).withValues(alpha: 0.92),
                    ],
            ),
            borderRadius: BorderRadius.circular(38),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.15),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              if (isDark)
                BoxShadow(
                  color: ApertixColors.primary.withValues(alpha: 0.10),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous Arrow Button (Big Picasa Circular)
                _CircularNavButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous Image (← or A)',
                  enabled: canPrev,
                  onTap: onNavigatePrev,
                ),
                const SizedBox(width: 4),

                // 1:1 / Fit Toggle Button (Picasa pill)
                _PicasaPillButton(
                  label: isZoomed ? 'FIT' : '1:1',
                  tooltip: isZoomed ? 'Fit to Screen (0)' : 'Actual Size 100% (1)',
                  isActive: isZoomed,
                  onTap: onResetZoom,
                ),
                const SizedBox(width: 4),

                // Next Arrow Button (Big Picasa Circular)
                _CircularNavButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next Image (→ or D)',
                  enabled: canNext,
                  onTap: onNavigateNext,
                ),

                const SizedBox(width: 8),
                _buildDivider(isDark),
                const SizedBox(width: 8),

                // Zoom Controls: [-] [Slider] [+] [Zoom Tag]
                _PicasaIconButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out (- / Wheel Down)',
                  onTap: onZoomOut,
                ),
                SizedBox(
                  width: 78,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: ApertixColors.primary,
                      inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                      thumbColor: Colors.white,
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
                  tooltip: 'Zoom In (+ / Wheel Up)',
                  onTap: onZoomIn,
                ),

                // Zoom Percentage Tag with quick preset menu
                PopupMenuButton<double>(
                  tooltip: 'Zoom Presets',
                  onSelected: onZoomChanged,
                  color: isDark ? ApertixColors.darkSurfaceElevated : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
                    ),
                  ),
                  itemBuilder: (context) => [
                    _buildZoomMenuItem(1.0, 'Fit to Screen (100%)', isDark),
                    _buildZoomMenuItem(0.5, '50%', isDark),
                    _buildZoomMenuItem(1.5, '150%', isDark),
                    _buildZoomMenuItem(2.0, '200%', isDark),
                    _buildZoomMenuItem(3.0, '300%', isDark),
                    _buildZoomMenuItem(4.0, '400%', isDark),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${(zoomLevel * 100).round()}%',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                _buildDivider(isDark),
                const SizedBox(width: 8),

                // Rotation: Left & Right
                _PicasaIconButton(
                  icon: Icons.rotate_left_rounded,
                  tooltip: 'Rotate Left 90° (L or [)',
                  onTap: onRotateLeft,
                ),
                _PicasaIconButton(
                  icon: Icons.rotate_right_rounded,
                  tooltip: 'Rotate Right 90° (R or ])',
                  onTap: onRotateRight,
                ),

                const SizedBox(width: 6),
                _buildDivider(isDark),
                const SizedBox(width: 6),

              // Picasa Signature Star / Favorite Button
              if (onToggleFavorite != null)
                _PicasaStarButton(
                  isFavorite: isFavorite,
                  tooltip: isFavorite ? 'Remove Favorite (F)' : 'Add Favorite (F)',
                  onTap: onToggleFavorite!,
                ),

              // Slideshow with glowing ring indicator when active
              _PicasaSlideshowButton(
                isPlaying: isPlayingSlideshow,
                tooltip: isPlayingSlideshow ? 'Pause Slideshow (Space)' : 'Play Slideshow (Space)',
                onTap: onToggleSlideshow,
              ),

              // Filmstrip toggle
              _PicasaIconButton(
                icon: Icons.view_carousel_rounded,
                tooltip: 'Filmstrip Carousel (T)',
                highlightColor: isFilmstripVisible ? ApertixColors.cyanAccent : null,
                onTap: onToggleFilmstrip,
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
                tooltip: 'Image EXIF Info (I)',
                onTap: onOpenMetadata,
              ),

              // Social Hub
              if (onOpenSocialHub != null)
                _PicasaIconButton(
                  icon: Icons.share_rounded,
                  tooltip: 'Social Hub (S)',
                  highlightColor: ApertixColors.cyanAccent,
                  onTap: onOpenSocialHub!,
                ),

              // Delete Trash Button
              if (onDelete != null)
                _PicasaIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete Photo (Delete)',
                  hoverBgColor: Colors.red.withValues(alpha: 0.25),
                  highlightColor: Colors.redAccent.shade100,
                  onTap: onDelete!,
                ),

              // Fullscreen
              _PicasaIconButton(
                icon: isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                tooltip: isFullscreen ? 'Exit Fullscreen (F11)' : 'Fullscreen (F11)',
                onTap: onToggleFullscreen,
              ),

              const SizedBox(width: 6),
              _buildDivider(isDark),
              const SizedBox(width: 6),

              // Close Viewer (Esc)
              _PicasaIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Close (Esc)',
                hoverBgColor: Colors.red.withValues(alpha: 0.35),
                onTap: onClose,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  PopupMenuItem<double> _buildZoomMenuItem(double scale, String text, bool isDark) {
    return PopupMenuItem<double>(
      value: scale,
      height: 36,
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? ApertixColors.darkTextPrimary : ApertixColors.lightTextPrimary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1.2,
      height: 22,
      color: isDark
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.black.withValues(alpha: 0.10),
    );
  }
}

/// Large Circular Button for Previous / Next (Authentic Google Picasa aesthetic).
class _CircularNavButton extends StatefulWidget {
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
  State<_CircularNavButton> createState() => _CircularNavButtonState();
}

class _CircularNavButtonState extends State<_CircularNavButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scale = !widget.enabled
        ? 1.0
        : (_isPressed
            ? 0.90
            : (_isHovered ? 1.10 : 1.0));

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (widget.enabled) setState(() => _isHovered = true);
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
            _isPressed = false;
          });
        },
        child: GestureDetector(
          onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedScale(
            scale: scale,
            duration: Duration(milliseconds: _isPressed ? 100 : 200),
            curve: _isPressed ? Curves.easeInQuad : Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.enabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.white.withValues(alpha: _isHovered ? 0.28 : 0.16),
                                Colors.white.withValues(alpha: _isHovered ? 0.14 : 0.06),
                              ]
                            : [
                                Colors.black.withValues(alpha: _isHovered ? 0.14 : 0.08),
                                Colors.black.withValues(alpha: _isHovered ? 0.06 : 0.03),
                              ],
                      )
                    : null,
                color: widget.enabled
                    ? null
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.02)),
                border: Border.all(
                  color: widget.enabled
                      ? (_isHovered
                          ? ApertixColors.cyanAccent
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.28)
                              : Colors.black.withValues(alpha: 0.14)))
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                  width: _isHovered ? 1.6 : 1.2,
                ),
                boxShadow: widget.enabled
                    ? [
                        BoxShadow(
                          color: _isHovered
                              ? ApertixColors.cyanAccent.withValues(alpha: 0.40)
                              : Colors.black.withValues(alpha: 0.25),
                          blurRadius: _isHovered ? 14 : 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: widget.enabled
                      ? (_isHovered
                          ? ApertixColors.cyanAccent
                          : (isDark ? Colors.white : ApertixColors.lightTextPrimary))
                      : (isDark ? Colors.white24 : Colors.black26),
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1:1 or Fit Pill Button (Picasa style) with spring hover.
class _PicasaPillButton extends StatefulWidget {
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
  State<_PicasaPillButton> createState() => _PicasaPillButtonState();
}

class _PicasaPillButtonState extends State<_PicasaPillButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = _isPressed ? 0.92 : (_isHovered ? 1.08 : 1.0);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: scale,
            duration: Duration(milliseconds: _isPressed ? 100 : 200),
            curve: _isPressed ? Curves.easeInQuad : Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: widget.isActive
                    ? ApertixColors.primary.withValues(alpha: 0.28)
                    : (_isHovered
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.black.withValues(alpha: 0.08))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05))),
                border: Border.all(
                  color: widget.isActive || _isHovered
                      ? ApertixColors.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.22)
                          : Colors.black.withValues(alpha: 0.12)),
                  width: 1.2,
                ),
                boxShadow: [
                  if (widget.isActive || _isHovered)
                    BoxShadow(
                      color: ApertixColors.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive || _isHovered
                      ? ApertixColors.cyanAccent
                      : (isDark ? Colors.white : ApertixColors.lightTextPrimary),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Picasa Golden Star Favorite button with gold glow and spring scale.
class _PicasaStarButton extends StatefulWidget {
  const _PicasaStarButton({
    required this.isFavorite,
    required this.tooltip,
    required this.onTap,
  });

  final bool isFavorite;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_PicasaStarButton> createState() => _PicasaStarButtonState();
}

class _PicasaStarButtonState extends State<_PicasaStarButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = _isPressed ? 0.90 : (_isHovered ? 1.15 : 1.0);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: scale,
            duration: Duration(milliseconds: _isPressed ? 100 : 200),
            curve: _isPressed ? Curves.easeInQuad : Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isHovered
                    ? const Color(0xFFFFD700).withValues(alpha: 0.18)
                    : Colors.transparent,
                boxShadow: [
                  if (widget.isFavorite || _isHovered)
                    BoxShadow(
                      color: const Color(0xFFFFC107).withValues(alpha: _isHovered ? 0.55 : 0.40),
                      blurRadius: _isHovered ? 14 : 10,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Icon(
                widget.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: (widget.isFavorite || _isHovered)
                    ? const Color(0xFFFFC107)
                    : (isDark ? Colors.white70 : Colors.black54),
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Picasa Slideshow Button with pulsating glow when playing and spring hover.
class _PicasaSlideshowButton extends StatefulWidget {
  const _PicasaSlideshowButton({
    required this.isPlaying,
    required this.tooltip,
    required this.onTap,
  });

  final bool isPlaying;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_PicasaSlideshowButton> createState() => _PicasaSlideshowButtonState();
}

class _PicasaSlideshowButtonState extends State<_PicasaSlideshowButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = _isPressed ? 0.90 : (_isHovered ? 1.15 : 1.0);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: scale,
            duration: Duration(milliseconds: _isPressed ? 100 : 200),
            curve: _isPressed ? Curves.easeInQuad : Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isPlaying
                    ? ApertixColors.secondary.withValues(alpha: 0.22)
                    : (_isHovered ? ApertixColors.secondary.withValues(alpha: 0.15) : Colors.transparent),
                border: widget.isPlaying
                    ? Border.all(color: ApertixColors.secondary, width: 1.2)
                    : null,
                boxShadow: [
                  if (widget.isPlaying || _isHovered)
                    BoxShadow(
                      color: ApertixColors.secondary.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Icon(
                widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isPlaying || _isHovered
                    ? ApertixColors.secondary
                    : (isDark ? Colors.white.withValues(alpha: 0.88) : Colors.black87),
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact Icon button with fluid spring scaling and glowing halo.
class _PicasaIconButton extends StatefulWidget {
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
  State<_PicasaIconButton> createState() => _PicasaIconButtonState();
}

class _PicasaIconButtonState extends State<_PicasaIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor =
        isDark ? Colors.white.withValues(alpha: 0.88) : ApertixColors.lightTextPrimary;
    final activeColor = widget.highlightColor ?? defaultIconColor;

    final scale = _isPressed ? 0.90 : (_isHovered ? 1.14 : 1.0);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: scale,
            duration: Duration(milliseconds: _isPressed ? 100 : 200),
            curve: _isPressed ? Curves.easeInQuad : Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isHovered
                    ? (widget.hoverBgColor ?? activeColor.withValues(alpha: 0.15))
                    : Colors.transparent,
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(
                      color: (widget.highlightColor ?? ApertixColors.cyanAccent).withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: _isHovered ? (widget.highlightColor ?? ApertixColors.cyanAccent) : activeColor,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
