import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/histogram_data.dart';
import '../providers/histogram_provider.dart';

/// Floating Nordic Glass HUD displaying live RGB and Luminance histograms with clipping alerts.
class HistogramOverlay extends ConsumerWidget {
  const HistogramOverlay({
    super.key,
    required this.filePath,
    this.onClose,
  });

  final String filePath;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histAsync = ref.watch(histogramProvider(filePath));
    final activeChannel = ref.watch(selectedHistogramChannelProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D111A).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: ApertixColors.cyanAccent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'HISTOGRAM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onClose,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Channel Selector Pills
              Row(
                children: HistogramChannel.values.map((channel) {
                  final isSelected = activeChannel == channel;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedHistogramChannelProvider.notifier).state = channel;
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ApertixColors.primary.withValues(alpha: 0.35)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? ApertixColors.cyanAccent.withValues(alpha: 0.6)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              channel.label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Canvas Area
              SizedBox(
                height: 120,
                child: histAsync.when(
                  data: (data) => CustomPaint(
                    painter: _HistogramPainter(
                      data: data,
                      channel: activeChannel,
                    ),
                    size: Size.infinite,
                  ),
                  loading: () => const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(ApertixColors.cyanAccent),
                      ),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Clipping & Exposure Indicators
              if (histAsync.hasValue) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ClippingChip(
                      label: 'Shadows',
                      percent: histAsync.value!.shadowClipPercentage,
                      isClipped: histAsync.value!.hasShadowClipping,
                      clipColor: const Color(0xFF3498DB),
                    ),
                    _ClippingChip(
                      label: 'Highlights',
                      percent: histAsync.value!.highlightClipPercentage,
                      isClipped: histAsync.value!.hasHighlightClipping,
                      clipColor: const Color(0xFFFF4757),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ClippingChip extends StatelessWidget {
  const _ClippingChip({
    required this.label,
    required this.percent,
    required this.isClipped,
    required this.clipColor,
  });

  final String label;
  final double percent;
  final bool isClipped;
  final Color clipColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isClipped ? clipColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isClipped ? clipColor.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isClipped ? clipColor : Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$label: ${percent.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isClipped ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: isClipped ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (isClipped) ...[
            const SizedBox(width: 4),
            Text(
              'CLIP',
              style: TextStyle(
                color: clipColor,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  const _HistogramPainter({
    required this.data,
    required this.channel,
  });

  final HistogramData data;
  final HistogramChannel channel;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.totalPixels == 0) return;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 1; i <= 3; i++) {
      final x = size.width * (i / 4.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final double maxVal = data.maxCount.toDouble();
    if (maxVal <= 0) return;

    void drawCurve(List<int> bins, Color color, {bool filled = false}) {
      final path = Path();
      path.moveTo(0, size.height);

      for (int i = 0; i < 256; i++) {
        final x = (i / 255.0) * size.width;
        final normalized = (bins[i] / maxVal).clamp(0.0, 1.0);
        final y = size.height - (normalized * (size.height - 4));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      if (filled) {
        final fillPath = Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;
        canvas.drawPath(fillPath, fillPaint);
      }

      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawPath(path, strokePaint);
    }

    switch (channel) {
      case HistogramChannel.rgb:
        drawCurve(data.red, const Color(0xFFFF5252).withValues(alpha: 0.75), filled: true);
        drawCurve(data.green, const Color(0xFF2ECC71).withValues(alpha: 0.75), filled: true);
        drawCurve(data.blue, const Color(0xFF3498DB).withValues(alpha: 0.75), filled: true);
        break;
      case HistogramChannel.luminance:
        drawCurve(data.luminance, Colors.white.withValues(alpha: 0.9), filled: true);
        break;
      case HistogramChannel.red:
        drawCurve(data.red, const Color(0xFFFF5252), filled: true);
        break;
      case HistogramChannel.green:
        drawCurve(data.green, const Color(0xFF2ECC71), filled: true);
        break;
      case HistogramChannel.blue:
        drawCurve(data.blue, const Color(0xFF3498DB), filled: true);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.channel != channel;
  }
}
