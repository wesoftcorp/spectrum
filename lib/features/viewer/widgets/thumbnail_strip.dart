import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/app_theme.dart';

/// Horizontal filmstrip at the bottom of the viewer for quick navigation.
/// Styled like Google Picasa's iconic bottom carousel.
class ThumbnailStrip extends StatefulWidget {
  const ThumbnailStrip({
    super.key,
    required this.paths,
    required this.currentIndex,
    required this.onTap,
  });

  final List<String> paths;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<ThumbnailStrip> createState() => _ThumbnailStripState();
}

class _ThumbnailStripState extends State<ThumbnailStrip> {
  late final ScrollController _scroll;
  static const _thumbWidth = 76.0;
  static const _thumbHeight = 56.0;
  static const _borderRadius = 8.0;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _scrollToCurrentIndex();
  }

  @override
  void didUpdateWidget(ThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollToCurrentIndex();
    }
  }

  void _scrollToCurrentIndex() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scroll.hasClients && widget.paths.isNotEmpty) {
        final offset = (widget.currentIndex * (_thumbWidth + 8)) -
            (_scroll.position.viewportDimension / 2 - _thumbWidth / 2);
        _scroll.animateTo(
          offset.clamp(0.0, _scroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _thumbHeight + 14,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == widget.currentIndex;
          final path = widget.paths[index];
          final fileName = p.basename(path);

          return Tooltip(
            message: '${index + 1}. $fileName',
            waitDuration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: () => widget.onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isSelected ? _thumbWidth + 4 : _thumbWidth,
                height: isSelected ? _thumbHeight + 4 : _thumbHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_borderRadius),
                  border: Border.all(
                    color: isSelected
                        ? ApertixColors.cyanAccent
                        : Colors.white.withValues(alpha: 0.22),
                    width: isSelected ? 2.5 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: ApertixColors.cyanAccent.withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  cacheWidth: 160,
                  cacheHeight: 120,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1C1E26),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
