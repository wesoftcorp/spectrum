import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/image_metadata.dart';
import '../providers/metadata_provider.dart';
import '../services/metadata_service.dart';

/// Slide-over metadata inspector drawer displaying EXIF, camera, GPS, and raw tags.
class MetadataDrawer extends ConsumerWidget {
  const MetadataDrawer({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataAsync = ref.watch(imageMetadataProvider(filePath));

    return Drawer(
      width: 380,
      backgroundColor: const Color(0xFF0F121D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 18,
                      color: Color(0xFF00F2FE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'EXIF & Image Inspector',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF1F243B)),

            // Content
            Expanded(
              child: metadataAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F2FE)),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to read EXIF: $err', style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),
                data: (meta) => _buildMetadataList(context, ref, meta),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataList(BuildContext context, WidgetRef ref, ImageMetadata meta) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Camera Exposure HUD Card
        if (meta.hasExposureInfo) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF15192B), Color(0xFF1A1F36)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF293252), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meta.cameraModel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_camera_rounded, size: 14, color: Color(0xFF00F2FE)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            meta.cameraModel!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHudMetric('SHUTTER', meta.shutterSpeed != null ? '${meta.shutterSpeed}s' : '—'),
                    _buildHudMetric('APERTURE', meta.aperture != null ? 'ƒ/${meta.aperture}' : '—'),
                    _buildHudMetric('ISO', meta.iso ?? '—'),
                    _buildHudMetric('FOCAL', meta.focalLength != null ? '${meta.focalLength}mm' : '—'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // File Overview
        _buildSectionHeader('File Properties'),
        _buildMetaTile('Name', p.basename(meta.filePath)),
        _buildMetaTile('Size', meta.formattedFileSize),
        if (meta.dimensions != null) _buildMetaTile('Dimensions', meta.dimensions!),
        _buildMetaTile('Modified', meta.lastModified.toString().split('.')[0]),
        const SizedBox(height: 16),

        // Camera Details
        if (meta.hasCameraInfo) ...[
          _buildSectionHeader('Camera & Equipment'),
          if (meta.cameraMake != null) _buildMetaTile('Make', meta.cameraMake!),
          if (meta.cameraModel != null) _buildMetaTile('Model', meta.cameraModel!),
          if (meta.lensModel != null) _buildMetaTile('Lens', meta.lensModel!),
          if (meta.software != null) _buildMetaTile('Software', meta.software!),
          const SizedBox(height: 16),
        ],

        // Location / GPS
        if (meta.hasGps) ...[
          _buildSectionHeader('GPS Location'),
          _buildMetaTile('Coordinates', '${meta.gpsLatitude!.toStringAsFixed(6)}, ${meta.gpsLongitude!.toStringAsFixed(6)}'),
          if (meta.gpsAltitude != null) _buildMetaTile('Altitude', '${meta.gpsAltitude!.toStringAsFixed(1)} m'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.shield_outlined, size: 16),
            label: const Text('Strip GPS & Privacy Tags'),
            onPressed: () => _stripMetadata(context, ref),
          ),
          const SizedBox(height: 16),
        ],

        // Raw EXIF Tags
        if (meta.rawTags.isNotEmpty) ...[
          _buildSectionHeader('All EXIF Tags (${meta.rawTags.length})'),
          ...meta.rawTags.entries.take(30).map((e) => _buildMetaTile(e.key, e.value)),
        ],
      ],
    );
  }

  Widget _buildHudMetric(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF00F2FE),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12, width: 0.5),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF00F2FE),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMetaTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _stripMetadata(BuildContext context, WidgetRef ref) async {
    try {
      await MetadataService.stripExif(filePath);
      ref.invalidate(imageMetadataProvider(filePath));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('EXIF & GPS metadata stripped successfully!')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to strip metadata: $e')),
      );
    }
  }
}
