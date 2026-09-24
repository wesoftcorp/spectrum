import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Floating Glass Animation Player Control Bar for Animated GIFs and WebPs.
class AnimationControlsBar extends StatelessWidget {
  const AnimationControlsBar({
    super.key,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.onTogglePlayPause,
    required this.onSpeedChanged,
    this.onStepForward,
    this.onStepBackward,
  });

  final bool isPlaying;
  final double playbackSpeed;
  final VoidCallback onTogglePlayPause;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback? onStepForward;
  final VoidCallback? onStepBackward;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF101322).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ApertixColors.warning.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ApertixColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.animation_rounded, size: 12, color: ApertixColors.warning),
                    SizedBox(width: 4),
                    Text(
                      'ANIMATED',
                      style: TextStyle(
                        color: ApertixColors.warning,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Step Backward (if supported)
              if (onStepBackward != null)
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 18, color: Colors.white70),
                  tooltip: 'Previous Frame',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onStepBackward,
                ),

              // Play / Pause
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  size: 24,
                  color: ApertixColors.cyanAccent,
                ),
                tooltip: isPlaying ? 'Pause Animation' : 'Play Animation',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onTogglePlayPause,
              ),

              // Step Forward (if supported)
              if (onStepForward != null)
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 18, color: Colors.white70),
                  tooltip: 'Next Frame',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onStepForward,
                ),

              const SizedBox(width: 6),
              Container(width: 1, height: 16, color: Colors.white24),
              const SizedBox(width: 8),

              // Speed selector
              PopupMenuButton<double>(
                tooltip: 'Playback Speed',
                initialValue: playbackSpeed,
                onSelected: onSpeedChanged,
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 0.5, child: Text('0.5x Slow')),
                  const PopupMenuItem(value: 1.0, child: Text('1.0x Normal')),
                  const PopupMenuItem(value: 1.5, child: Text('1.5x Fast')),
                  const PopupMenuItem(value: 2.0, child: Text('2.0x Double')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${playbackSpeed}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
