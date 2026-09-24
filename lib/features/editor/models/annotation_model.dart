import 'package:flutter/material.dart';

enum AnnotationType {
  pen,
  arrow,
  rectangle,
  circle,
  text,
}

/// Single vector or text annotation item stored in normalized (0.0 to 1.0) coordinates.
class AnnotationItem {
  const AnnotationItem({
    required this.id,
    required this.type,
    required this.points,
    required this.color,
    this.strokeWidth = 3.0,
    this.text,
    this.fontSize = 18.0,
    this.filled = false,
  });

  final String id;
  final AnnotationType type;
  final List<Offset> points; // Normalized (0.0 to 1.0)
  final Color color;
  final double strokeWidth;
  final String? text;
  final double fontSize;
  final bool filled;

  AnnotationItem copyWith({
    String? id,
    AnnotationType? type,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    String? text,
    double? fontSize,
    bool? filled,
  }) {
    return AnnotationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      filled: filled ?? this.filled,
    );
  }
}
