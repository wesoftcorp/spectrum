import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../models/editor_state.dart';
import '../providers/editor_provider.dart';
import '../widgets/crop_overlay.dart';
import '../widgets/filter_preset_list.dart';
import '../widgets/export_dialog.dart';
import '../models/annotation_model.dart';
import '../widgets/annotation_canvas.dart';
import '../widgets/annotation_toolbar.dart';

enum _EditorTab { transform, adjust, filters, crop, annotate }

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.filePath});

  final String filePath;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
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
    _resolveImageNaturalSize();
  }

  Future<void> _resolveImageNaturalSize() async {
    final image = Image.file(File(widget.filePath));
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
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider(widget.filePath));
    final notifier = ref.read(editorProvider(widget.filePath).notifier);

    final params = _comparingOriginal ? const EditorParameters() : editorState.currentParams;
    final colorMatrix = params.calculateColorMatrix();

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10131E).withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          tooltip: 'Cancel & Exit',
          onPressed: () => context.pop(),
        ),
        title: Text(
          p.basename(widget.filePath),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
                    ? const Color(0xFF00F2FE).withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _comparingOriginal
                      ? const Color(0xFF00F2FE)
                      : Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.compare_rounded,
                    size: 15,
                    color: _comparingOriginal ? const Color(0xFF00F2FE) : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Compare',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _comparingOriginal ? const Color(0xFF00F2FE) : Colors.white,
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
                                File(widget.filePath),
                                fit: BoxFit.contain,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10131E),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
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

            const Divider(height: 1, color: Color(0xFF1F243B)),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabButton(_EditorTab.transform, Icons.crop_rotate_rounded, 'Transform'),
                  _buildTabButton(_EditorTab.crop, Icons.crop_rounded, 'Crop'),
                  _buildTabButton(_EditorTab.adjust, Icons.tune_rounded, 'Adjust'),
                  _buildTabButton(_EditorTab.filters, Icons.auto_awesome_rounded, 'Filters'),
                  _buildTabButton(_EditorTab.annotate, Icons.draw_rounded, 'Annotate'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(_EditorTab tab, IconData icon, String label) {
    final isSelected = _currentTab == tab;

    return InkWell(
      onTap: () => setState(() => _currentTab = tab),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F2FE).withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F2FE).withValues(alpha: 0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF00F2FE) : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF00F2FE) : Colors.white60,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              const SizedBox(width: 6),
              Text(
                (value * 100).round().toString(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
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
        customOutputPath: options.overwrite ? widget.filePath : null,
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
}
