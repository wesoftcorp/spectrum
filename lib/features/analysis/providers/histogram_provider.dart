import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/histogram_data.dart';
import '../services/histogram_service.dart';

enum HistogramChannel {
  rgb('RGB', 'Combined RGB curves'),
  luminance('LUM', 'Perceived Luminance'),
  red('R', 'Red Channel'),
  green('G', 'Green Channel'),
  blue('B', 'Blue Channel');

  const HistogramChannel(this.label, this.description);
  final String label;
  final String description;
}

final histogramServiceProvider = Provider<HistogramService>((ref) {
  return const HistogramService();
});

final selectedHistogramChannelProvider = StateProvider<HistogramChannel>((ref) {
  return HistogramChannel.rgb;
});

final histogramProvider = FutureProvider.family<HistogramData, String>((ref, filePath) async {
  if (filePath.isEmpty) {
    return HistogramData.empty();
  }
  final service = ref.watch(histogramServiceProvider);
  return service.computeFromFile(filePath);
});
