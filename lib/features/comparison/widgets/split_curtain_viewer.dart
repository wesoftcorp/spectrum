import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Interactive draggable Before/After Split Curtain Slider.
class SplitCurtainViewer extends StatefulWidget {
  const SplitCurtainViewer({
    super.key,
    required this.imagePathA,
    required this.imagePathB,
    this.labelA = 'BEFORE',
    this.labelB = 'AFTER',
  });

  final String imagePathA;
  final String imagePathB;
  final String labelA;
  final String labelB;

  @override
  State<SplitCurtainViewer> createState() => _SplitCurtainViewerState();
}

class _SplitCurtainViewerState extends State<SplitCurtainViewer> {
  double _splitFraction = 0.5; // [0.0 .. 1.0]
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        final splitX = (totalWidth * _splitFraction).clamp(0.0, totalWidth);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Image B (After / Right / Background)
            Positioned.fill(
              child: Image.file(
                File(widget.imagePathB),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),

            // Image A (Before / Left / Foreground clipped to splitX)
            Positioned.fill(
              child: ClipRect(
                clipper: _LeftSplitClipper(splitX: splitX),
                child: Image.file(
                  File(widget.imagePathA),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),

            // Labels
            Positioned(
              top: 20,
              left: 20,
              child: _ComparisonBadge(label: widget.labelA, isLeft: true),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: _ComparisonBadge(label: widget.labelB, isLeft: false),
            ),

            // Splitter Line & Draggable Handle
            Positioned(
              left: splitX - 1.5,
              top: 0,
              bottom: 0,
              width: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),

            // Draggable Knob / Pill
            Positioned(
              left: splitX - 22,
              top: (totalHeight / 2) - 22,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) => setState(() => _isDragging = true),
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _splitFraction = (_splitFraction + (details.delta.dx / totalWidth)).clamp(0.01, 0.99);
                  });
                },
                onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isDragging ? ApertixColors.primary : const Color(0xFF10131E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isDragging ? ApertixColors.cyanAccent : Colors.white70,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        color: _isDragging ? Colors.white : ApertixColors.cyanAccent,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Full-screen horizontal drag gesture detector
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _splitFraction = (_splitFraction + (details.delta.dx / totalWidth)).clamp(0.01, 0.99);
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LeftSplitClipper extends CustomClipper<Rect> {
  const _LeftSplitClipper({required this.splitX});
  final double splitX;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, splitX, size.height);
  }

  @override
  bool shouldReclip(covariant _LeftSplitClipper oldClipper) {
    return oldClipper.splitX != splitX;
  }
}

class _ComparisonBadge extends StatelessWidget {
  const _ComparisonBadge({required this.label, required this.isLeft});
  final String label;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLeft ? ApertixColors.cyanAccent.withValues(alpha: 0.6) : ApertixColors.secondary.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isLeft ? ApertixColors.cyanAccent : ApertixColors.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
