import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/annotation_model.dart';

/// Interactive drawing & shape canvas for image annotations.
class AnnotationCanvas extends StatefulWidget {
  const AnnotationCanvas({
    super.key,
    required this.annotations,
    required this.activeType,
    required this.activeColor,
    required this.activeStrokeWidth,
    required this.onAnnotationAdded,
  });

  final List<AnnotationItem> annotations;
  final AnnotationType activeType;
  final Color activeColor;
  final double activeStrokeWidth;
  final ValueChanged<AnnotationItem> onAnnotationAdded;

  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  final List<Offset> _currentPoints = [];

  void _onPanStart(DragStartDetails details, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final normalized = Offset(
      (details.localPosition.dx / size.width).clamp(0.0, 1.0),
      (details.localPosition.dy / size.height).clamp(0.0, 1.0),
    );
    setState(() {
      _currentPoints.clear();
      _currentPoints.add(normalized);
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final normalized = Offset(
      (details.localPosition.dx / size.width).clamp(0.0, 1.0),
      (details.localPosition.dy / size.height).clamp(0.0, 1.0),
    );

    setState(() {
      if (widget.activeType == AnnotationType.pen) {
        _currentPoints.add(normalized);
      } else {
        // Arrow, rectangle, circle only keep start & current end
        if (_currentPoints.isEmpty) {
          _currentPoints.add(normalized);
        } else if (_currentPoints.length == 1) {
          _currentPoints.add(normalized);
        } else {
          _currentPoints[1] = normalized;
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPoints.length >= 2 ||
        (widget.activeType == AnnotationType.pen && _currentPoints.isNotEmpty)) {
      final item = AnnotationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: widget.activeType,
        points: List.from(_currentPoints),
        color: widget.activeColor,
        strokeWidth: widget.activeStrokeWidth,
      );
      widget.onAnnotationAdded(item);
    }
    setState(() {
      _currentPoints.clear();
    });
  }

  Future<void> _onTapUp(TapUpDetails details, Size size) async {
    if (widget.activeType != AnnotationType.text) return;

    final normalized = Offset(
      (details.localPosition.dx / size.width).clamp(0.0, 1.0),
      (details.localPosition.dy / size.height).clamp(0.0, 1.0),
    );

    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141829),
        title: const Text('Add Text Annotation', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter callout text...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (text != null && text.isNotEmpty) {
      final item = AnnotationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: AnnotationType.text,
        points: [normalized],
        color: widget.activeColor,
        strokeWidth: widget.activeStrokeWidth,
        text: text,
      );
      widget.onAnnotationAdded(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanStart: (d) => _onPanStart(d, size),
          onPanUpdate: (d) => _onPanUpdate(d, size),
          onPanEnd: _onPanEnd,
          onTapUp: (d) => _onTapUp(d, size),
          child: CustomPaint(
            size: size,
            painter: _AnnotationPainter(
              annotations: widget.annotations,
              currentPoints: _currentPoints,
              activeType: widget.activeType,
              activeColor: widget.activeColor,
              activeStrokeWidth: widget.activeStrokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  const _AnnotationPainter({
    required this.annotations,
    required this.currentPoints,
    required this.activeType,
    required this.activeColor,
    required this.activeStrokeWidth,
  });

  final List<AnnotationItem> annotations;
  final List<Offset> currentPoints;
  final AnnotationType activeType;
  final Color activeColor;
  final double activeStrokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw committed annotations
    for (final item in annotations) {
      _drawItem(canvas, size, item);
    }

    // 2. Draw live stroke
    if (currentPoints.isNotEmpty) {
      final liveItem = AnnotationItem(
        id: 'live',
        type: activeType,
        points: currentPoints,
        color: activeColor,
        strokeWidth: activeStrokeWidth,
      );
      _drawItem(canvas, size, liveItem);
    }
  }

  void _drawItem(Canvas canvas, Size size, AnnotationItem item) {
    if (item.points.isEmpty) return;

    final paint = Paint()
      ..color = item.color
      ..strokeWidth = item.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final denormalized = item.points
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

    switch (item.type) {
      case AnnotationType.pen:
        if (denormalized.length == 1) {
          canvas.drawCircle(denormalized.first, item.strokeWidth / 2, paint..style = PaintingStyle.fill);
        } else {
          final path = Path()..moveTo(denormalized.first.dx, denormalized.first.dy);
          for (int i = 1; i < denormalized.length; i++) {
            path.lineTo(denormalized[i].dx, denormalized[i].dy);
          }
          canvas.drawPath(path, paint);
        }
        break;

      case AnnotationType.arrow:
        if (denormalized.length >= 2) {
          final start = denormalized[0];
          final end = denormalized[1];
          canvas.drawLine(start, end, paint);

          // Arrow head
          final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
          const arrowLength = 16.0;
          const arrowAngle = math.pi / 6;

          final path = Path()
            ..moveTo(end.dx, end.dy)
            ..lineTo(
              end.dx - arrowLength * math.cos(angle - arrowAngle),
              end.dy - arrowLength * math.sin(angle - arrowAngle),
            )
            ..moveTo(end.dx, end.dy)
            ..lineTo(
              end.dx - arrowLength * math.cos(angle + arrowAngle),
              end.dy - arrowLength * math.sin(angle + arrowAngle),
            );

          canvas.drawPath(path, paint);
        }
        break;

      case AnnotationType.rectangle:
        if (denormalized.length >= 2) {
          final rect = Rect.fromPoints(denormalized[0], denormalized[1]);
          canvas.drawRect(rect, paint);
        }
        break;

      case AnnotationType.circle:
        if (denormalized.length >= 2) {
          final rect = Rect.fromPoints(denormalized[0], denormalized[1]);
          canvas.drawOval(rect, paint);
        }
        break;

      case AnnotationType.text:
        if (item.text != null && denormalized.isNotEmpty) {
          final pos = denormalized.first;
          final span = TextSpan(
            text: item.text,
            style: TextStyle(
              color: item.color,
              fontSize: item.fontSize,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.black.withValues(alpha: 0.6),
            ),
          );
          final textPainter = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(canvas, pos);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}
