import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum SplitOrientation { horizontal, vertical }

/// Synchronized Dual Viewport for comparing two images with locked pan & zoom.
class SideBySideViewer extends StatefulWidget {
  const SideBySideViewer({
    super.key,
    required this.imagePathA,
    required this.imagePathB,
    this.labelA = 'IMAGE A',
    this.labelB = 'IMAGE B',
    this.orientation = SplitOrientation.horizontal,
    this.isSyncLocked = true,
  });

  final String imagePathA;
  final String imagePathB;
  final String labelA;
  final String labelB;
  final SplitOrientation orientation;
  final bool isSyncLocked;

  @override
  State<SideBySideViewer> createState() => _SideBySideViewerState();
}

class _SideBySideViewerState extends State<SideBySideViewer> {
  late final TransformationController _controllerA;
  late final TransformationController _controllerB;
  bool _updatingFromA = false;
  bool _updatingFromB = false;

  @override
  void initState() {
    super.initState();
    _controllerA = TransformationController();
    _controllerB = TransformationController();

    _controllerA.addListener(_onControllerAChanged);
    _controllerB.addListener(_onControllerBChanged);
  }

  void _onControllerAChanged() {
    if (!widget.isSyncLocked || _updatingFromB) return;
    _updatingFromA = true;
    _controllerB.value = _controllerA.value;
    _updatingFromA = false;
  }

  void _onControllerBChanged() {
    if (!widget.isSyncLocked || _updatingFromA) return;
    _updatingFromB = true;
    _controllerA.value = _controllerB.value;
    _updatingFromB = false;
  }

  @override
  void dispose() {
    _controllerA.removeListener(_onControllerAChanged);
    _controllerB.removeListener(_onControllerBChanged);
    _controllerA.dispose();
    _controllerB.dispose();
    super.dispose();
  }

  void resetZoom() {
    _controllerA.value = Matrix4.identity();
    _controllerB.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final isHorizontal = widget.orientation == SplitOrientation.horizontal;

    final paneA = _buildPane(
      path: widget.imagePathA,
      label: widget.labelA,
      controller: _controllerA,
      accentColor: ApertixColors.cyanAccent,
    );

    final paneB = _buildPane(
      path: widget.imagePathB,
      label: widget.labelB,
      controller: _controllerB,
      accentColor: ApertixColors.secondary,
    );

    return isHorizontal
        ? Row(
            children: [
              Expanded(child: paneA),
              Container(width: 2, color: Colors.white.withValues(alpha: 0.12)),
              Expanded(child: paneB),
            ],
          )
        : Column(
            children: [
              Expanded(child: paneA),
              Container(height: 2, color: Colors.white.withValues(alpha: 0.12)),
              Expanded(child: paneB),
            ],
          );
  }

  Widget _buildPane({
    required String path,
    required String label,
    required TransformationController controller,
    required Color accentColor,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          transformationController: controller,
          minScale: 0.2,
          maxScale: 16.0,
          child: Center(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.6)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
