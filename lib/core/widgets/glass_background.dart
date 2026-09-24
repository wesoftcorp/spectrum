import 'package:flutter/material.dart';

/// Ethereal atmospheric background that provides chromatic light for glassmorphism.
class GlassBackground extends StatelessWidget {
  const GlassBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base solid canvas
          Container(
            color: isDark ? const Color(0xFF0D0F14) : const Color(0xFFF3F5FA),
          ),

          // Luminous Ambient Light Orb: Top-Left (Sky Azure)
          Positioned(
            top: -120,
            left: -80,
            width: 520,
            height: 520,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            const Color(0xFF38BDF8).withValues(alpha: 0.0),
                          ]
                        : [
                            const Color(0xFF60A5FA).withValues(alpha: 0.22),
                            const Color(0xFF60A5FA).withValues(alpha: 0.0),
                          ],
                  ),
                ),
              ),
            ),
          ),

          // Luminous Ambient Light Orb: Center-Right (Deep Violet / Indigo)
          Positioned(
            top: 140,
            right: -100,
            width: 580,
            height: 580,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF6366F1).withValues(alpha: 0.14),
                            const Color(0xFF6366F1).withValues(alpha: 0.0),
                          ]
                        : [
                            const Color(0xFFA78BFA).withValues(alpha: 0.20),
                            const Color(0xFFA78BFA).withValues(alpha: 0.0),
                          ],
                  ),
                ),
              ),
            ),
          ),

          // Luminous Ambient Light Orb: Bottom-Left (Seafoam Teal)
          Positioned(
            bottom: -100,
            left: 200,
            width: 480,
            height: 480,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF2DD4BF).withValues(alpha: 0.10),
                            const Color(0xFF2DD4BF).withValues(alpha: 0.0),
                          ]
                        : [
                            const Color(0xFF5EEAD4).withValues(alpha: 0.18),
                            const Color(0xFF5EEAD4).withValues(alpha: 0.0),
                          ],
                  ),
                ),
              ),
            ),
          ),

          // Child content laid over the ambient light
          child,
        ],
      ),
    );
  }
}
