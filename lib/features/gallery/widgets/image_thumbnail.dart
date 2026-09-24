import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/sources/local/image_file_service.dart';

/// Modern Nordic Frost thumbnail card with hover glow, badge pills, and selection state.
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
            scale: isSelected ? 0.96 : (_isHovered ? 1.025 : 1.0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark
                    ? const Color(0xFF191D26).withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.85),
                border: Border.all(
                  color: isSelected
                      ? ApertixColors.primary
                      : (_isHovered
                          ? ApertixColors.cyanAccent.withValues(alpha: 0.7)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.65))),
                  width: isSelected ? 2.5 : (_isHovered ? 1.5 : 1.0),
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: ApertixColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                    )
                  else if (_isHovered)
                    BoxShadow(
                      color: ApertixColors.cyanAccent.withValues(alpha: 0.2),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    )
                  else
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
                  // Image layer
                  Image.file(
                    File(widget.imageFile.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: isDark ? const Color(0xFF141724) : const Color(0xFFE2E8F0),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 32,
                        ),
                      ),
                    ),
                    cacheWidth: 300,
                    cacheHeight: 300,
                  ),

                // Selection tint overlay
                if (isSelected)
                  Container(
                    color: ApertixColors.primary.withValues(alpha: 0.15),
                  ),

                // Top Pills (Format badge, Selection Checkbox, Hover Actions)
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // File Extension Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
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

                      // Selection Checkbox or Hover Action Capsule
                      if (widget.isSelectionMode || isSelected || _isHovered)
                        GestureDetector(
                          onTap: widget.onToggleSelect,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? ApertixColors.primary
                                  : Colors.black.withValues(alpha: 0.5),
                              border: Border.all(
                                color: isSelected ? ApertixColors.primary : Colors.white60,
                                width: 1.5,
                              ),
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
                ),

                // Bottom Scrim & File Details
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Filename
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
                        // Size label
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
