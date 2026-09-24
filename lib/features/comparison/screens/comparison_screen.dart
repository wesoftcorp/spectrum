import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/app_theme.dart';
import '../widgets/split_curtain_viewer.dart';
import '../widgets/side_by_side_viewer.dart';
import '../widgets/difference_viewer.dart';
import '../../analysis/widgets/histogram_overlay.dart';

enum ComparisonMode { curtain, sideBySide, difference }

/// Full-screen professional comparison studio for inspecting two images or Before/After edits.
class ComparisonScreen extends ConsumerStatefulWidget {
  const ComparisonScreen({
    super.key,
    required this.imagePathA,
    required this.imagePathB,
    this.labelA,
    this.labelB,
  });

  final String imagePathA;
  final String imagePathB;
  final String? labelA;
  final String? labelB;

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  late String _pathA;
  late String _pathB;
  late String _labelA;
  late String _labelB;

  ComparisonMode _mode = ComparisonMode.curtain;
  SplitOrientation _orientation = SplitOrientation.horizontal;
  bool _isSyncLocked = true;
  bool _showHistogram = false;
  int _activeHistogramTarget = 0; // 0: Image A, 1: Image B

  @override
  void initState() {
    super.initState();
    _pathA = widget.imagePathA;
    _pathB = widget.imagePathB;
    _labelA = widget.labelA ?? p.basename(_pathA);
    _labelB = widget.labelB ?? p.basename(_pathB);
  }

  void _swapImages() {
    setState(() {
      final tmpPath = _pathA;
      final tmpLabel = _labelA;
      _pathA = _pathB;
      _labelA = _labelB;
      _pathB = tmpPath;
      _labelB = tmpLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
        const SingleActivator(LogicalKeyboardKey.digit1): () => setState(() => _mode = ComparisonMode.curtain),
        const SingleActivator(LogicalKeyboardKey.digit2): () => setState(() => _mode = ComparisonMode.sideBySide),
        const SingleActivator(LogicalKeyboardKey.digit3): () => setState(() => _mode = ComparisonMode.difference),
        const SingleActivator(LogicalKeyboardKey.keyS): _swapImages,
        const SingleActivator(LogicalKeyboardKey.keyH): () => setState(() => _showHistogram = !_showHistogram),
      },
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: isDark ? ApertixColors.darkBackground : ApertixColors.lightBackground,
              body: Stack(
            fit: StackFit.expand,
            children: [
              // Main Comparison Viewport
              Positioned.fill(
                child: switch (_mode) {
                  ComparisonMode.curtain => SplitCurtainViewer(
                      imagePathA: _pathA,
                      imagePathB: _pathB,
                      labelA: _labelA,
                      labelB: _labelB,
                    ),
                  ComparisonMode.sideBySide => SideBySideViewer(
                      imagePathA: _pathA,
                      imagePathB: _pathB,
                      labelA: _labelA,
                      labelB: _labelB,
                      orientation: _orientation,
                      isSyncLocked: _isSyncLocked,
                    ),
                  ComparisonMode.difference => DifferenceViewer(
                      imagePathA: _pathA,
                      imagePathB: _pathB,
                    ),
                },
              ),

              // Top Glass Navigation & Tool Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(context),
              ),

              // Floating Histogram Overlay
              if (_showHistogram)
                Positioned(
                  top: 76,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Target switch: Image A vs Image B
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: (isDark ? ApertixColors.darkSurface : ApertixColors.lightSurface).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _targetChip('Target: $_labelA', 0),
                            const SizedBox(width: 4),
                            _targetChip('Target: $_labelB', 1),
                          ],
                        ),
                      ),
                      HistogramOverlay(
                        filePath: _activeHistogramTarget == 0 ? _pathA : _pathB,
                        onClose: () => setState(() => _showHistogram = false),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  ),
);
  }

  Widget _targetChip(String text, int targetIndex) {
    final isSelected = _activeHistogramTarget == targetIndex;
    return InkWell(
      onTap: () => setState(() => _activeHistogramTarget = targetIndex),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? ApertixColors.primary.withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: (isDark ? ApertixColors.darkSurface : ApertixColors.lightSurface).withValues(alpha: 0.90),
            border: Border(
              bottom: BorderSide(color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder),
            ),
          ),
          child: Row(
            children: [
              // Back Button
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: colorScheme.onSurface),
                tooltip: 'Back (Esc)',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8),

              // Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.compare_rounded, color: ApertixColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'COMPARISON STUDIO',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Mode Segmented Buttons
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modeButton(ComparisonMode.curtain, Icons.splitscreen_rounded, 'Curtain (1)'),
                    _modeButton(ComparisonMode.sideBySide, Icons.view_column_rounded, 'Side-by-Side (2)'),
                    _modeButton(ComparisonMode.difference, Icons.difference_rounded, 'Difference (3)'),
                  ],
                ),
              ),

              const Spacer(),

              // Side-by-Side Controls (Orientation & Sync Lock)
              if (_mode == ComparisonMode.sideBySide) ...[
                IconButton(
                  icon: Icon(
                    _orientation == SplitOrientation.horizontal ? Icons.view_agenda_rounded : Icons.view_column_rounded,
                    size: 18,
                    color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
                  ),
                  tooltip: _orientation == SplitOrientation.horizontal ? 'Vertical Split' : 'Horizontal Split',
                  onPressed: () {
                    setState(() {
                      _orientation = _orientation == SplitOrientation.horizontal
                          ? SplitOrientation.vertical
                          : SplitOrientation.horizontal;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isSyncLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 18,
                    color: _isSyncLocked
                        ? ApertixColors.primary
                        : (isDark ? ApertixColors.darkTextMuted : ApertixColors.lightTextMuted),
                  ),
                  tooltip: _isSyncLocked ? 'Pan/Zoom Sync Locked' : 'Sync Unlocked',
                  onPressed: () => setState(() => _isSyncLocked = !_isSyncLocked),
                ),
                const SizedBox(width: 8),
              ],

              // Swap Images Button
              IconButton(
                icon: Icon(
                  Icons.swap_horiz_rounded,
                  size: 20,
                  color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
                ),
                tooltip: 'Swap A ↔ B (S)',
                onPressed: _swapImages,
              ),

              // Histogram Toggle Button
              IconButton(
                icon: Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: _showHistogram
                      ? ApertixColors.primary
                      : (isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary),
                ),
                tooltip: 'Toggle Histogram (H)',
                onPressed: () => setState(() => _showHistogram = !_showHistogram),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButton(ComparisonMode mode, IconData icon, String label) {
    final isSelected = _mode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _mode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? ApertixColors.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ApertixColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? ApertixColors.primary
                  : (isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? ApertixColors.primary
                    : (isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
