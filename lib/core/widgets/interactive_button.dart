import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Physics-inspired interactive button with fluid spring scaling, press compression,
/// and luminous hover glow.
class InteractiveMotionButton extends StatefulWidget {
  const InteractiveMotionButton({
    super.key,
    required this.child,
    required this.onTap,
    this.tooltip,
    this.scaleOnHover = 1.06,
    this.scaleOnPress = 0.94,
    this.glowColor,
    this.borderRadius = 12.0,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.isActive = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final double scaleOnHover;
  final double scaleOnPress;
  final Color? glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool isActive;

  @override
  State<InteractiveMotionButton> createState() => _InteractiveMotionButtonState();
}

class _InteractiveMotionButtonState extends State<InteractiveMotionButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGlowColor = widget.glowColor ?? ApertixColors.cyanAccent;

    double scale = 1.0;
    if (_isPressed) {
      scale = widget.scaleOnPress;
    } else if (_isHovered) {
      scale = widget.scaleOnHover;
    }

    Widget content = AnimatedScale(
      scale: scale,
      duration: Duration(milliseconds: _isPressed ? 100 : 200),
      curve: _isPressed ? Curves.easeInQuad : Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.borderColor != null
              ? Border.all(
                  color: _isHovered || widget.isActive
                      ? effectiveGlowColor.withValues(alpha: 0.8)
                      : widget.borderColor!,
                  width: widget.borderWidth,
                )
              : null,
          boxShadow: [
            if (_isHovered || widget.isActive)
              BoxShadow(
                color: effectiveGlowColor.withValues(alpha: isDark ? 0.35 : 0.20),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: widget.child,
      ),
    );

    if (widget.tooltip != null) {
      content = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 400),
        child: content,
      );
    }

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: content,
      ),
    );
  }
}

/// Sleek Spectrum Icon Button with glowing spring hover and micro-feedback.
class SpectrumIconButton extends StatelessWidget {
  const SpectrumIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 20.0,
    this.padding = const EdgeInsets.all(8.0),
    this.color,
    this.hoverColor,
    this.backgroundColor,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? hoverColor;
  final Color? backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white70 : Colors.black87;
    final activeColor = color ?? defaultColor;

    return InteractiveMotionButton(
      onTap: onPressed,
      tooltip: tooltip,
      padding: padding,
      backgroundColor: backgroundColor ?? (isActive ? ApertixColors.primary.withValues(alpha: 0.2) : Colors.transparent),
      glowColor: hoverColor ?? ApertixColors.cyanAccent,
      borderRadius: 10,
      isActive: isActive,
      child: Icon(
        icon,
        size: size,
        color: isActive ? (hoverColor ?? ApertixColors.cyanAccent) : activeColor,
      ),
    );
  }
}

/// Shimmering Gradient CTA button with luminous pulse and spring click.
class SpectrumGradientButton extends StatelessWidget {
  const SpectrumGradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.gradientColors,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final List<Color>? gradientColors;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        const [
          ApertixColors.primary,
          ApertixColors.secondary,
        ];

    return InteractiveMotionButton(
      onTap: onPressed,
      tooltip: tooltip,
      scaleOnHover: 1.04,
      glowColor: colors.first,
      borderRadius: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
