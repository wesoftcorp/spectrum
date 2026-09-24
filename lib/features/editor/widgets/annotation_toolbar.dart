import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/annotation_model.dart';

/// Sub-panel toolbar for managing active annotation tools, colors, stroke widths, and undo.
class AnnotationToolbar extends StatelessWidget {
  const AnnotationToolbar({
    super.key,
    required this.activeType,
    required this.activeColor,
    required this.activeStrokeWidth,
    required this.canUndo,
    required this.onTypeChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onUndo,
    required this.onClear,
  });

  final AnnotationType activeType;
  final Color activeColor;
  final double activeStrokeWidth;
  final bool canUndo;
  final ValueChanged<AnnotationType> onTypeChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  static const List<Color> _palette = [
    Color(0xFFFF4757), // Crimson
    ApertixColors.cyanAccent, // Cyber Cyan
    ApertixColors.secondary, // Neon Mint
    Color(0xFFFFD32A), // Amber
    Colors.white,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Tool selection chips
          _buildToolButton(AnnotationType.pen, Icons.edit_rounded, 'Pen'),
          _buildToolButton(AnnotationType.arrow, Icons.arrow_right_alt_rounded, 'Arrow'),
          _buildToolButton(AnnotationType.rectangle, Icons.crop_square_rounded, 'Rect'),
          _buildToolButton(AnnotationType.circle, Icons.circle_outlined, 'Circle'),
          _buildToolButton(AnnotationType.text, Icons.title_rounded, 'Text'),

          const SizedBox(width: 8),
          Container(width: 1, height: 28, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12),
          const SizedBox(width: 8),

          // Color palette circles
          ..._palette.map((c) {
            final isSelected = activeColor == c;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return GestureDetector(
              onTap: () => onColorChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? ApertixColors.primary : (isDark ? Colors.white24 : Colors.black12),
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 8),
          Container(width: 1, height: 28, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12),
          const SizedBox(width: 8),

          // Stroke widths: 2, 4, 8
          _buildStrokeButton(context, 2.0, '2px'),
          _buildStrokeButton(context, 4.0, '4px'),
          _buildStrokeButton(context, 8.0, '8px'),

          const SizedBox(width: 8),
          Container(width: 1, height: 28, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12),
          const SizedBox(width: 8),

          // Undo annotation
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    tooltip: 'Undo last stroke',
                    color: canUndo
                        ? (isDark ? Colors.white : ApertixColors.lightTextPrimary)
                        : (isDark ? Colors.white24 : Colors.black26),
                    onPressed: canUndo ? onUndo : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    tooltip: 'Clear all annotations',
                    color: canUndo
                        ? (isDark ? Colors.white70 : ApertixColors.lightTextSecondary)
                        : (isDark ? Colors.white24 : Colors.black26),
                    onPressed: canUndo ? onClear : null,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(AnnotationType type, IconData icon, String tooltip) {
    final isSelected = activeType == type;

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: () => onTypeChanged(type),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(7),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? ApertixColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? ApertixColors.primary : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 19,
                color: isSelected
                    ? ApertixColors.primary
                    : (isDark ? Colors.white70 : ApertixColors.lightTextSecondary),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStrokeButton(BuildContext context, double width, String label) {
    final isSelected = activeStrokeWidth == width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onStrokeWidthChanged(width),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.white24 : Colors.black12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? ApertixColors.primary
                : (isDark ? Colors.white70 : ApertixColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
