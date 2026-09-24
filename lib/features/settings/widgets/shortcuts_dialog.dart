import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Modal displaying comprehensive keyboard shortcuts cheatsheet.
class ShortcutsDialog extends StatelessWidget {
  const ShortcutsDialog({super.key});

  static const List<Map<String, dynamic>> _shortcutGroups = [
    {
      'group': 'NAVIGATION & PLAYBACK',
      'items': [
        {'key': '← / →', 'desc': 'Previous / Next image'},
        {'key': 'Space', 'desc': 'Toggle Slideshow autoplay'},
        {'key': 'T', 'desc': 'Toggle bottom thumbnail filmstrip'},
        {'key': 'Esc', 'desc': 'Return to gallery / Close modal'},
      ],
    },
    {
      'group': 'ZOOM & ORIENTATION',
      'items': [
        {'key': '0', 'desc': 'Reset to 1:1 Actual Size'},
        {'key': '1', 'desc': 'Fit to Screen / 2.5x magnification'},
        {'key': '+ / -', 'desc': 'Smooth zoom in / zoom out'},
        {'key': 'R / L', 'desc': 'Rotate 90° Clockwise / Counter-Clockwise'},
      ],
    },
    {
      'group': 'STUDIO & POWER TOOLS',
      'items': [
        {'key': 'H', 'desc': 'Toggle live RGB & Luminance Histogram HUD'},
        {'key': 'C', 'desc': 'Launch Comparison Studio (Side-by-Side / Curtain)'},
        {'key': 'F', 'desc': 'Toggle Favorite heart bookmark'},
        {'key': 'S', 'desc': 'Open Social Hub Multi-Publisher modal'},
        {'key': 'E', 'desc': 'Open Image Editor Studio'},
        {'key': 'I', 'desc': 'Toggle EXIF Metadata & Camera inspector'},
        {'key': 'F11', 'desc': 'Toggle True Fullscreen'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 620),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? ApertixColors.darkSurface : ApertixColors.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.keyboard_rounded, color: ApertixColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Keyboard Shortcuts',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _shortcutGroups.map((group) {
                        final items = group['items'] as List<Map<String, String>>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group['group'] as String,
                                style: const TextStyle(
                                  color: ApertixColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...items.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.15) : ApertixColors.lightBorder),
                                          ),
                                          child: Text(
                                            item['key']!,
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            item['desc']!,
                                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
