import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/editor_state.dart';
import '../models/annotation_model.dart';
import '../services/image_processor.dart';

/// Provider family for the editor state keyed by the target file path.
final editorProvider = StateNotifierProvider.autoDispose
    .family<EditorNotifier, EditorState, String>((ref, filePath) {
  return EditorNotifier(filePath);
});

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier(String filePath)
      : super(EditorState(
          filePath: filePath,
          currentParams: const EditorParameters(),
        ));

  static const int _maxHistory = 25;

  void _pushHistory(EditorParameters newParams) {
    if (newParams == state.currentParams) return;
    final updatedUndo = [...state.undoStack, state.currentParams];
    if (updatedUndo.length > _maxHistory) {
      updatedUndo.removeAt(0);
    }
    state = state.copyWith(
      currentParams: newParams,
      undoStack: updatedUndo,
      redoStack: const [], // Cleared on new action
    );
  }

  /// Adjusts individual color parameters without flooding history on every slider drag.
  void updateParamLive(EditorParameters Function(EditorParameters) update) {
    state = state.copyWith(currentParams: update(state.currentParams));
  }

  /// Commits a slider drag release to history.
  void commitChange(EditorParameters Function(EditorParameters) update) {
    final next = update(state.currentParams);
    _pushHistory(next);
  }

  // Transformations
  void rotateClockwise() {
    _pushHistory(state.currentParams.copyWith(
      rotationQuarterTurns: (state.currentParams.rotationQuarterTurns + 1) % 4,
    ));
  }

  void rotateCounterClockwise() {
    _pushHistory(state.currentParams.copyWith(
      rotationQuarterTurns: (state.currentParams.rotationQuarterTurns + 3) % 4,
    ));
  }

  void toggleFlipHorizontal() {
    _pushHistory(state.currentParams.copyWith(
      flipHorizontal: !state.currentParams.flipHorizontal,
    ));
  }

  void toggleFlipVertical() {
    _pushHistory(state.currentParams.copyWith(
      flipVertical: !state.currentParams.flipVertical,
    ));
  }

  void setCropRect(Rect? rect) {
    _pushHistory(state.currentParams.copyWith(
      cropRect: () => rect,
    ));
  }

  void setFilterPreset(FilterPreset preset) {
    _pushHistory(state.currentParams.copyWith(
      preset: preset,
    ));
  }

  void undo() {
    if (!state.canUndo) return;
    final previous = state.undoStack.last;
    final newUndo = state.undoStack.sublist(0, state.undoStack.length - 1);
    final newRedo = [...state.redoStack, state.currentParams];

    state = state.copyWith(
      currentParams: previous,
      undoStack: newUndo,
      redoStack: newRedo,
    );
  }

  void redo() {
    if (!state.canRedo) return;
    final next = state.redoStack.last;
    final newRedo = state.redoStack.sublist(0, state.redoStack.length - 1);
    final newUndo = [...state.undoStack, state.currentParams];

    state = state.copyWith(
      currentParams: next,
      undoStack: newUndo,
      redoStack: newRedo,
    );
  }

  void resetAll() {
    _pushHistory(const EditorParameters());
  }

  /// Exports or overwrites the edited image via background isolate.
  Future<String> saveImage({
    String? customOutputPath,
    int? targetWidth,
    int? targetHeight,
    int quality = 90,
    List<AnnotationItem> annotations = const [],
  }) async {
    state = state.copyWith(isProcessing: true);
    try {
      final outPath = customOutputPath ?? _generateDefaultOutputPath(state.filePath);
      final exportAnnotations = annotations.map((a) {
        return AnnotationExportData(
          typeIndex: a.type.index,
          points: a.points.map((p) => [p.dx, p.dy]).toList(),
          r: (a.color.r * 255).round().clamp(0, 255),
          g: (a.color.g * 255).round().clamp(0, 255),
          b: (a.color.b * 255).round().clamp(0, 255),
          a: (a.color.a * 255).round().clamp(0, 255),
          strokeWidth: a.strokeWidth,
          text: a.text,
          fontSize: a.fontSize,
        );
      }).toList();

      final task = ImageProcessingTask(
        inputPath: state.filePath,
        outputPath: outPath,
        params: state.currentParams,
        annotations: exportAnnotations,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        quality: quality,
      );
      final savedPath = await ImageProcessorService.processAndSave(task);
      return savedPath;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  String _generateDefaultOutputPath(String sourcePath) {
    final dir = p.dirname(sourcePath);
    final name = p.basenameWithoutExtension(sourcePath);
    final ext = p.extension(sourcePath);
    var candidate = p.join(dir, '${name}_edit$ext');
    var counter = 1;
    while (File(candidate).existsSync()) {
      candidate = p.join(dir, '${name}_edit_$counter$ext');
      counter++;
    }
    return candidate;
  }
}
