import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/editor_state.dart';

/// Horizontal list of preset filters with visual preview.
class FilterPresetList extends StatelessWidget {
  const FilterPresetList({
    super.key,
    required this.selectedPreset,
    required this.imageFile,
    required this.onSelectPreset,
  });

  final FilterPreset selectedPreset;
  final File imageFile;
  final ValueChanged<FilterPreset> onSelectPreset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: FilterPreset.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final preset = FilterPreset.values[index];
          final isSelected = preset == selectedPreset;
          final previewParams = EditorParameters(preset: preset);
          final matrix = previewParams.calculateColorMatrix();

          return GestureDetector(
            onTap: () => onSelectPreset(preset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix(matrix),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      cacheWidth: 120,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preset.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.primary
                        : (isDark ? Colors.white70 : ApertixColors.lightTextSecondary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
