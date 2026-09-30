import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../models/editor_state.dart';
import '../providers/editor_provider.dart';
import '../widgets/crop_overlay.dart';
import '../widgets/filter_preset_list.dart';
import '../widgets/export_dialog.dart';
import '../models/annotation_model.dart';
import '../widgets/annotation_canvas.dart';
import '../widgets/annotation_toolbar.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_background.dart';
import '../../social/widgets/social_hub_dialog.dart';
import '../../analysis/services/histogram_service.dart';
import '../services/auto_enhance_service.dart';

enum _EditorTab { transform, adjust, filters, crop, annotate }

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.filePath});

  final String filePath;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late String _activeFilePath;
  _EditorTab _currentTab = _EditorTab.transform;
  CropAspectRatio _cropRatio = CropAspectRatio.free;
  bool _comparingOriginal = false;
  Size? _imageNaturalSize;

  // Annotations state
  final List<AnnotationItem> _annotations = [];
  AnnotationType _activeAnnotationType = AnnotationType.pen;
  Color _activeAnnotationColor = const Color(0xFFFF4757);
  double _activeAnnotationStrokeWidth = 3.0;

  @override
  void initState() {
    super.initState();
    _activeFilePath = widget.filePath;
    _resolveImageNaturalSize();
  }

  Future<void> _resolveImageNaturalSize() async {
    if (_activeFilePath.isEmpty || !File(_activeFilePath).existsSync()) {
      return;
    }
    try {
      final image = Image.file(File(_activeFilePath));
      image.image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) {
          if (mounted) {
            setState(() {
              _imageNaturalSize = Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              );
            });
          }
        }, onError: (_, __) {}),
      );
    } catch (_) {}
  }

  Future<void> _pickNewImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: SupportedFormats.pickerExtensions,
      dialogTitle: 'Select Image to Edit',
    );
    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      setState(() {
        _activeFilePath = result.files.first.path!;
        _annotations.clear();
      });
      _resolveImageNaturalSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // If no valid image is loaded, render a sleek Glassmorphism Welcome Canvas
    if (_activeFilePath.isEmpty || !File(_activeFilePath).existsSync()) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D0F14) : const Color(0xFFF3F5FA),
        appBar: AppBar(
          backgroundColor: (isDark ? const Color(0xFF13161F) : Colors.white).withValues(alpha: 0.85),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
            tooltip: 'Back to Gallery',
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Photo Editor Studio',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          actions: [
            FilledButton.icon(
              icon: const Icon(Icons.folder_open_rounded, size: 16),
              label: const Text('Open Photo'),
              style: FilledButton.styleFrom(
                backgroundColor: ApertixColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: _pickNewImage,
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: GlassBackground(
          child: Center(
            child: GlassContainer(
              blur: 20,
              opacity: isDark ? 0.08 : 0.85,
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
              margin: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), ApertixColors.cyanAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.tune_rounded, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Spectrum Photo Editor',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Non-destructive color grading, cinematic LUT filters, professional crop aspect ratios, and brush annotations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: const Text('Select Photo to Edit'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ApertixColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 6,
                        shadowColor: ApertixColors.primary.withValues(alpha: 0.5),
                      ),
                      onPressed: _pickNewImage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final editorState = ref.watch(editorProvider(_activeFilePath));
    final notifier = ref.read(editorProvider(_activeFilePath).notifier);

    final params = _comparingOriginal ? const EditorParameters() : editorState.currentParams;
    final colorMatrix = params.calculateColorMatrix();


    return Scaffold(
      backgroundColor: isDark ? ApertixColors.darkBackground : ApertixColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? ApertixColors.darkSurface.withValues(alpha: 0.95)
            : ApertixColors.lightSurface.withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
          tooltip: 'Cancel & Exit',
          onPressed: () => context.pop(),
        ),
        title: Text(
          p.basename(_activeFilePath),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          // Hold to compare
          GestureDetector(
            onTapDown: (_) => setState(() => _comparingOriginal = true),
            onTapUp: (_) => setState(() => _comparingOriginal = false),
            onTapCancel: () => setState(() => _comparingOriginal = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _comparingOriginal
                    ? ApertixColors.primary.withValues(alpha: 0.2)
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _comparingOriginal
                      ? ApertixColors.primary
                      : (isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.compare_rounded,
                    size: 15,
                    color: _comparingOriginal
                        ? ApertixColors.primary
                        : (isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Compare',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _comparingOriginal
                          ? ApertixColors.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Undo
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'Undo',
            color: editorState.canUndo ? Colors.white : Colors.white24,
            onPressed: editorState.canUndo ? notifier.undo : null,
          ),
          // Redo
          IconButton(
            icon: const Icon(Icons.redo_rounded),
            tooltip: 'Redo',
            color: editorState.canRedo ? Colors.white : Colors.white24,
            onPressed: editorState.canRedo ? notifier.redo : null,
          ),
          // Open different image
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            tooltip: 'Open Different Image',
            color: Colors.white70,
            onPressed: _pickNewImage,
          ),
          const SizedBox(width: 6),

          // Social Hub Publish
          OutlinedButton.icon(
            icon: const Icon(Icons.share_rounded, size: 14, color: ApertixColors.cyanAccent),
            label: const Text('Social Hub'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ApertixColors.cyanAccent,
              side: const BorderSide(color: ApertixColors.cyanAccent, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: editorState.isProcessing ? null : () => _handleSocialPublish(editorState, notifier),
          ),
          const SizedBox(width: 8),

          // Save / Export
          FilledButton.icon(
            icon: editorState.isProcessing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 16),
            label: const Text('Export'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: editorState.isProcessing ? null : () => _handleExport(notifier),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Canvas preview area
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    child: Transform.rotate(
                      angle: params.rotationRadians,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(
                          params.flipHorizontal ? -1.0 : 1.0,
                          params.flipVertical ? -1.0 : 1.0,
                          1.0,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.matrix(colorMatrix),
                              child: Image.file(
                                File(_activeFilePath),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.black26,
                                  child: const Center(
                                    child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.white38),
                                  ),
                                ),
                              ),
                            ),
                            if (params.vignette > 0)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        radius: 0.85,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: params.vignette * 0.85),
                                        ],
                                        stops: const [0.4, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Crop overlay mode
                if (_currentTab == _EditorTab.crop && _imageNaturalSize != null)
                  Center(
                    child: CropOverlay(
                      imageSize: _imageNaturalSize!,
                      selectedRatio: _cropRatio,
                      initialCrop: editorState.currentParams.cropRect,
                      onCropChanged: notifier.setCropRect,
                    ),
                  ),

                // Annotation drawing overlay
                if (_currentTab == _EditorTab.annotate)
                  Positioned.fill(
                    child: AnnotationCanvas(
                      annotations: _annotations,
                      activeType: _activeAnnotationType,
                      activeColor: _activeAnnotationColor,
                      activeStrokeWidth: _activeAnnotationStrokeWidth,
                      onAnnotationAdded: (item) => setState(() => _annotations.add(item)),
                    ),
                  )
                else if (_annotations.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnnotationCanvas(
                        annotations: _annotations,
                        activeType: _activeAnnotationType,
                        activeColor: _activeAnnotationColor,
                        activeStrokeWidth: _activeAnnotationStrokeWidth,
                        onAnnotationAdded: (_) {},
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Controls panel
          _buildControlsPanel(context, editorState, notifier),
        ],
      ),
    );
  }

  Widget _buildControlsPanel(
    BuildContext context,
    EditorState editorState,
    EditorNotifier notifier,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ApertixColors.darkSurface : ApertixColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sub-panel for active tool
            Container(
              height: 110,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: switch (_currentTab) {
                _EditorTab.transform => _buildTransformSubpanel(notifier),
                _EditorTab.adjust => _buildAdjustSubpanel(editorState.currentParams, notifier),
                _EditorTab.filters => FilterPresetList(
                    selectedPreset: editorState.currentParams.preset,
                    imageFile: File(widget.filePath),
                    onSelectPreset: notifier.setFilterPreset,
                  ),
                _EditorTab.crop => _buildCropSubpanel(notifier),
                _EditorTab.annotate => AnnotationToolbar(
                    activeType: _activeAnnotationType,
                    activeColor: _activeAnnotationColor,
                    activeStrokeWidth: _activeAnnotationStrokeWidth,
                    canUndo: _annotations.isNotEmpty,
                    onTypeChanged: (t) => setState(() => _activeAnnotationType = t),
                    onColorChanged: (c) => setState(() => _activeAnnotationColor = c),
                    onStrokeWidthChanged: (w) => setState(() => _activeAnnotationStrokeWidth = w),
                    onUndo: () {
                      if (_annotations.isNotEmpty) {
                        setState(() => _annotations.removeLast());
                      }
                    },
                    onClear: () => setState(() => _annotations.clear()),
                  ),
              },
            ),

            Divider(height: 1, color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabButton(_EditorTab.transform, Icons.crop_rotate_rounded, 'Transform', isDark),
                  _buildTabButton(_EditorTab.crop, Icons.crop_rounded, 'Crop', isDark),
                  _buildTabButton(_EditorTab.adjust, Icons.tune_rounded, 'Adjust', isDark),
                  _buildTabButton(_EditorTab.filters, Icons.auto_awesome_rounded, 'Filters', isDark),
                  _buildTabButton(_EditorTab.annotate, Icons.draw_rounded, 'Annotate', isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(_EditorTab tab, IconData icon, String label, bool isDark) {
    final isSelected = _currentTab == tab;

    return InkWell(
      onTap: () => setState(() => _currentTab = tab),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ApertixColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? ApertixColors.primary
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? ApertixColors.primary
                  : (isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? ApertixColors.primary
                    : (isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransformSubpanel(EditorNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionIconButton(
          icon: Icons.rotate_90_degrees_ccw_rounded,
          label: '90° Left',
          onTap: notifier.rotateCounterClockwise,
        ),
        const SizedBox(width: 16),
        _buildActionIconButton(
          icon: Icons.rotate_90_degrees_cw_rounded,
          label: '90° Right',
          onTap: notifier.rotateClockwise,
        ),
        const SizedBox(width: 16),
        _buildActionIconButton(
          icon: Icons.flip_rounded,
          label: 'Flip Horiz.',
          onTap: notifier.toggleFlipHorizontal,
        ),
        const SizedBox(width: 16),
        _buildActionIconButton(
          icon: Icons.swap_vert_rounded,
          label: 'Flip Vert.',
          onTap: notifier.toggleFlipVertical,
        ),
      ],
    );
  }

  Widget _buildCropSubpanel(EditorNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownButton<CropAspectRatio>(
          value: _cropRatio,
          dropdownColor: const Color(0xFF2A2A3E),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: CropAspectRatio.values.map((ratio) {
            return DropdownMenuItem(
              value: ratio,
              child: Text(ratio.label),
            );
          }).toList(),
          onChanged: (ratio) {
            if (ratio != null) {
              setState(() => _cropRatio = ratio);
            }
          },
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Reset Crop'),
          onPressed: () => notifier.setCropRect(null),
        ),
      ],
    );
  }

  Widget _buildAdjustSubpanel(EditorParameters params, EditorNotifier notifier) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // One-Click Smart Auto-Enhance
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () async {
                final hist = await const HistogramService().computeFromFile(widget.filePath);
                final enhanced = const AutoEnhanceService().calculateEnhancement(hist);
                notifier.commitChange((p) => p.copyWith(
                  brightness: enhanced.brightness,
                  contrast: enhanced.contrast,
                  saturation: enhanced.saturation,
                  exposure: enhanced.exposure,
                ));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Auto-Tune applied (Exposure: ${enhanced.exposure > 0 ? '+' : ''}${enhanced.exposure}, Contrast: ${enhanced.contrast > 0 ? '+' : ''}${enhanced.contrast})'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ApertixColors.primary, ApertixColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ApertixColors.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 20),
                    SizedBox(height: 4),
                    Text(
                      'Auto Tune',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildSliderControl(
            label: 'Brightness',
            value: params.brightness,
            min: -1.0,
            max: 1.0,
            onChanged: (v) => notifier.updateParamLive((p) => p.copyWith(brightness: v)),
            onChangeEnd: (v) => notifier.commitChange((p) => p.copyWith(brightness: v)),
          ),
          _buildSliderControl(
            label: 'Contrast',
            value: params.contrast,
            min: -1.0,
            max: 1.0,
            onChanged: (v) => notifier.updateParamLive((p) => p.copyWith(contrast: v)),
            onChangeEnd: (v) => notifier.commitChange((p) => p.copyWith(contrast: v)),
          ),
          _buildSliderControl(
            label: 'Saturation',
            value: params.saturation,
            min: -1.0,
            max: 1.0,
            onChanged: (v) => notifier.updateParamLive((p) => p.copyWith(saturation: v)),
            onChangeEnd: (v) => notifier.commitChange((p) => p.copyWith(saturation: v)),
          ),
          _buildSliderControl(
            label: 'Exposure',
            value: params.exposure,
            min: -1.0,
            max: 1.0,
            onChanged: (v) => notifier.updateParamLive((p) => p.copyWith(exposure: v)),
            onChangeEnd: (v) => notifier.commitChange((p) => p.copyWith(exposure: v)),
          ),
          _buildSliderControl(
            label: 'Vignette',
            value: params.vignette,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => notifier.updateParamLive((p) => p.copyWith(vignette: v)),
            onChangeEnd: (v) => notifier.commitChange((p) => p.copyWith(vignette: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                (value * 100).round().toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? ApertixColors.darkTextPrimary : ApertixColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 140,
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isDark ? ApertixColors.darkTextPrimary : ApertixColors.lightTextPrimary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport(EditorNotifier notifier) async {
    final naturalW = _imageNaturalSize?.width.round() ?? 1920;
    final naturalH = _imageNaturalSize?.height.round() ?? 1080;

    final options = await showDialog<ExportOptions>(
      context: context,
      builder: (ctx) => ExportDialog(originalWidth: naturalW, originalHeight: naturalH),
    );

    if (options == null) return;

    try {
      final savedPath = await notifier.saveImage(
        customOutputPath: options.overwrite ? _activeFilePath : null,
        targetWidth: options.customWidth,
        targetHeight: options.customHeight,
        quality: options.quality,
        annotations: _annotations,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ${p.basename(savedPath)}'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              if (mounted) context.pop(savedPath);
            },
          ),
        ),
      );
      if (mounted) {
        context.pop(savedPath);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _handleSocialPublish(EditorState editorState, EditorNotifier notifier) async {
    String publishPath = _activeFilePath;
    if (_annotations.isNotEmpty || editorState.currentParams.isModified) {
      final naturalW = _imageNaturalSize?.width.round() ?? 1920;
      final naturalH = _imageNaturalSize?.height.round() ?? 1080;
      try {
        publishPath = await notifier.saveImage(
          targetWidth: naturalW,
          targetHeight: naturalH,
          quality: 95,
          annotations: _annotations,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to prepare image: $e')),
        );
        return;
      }
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => SocialHubDialog(imagePath: publishPath),
    );
  }
}
