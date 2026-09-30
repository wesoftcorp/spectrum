import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/sources/local/image_file_service.dart';

/// Modern Nordic Frost thumbnail card with spring hover physics, parallax zoom,
/// specular glow, badge pills, and selection state.
class ImageThumbnail extends StatefulWidget {
  const ImageThumbnail({
    super.key,
    required this.imageFile,
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onToggleSelect,
    this.onQuickView,
    this.onQuickEdit,
  });

  final ImageFile imageFile;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onQuickView;
  final VoidCallback? onQuickEdit;

  @override
  State<ImageThumbnail> createState() => _ImageThumbnailState();
}

class _ImageThumbnailState extends State<ImageThumbnail> {
  bool _isHovered = false;

  Color _badgeColor(String ext) {
    switch (ext.toLowerCase()) {
      case 'raw' || 'dng' || 'nef' || 'cr2' || 'arw':
        return ApertixColors.primary;
      case 'png' || 'webp':
        return ApertixColors.cyanAccent;
      case 'gif':
        return ApertixColors.warning;
      case 'svg':
        return ApertixColors.secondary;
      default:
        return const Color(0xFF4A5568);
    }
  }

  bool get _isNativelyDecodeable {
    const nativeRasterExts = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'ico'};
    return nativeRasterExts.contains(widget.imageFile.extension.toLowerCase());
  }

  Widget _buildPlaceholder(bool isDark) {
    final ext = widget.imageFile.extension.toLowerCase();
    final icon = ['raw', 'dng', 'nef', 'cr2', 'arw'].contains(ext)
        ? Icons.camera_alt_rounded
        : (ext == 'svg' ? Icons.draw_rounded : Icons.photo_outlined);

    return Container(
      color: isDark ? const Color(0xFF141724) : const Color(0xFFE2E8F0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(
              widget.imageFile.extension.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = widget.imageFile.extension.toUpperCase();
    final badgeBg = _badgeColor(widget.imageFile.extension);
    final isSelected = widget.isSelected;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.isSelectionMode && widget.onToggleSelect != null
              ? widget.onToggleSelect!
              : widget.onTap,
          onLongPress: widget.onToggleSelect,
          child: AnimatedScale(
            scale: isSelected ? 0.95 : (_isHovered ? 1.04 : 1.0),
            duration: const Duration(milliseconds: 220),
            curve: _isHovered ? Curves.easeOutBack : Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark
                    ? const Color(0xFF191D26).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.90),
                border: Border.all(
                  color: isSelected
                      ? ApertixColors.primary
                      : (_isHovered
                          ? ApertixColors.cyanAccent.withValues(alpha: 0.85)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.65))),
                  width: isSelected ? 2.5 : (_isHovered ? 1.8 : 1.0),
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: ApertixColors.primary.withValues(alpha: 0.45),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  else if (_isHovered) ...[
                    BoxShadow(
                      color: ApertixColors.cyanAccent.withValues(alpha: isDark ? 0.35 : 0.22),
                      blurRadius: 18,
                      spreadRadius: 1.5,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: ApertixColors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                      blurRadius: 28,
                      spreadRadius: 1,
                      offset: const Offset(0, 10),
                    ),
                  ] else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Image layer ──────────────────────────────────────────
                  // IMPORTANT: Do NOT set both cacheWidth+cacheHeight — that
                  // forces a 1:1 square decode and distorts non-square images.
                  // Only set cacheWidth so the decoder preserves aspect ratio.
                  AnimatedScale(
                    scale: _isHovered ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: _isNativelyDecodeable
                        ? Image.file(
                            File(widget.imageFile.path),
                            fit: BoxFit.cover,
                            // Only constrain width — height is auto to keep aspect ratio.
                            // Flutter's decoder will compute the correct height.
                            cacheWidth: 480,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                            frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded || frame != null) return child;
                              // Fade-in while loading
                              return AnimatedOpacity(
                                opacity: frame == null ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: child,
                              );
                            },
                          )
                        : _buildPlaceholder(isDark),
                  ),

                  // Selection tint overlay
                  if (isSelected)
                    Container(
                      color: ApertixColors.primary.withValues(alpha: 0.20),
                    ),

                  // Top Pills (Format badge & Quick Hover Actions)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // File Extension Tag
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: badgeBg.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Text(
                            ext,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Hover Action Buttons & Checkbox
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isHovered && !widget.isSelectionMode && widget.onQuickEdit != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Tooltip(
                                  message: 'Quick Edit in Studio',
                                  child: InkWell(
                                    onTap: widget.onQuickEdit,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withValues(alpha: 0.65),
                                        border: Border.all(
                                          color: ApertixColors.cyanAccent.withValues(alpha: 0.8),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.tune_rounded, size: 13, color: ApertixColors.cyanAccent),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Selection Checkbox Capsule
                            if (widget.isSelectionMode || isSelected || _isHovered)
                              GestureDetector(
                                onTap: widget.onToggleSelect,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? ApertixColors.primary
                                        : Colors.black.withValues(alpha: 0.55),
                                    border: Border.all(
                                      color: isSelected ? ApertixColors.primary : Colors.white70,
                                      width: 1.6,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: ApertixColors.primary.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        ),
                                    ],
                                  ),
                                  child: Center(
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom Scrim & File Details
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.fromLTRB(8, 18, 8, 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: _isHovered ? 0.90 : 0.75),
                          ],
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              widget.imageFile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.imageFile.sizeLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
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
