import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Glassmorphism frosted container with specular highlight edges.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 16.0,
    this.opacity,
    this.border,
    this.gradient,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    this.alignment,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double? opacity;
  final BoxBorder? border;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(16);

    final defaultGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: opacity ?? 0.08),
                  Colors.white.withValues(alpha: (opacity ?? 0.08) * 0.3),
                ]
              : [
                  Colors.white.withValues(alpha: opacity ?? 0.75),
                  Colors.white.withValues(alpha: (opacity ?? 0.75) * 0.5),
                ],
        );

    final defaultBorder = border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.65),
          width: 1.0,
        );

    final defaultShadow = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ];

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: defaultGradient,
        border: defaultBorder,
        boxShadow: defaultShadow,
      ),
      child: child,
    );

    if (blur > 0) {
      content = ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
