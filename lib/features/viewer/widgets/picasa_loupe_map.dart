import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Picasa-style Loupe Mini-Map overlay.
/// Appears when the image is zoomed in to show the full picture overview and viewport position.
class PicasaLoupeMap extends StatelessWidget {
  const PicasaLoupeMap({
    super.key,
    required this.imagePath,
    required this.scale,
    required this.quarterTurns,
    required this.onResetZoom,
    required this.onClose,
  });

  final String imagePath;
  final double scale;
  final int quarterTurns;
  final VoidCallback onResetZoom;
  final VoidCallback onClose;

  static const double _mapWidth = 160.0;
  static const double _mapHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    // Viewport box dimensions proportional to 1 / scale
    final clampedScale = scale.clamp(1.0, 5.0);
    final boxW = (_mapWidth / clampedScale).clamp(24.0, _mapWidth);
    final boxH = (_mapHeight / clampedScale).clamp(18.0, _mapHeight);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: _mapWidth,
          height: _mapHeight + 28,
          decoration: BoxDecoration(
            color: const Color(0xCC151821),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with Zoom % tag & Close
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'NAVIGATOR ${(scale * 100).round()}%',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ApertixColors.cyanAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onResetZoom,
                      child: Tooltip(
                        message: 'Reset to Fit (0)',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            'FIT',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Thumbnail with Viewport Box
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base thumbnail
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                      child: RotatedBox(
                        quarterTurns: quarterTurns,
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                          cacheWidth: 320,
                          cacheHeight: 200,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, size: 24, color: Colors.white24),
                          ),
                        ),
                      ),
                    ),

                    // Viewport highlight rectangle in center
                    Center(
                      child: Container(
                        width: boxW,
                        height: boxH,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: ApertixColors.cyanAccent.withValues(alpha: 0.9),
                            width: 1.8,
                          ),
                          color: ApertixColors.cyanAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: ApertixColors.cyanAccent.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
