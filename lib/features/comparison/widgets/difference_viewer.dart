import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Pixel difference viewer using BlendMode.difference to reveal alterations and subtle deltas.
class DifferenceViewer extends StatefulWidget {
  const DifferenceViewer({
    super.key,
    required this.imagePathA,
    required this.imagePathB,
  });

  final String imagePathA;
  final String imagePathB;

  @override
  State<DifferenceViewer> createState() => _DifferenceViewerState();
}

class _DifferenceViewerState extends State<DifferenceViewer> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          transformationController: _controller,
          minScale: 0.2,
          maxScale: 16.0,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Base Image A
                Image.file(
                  File(widget.imagePathA),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),

                // Difference Blended Image B
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.dst,
                  ),
                  child: Image.file(
                    File(widget.imagePathB),
                    fit: BoxFit.contain,
                    colorBlendMode: BlendMode.difference,
                    color: Colors.white,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Info Badge
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ApertixColors.cyanAccent.withValues(alpha: 0.6)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.difference_rounded, size: 14, color: ApertixColors.cyanAccent),
                SizedBox(width: 6),
                Text(
                  'PIXEL DIFFERENCE (BLACK = IDENTICAL)',
                  style: TextStyle(
                    color: ApertixColors.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
