// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../models/batch_options.dart';
import '../services/batch_processor.dart';

enum _BatchTab { resize, format, rename, output }

/// Full-featured Nordic Glass Studio modal for batch resizing, format conversion, and template renaming.
class BatchDialog extends StatefulWidget {
  const BatchDialog({
    super.key,
    required this.selectedFilePaths,
  });

  final List<String> selectedFilePaths;

  @override
  State<BatchDialog> createState() => _BatchDialogState();
}

class _BatchDialogState extends State<BatchDialog> {
  _BatchTab _currentTab = _BatchTab.resize;

  // Options
  BatchResizeOptions _resizeOptions = const BatchResizeOptions();
  BatchConvertOptions _convertOptions = const BatchConvertOptions();
  BatchRenameOptions _renameOptions = const BatchRenameOptions();
  String? _customOutputDir;
  bool _overwrite = false;

  // Processing state
  final BatchProcessorService _processor = BatchProcessorService();
  bool _isProcessing = false;
  BatchProgress? _currentProgress;
  BatchSummary? _summary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = widget.selectedFilePaths.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 680,
        height: 600,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F121E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF232A44) : Colors.black12,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header
            _buildHeader(isDark, count),

            // Tab bar
            _buildTabBar(isDark),

            // Body
            Expanded(
              child: _isProcessing
                  ? _buildProcessingView(isDark)
                  : (_summary != null ? _buildSummaryView(isDark) : _buildTabContent(isDark)),
            ),

            // Footer
            _buildFooter(isDark, count),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141829) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF1F243B) : Colors.black12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [ApertixColors.cyanAccent, ApertixColors.primary]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_motion_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Batch Processing Studio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2),
              ),
              Text(
                '$count images queued for processing',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancel',
            onPressed: () {
              if (_isProcessing) _processor.cancel();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    if (_isProcessing || _summary != null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101322) : const Color(0xFFF1F5F9),
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF1F243B) : Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabPill(_BatchTab.resize, Icons.aspect_ratio_rounded, 'Resize & Scale'),
          _buildTabPill(_BatchTab.format, Icons.transform_rounded, 'Format & Quality'),
          _buildTabPill(_BatchTab.rename, Icons.drive_file_rename_outline_rounded, 'Rename Templates'),
          _buildTabPill(_BatchTab.output, Icons.folder_special_rounded, 'Output & Save'),
        ],
      ),
    );
  }

  Widget _buildTabPill(_BatchTab tab, IconData icon, String label) {
    final isSelected = _currentTab == tab;

    return InkWell(
      onTap: () => setState(() => _currentTab = tab),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ApertixColors.cyanAccent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? ApertixColors.cyanAccent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? ApertixColors.cyanAccent : Colors.white60),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? ApertixColors.cyanAccent : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDark) {
    return switch (_currentTab) {
      _BatchTab.resize => _buildResizeTab(isDark),
      _BatchTab.format => _buildFormatTab(isDark),
      _BatchTab.rename => _buildRenameTab(isDark),
      _BatchTab.output => _buildOutputTab(isDark),
    };
  }

  Widget _buildResizeTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        RadioListTile<ResizeMode>(
          title: const Text('Do Not Resize (Keep Original Resolution)'),
          value: ResizeMode.none,
          groupValue: _resizeOptions.mode,
          onChanged: (v) => setState(() => _resizeOptions = _resizeOptions.copyWith(mode: v)),
        ),
        RadioListTile<ResizeMode>(
          title: Text('Scale by Percentage (${_resizeOptions.percentage}%)'),
          subtitle: const Text('Scales all images proportionally by relative factor'),
          value: ResizeMode.percentage,
          groupValue: _resizeOptions.mode,
          onChanged: (v) => setState(() => _resizeOptions = _resizeOptions.copyWith(mode: v)),
        ),
        if (_resizeOptions.mode == ResizeMode.percentage)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Slider(
              value: _resizeOptions.percentage.toDouble(),
              min: 10,
              max: 100,
              divisions: 18,
              label: '${_resizeOptions.percentage}%',
              onChanged: (v) => setState(() => _resizeOptions = _resizeOptions.copyWith(percentage: v.round())),
            ),
          ),
        RadioListTile<ResizeMode>(
          title: Text('Fit Longest Edge (${_resizeOptions.longestEdge} px)'),
          subtitle: const Text('Ideal for web exports, Instagram, and social posting'),
          value: ResizeMode.fitLongestEdge,
          groupValue: _resizeOptions.mode,
          onChanged: (v) => setState(() => _resizeOptions = _resizeOptions.copyWith(mode: v)),
        ),
        if (_resizeOptions.mode == ResizeMode.fitLongestEdge)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildEdgePreset(1080),
                const SizedBox(width: 8),
                _buildEdgePreset(1920),
                const SizedBox(width: 8),
                _buildEdgePreset(2048),
                const SizedBox(width: 8),
                _buildEdgePreset(3840),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEdgePreset(int edge) {
    final isSelected = _resizeOptions.longestEdge == edge;
    return ChoiceChip(
      label: Text('${edge}px'),
      selected: isSelected,
      onSelected: (_) => setState(() => _resizeOptions = _resizeOptions.copyWith(longestEdge: edge)),
    );
  }

  Widget _buildFormatTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        RadioListTile<TargetFormat>(
          title: const Text('Keep Original Format'),
          subtitle: const Text('Images will stay in their current formats (JPG, PNG, etc.)'),
          value: TargetFormat.keepOriginal,
          groupValue: _convertOptions.format,
          onChanged: (v) => setState(() => _convertOptions = _convertOptions.copyWith(format: v)),
        ),
        RadioListTile<TargetFormat>(
          title: const Text('Convert All to JPEG (.jpg)'),
          subtitle: const Text('Maximum compatibility, high compression'),
          value: TargetFormat.jpeg,
          groupValue: _convertOptions.format,
          onChanged: (v) => setState(() => _convertOptions = _convertOptions.copyWith(format: v)),
        ),
        RadioListTile<TargetFormat>(
          title: const Text('Convert All to WebP (.webp)'),
          subtitle: const Text('Modern web standard, 30% smaller than JPEG at equal quality'),
          value: TargetFormat.webp,
          groupValue: _convertOptions.format,
          onChanged: (v) => setState(() => _convertOptions = _convertOptions.copyWith(format: v)),
        ),
        RadioListTile<TargetFormat>(
          title: const Text('Convert All to PNG (.png)'),
          subtitle: const Text('Lossless compression, perfect for screenshots & graphics'),
          value: TargetFormat.png,
          groupValue: _convertOptions.format,
          onChanged: (v) => setState(() => _convertOptions = _convertOptions.copyWith(format: v)),
        ),
        const SizedBox(height: 16),
        if (_convertOptions.format == TargetFormat.jpeg || _convertOptions.format == TargetFormat.webp) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Encoding Quality', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${_convertOptions.quality}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: ApertixColors.cyanAccent)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: _convertOptions.quality.toDouble(),
              min: 30,
              max: 100,
              divisions: 70,
              onChanged: (v) => setState(() => _convertOptions = _convertOptions.copyWith(quality: v.round())),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRenameTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        RadioListTile<RenameMode>(
          title: const Text('Keep Original Filenames'),
          value: RenameMode.keepOriginal,
          groupValue: _renameOptions.mode,
          onChanged: (v) => setState(() => _renameOptions = _renameOptions.copyWith(mode: v)),
        ),
        RadioListTile<RenameMode>(
          title: const Text('Pattern Template (e.g. {name}_{index})'),
          value: RenameMode.template,
          groupValue: _renameOptions.mode,
          onChanged: (v) => setState(() => _renameOptions = _renameOptions.copyWith(mode: v)),
        ),
        if (_renameOptions.mode == RenameMode.template) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Template Pattern',
                hintText: '{name}_{index} or Photo_{date}_{index}',
                helperText: 'Variables: {name}, {index}, {date}',
                isDense: true,
              ),
              controller: TextEditingController(text: _renameOptions.template),
              onChanged: (v) => setState(() => _renameOptions = _renameOptions.copyWith(template: v)),
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Live Preview Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141829) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF1F243B) : Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 14, color: ApertixColors.cyanAccent),
                  SizedBox(width: 6),
                  Text('Live Name Preview (First 3 files)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ...widget.selectedFilePaths.take(3).toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final path = entry.value;
                final newName = _renameOptions.computeNewName(
                  originalPath: path,
                  index: idx,
                  date: DateTime.now(),
                  newExtension: _convertOptions.extension,
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.basename(path),
                          style: const TextStyle(fontSize: 11, color: Colors.white60),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: ApertixColors.cyanAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          newName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutputTab(bool isDark) {
    final first = widget.selectedFilePaths.first;
    final defaultDir = p.join(p.dirname(first), '_processed');
    final activeDir = _customOutputDir ?? defaultDir;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile(
          title: const Text('Overwrite Original Files'),
          subtitle: const Text('Destructive: original files will be replaced permanently'),
          value: _overwrite,
          activeThumbColor: ApertixColors.error,
          onChanged: (v) => setState(() => _overwrite = v),
        ),
        const SizedBox(height: 16),
        if (!_overwrite) ...[
          const Text('Output Directory:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141829) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF1F243B) : Colors.black12),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined, color: ApertixColors.cyanAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activeDir,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final chosen = await FilePicker.platform.getDirectoryPath();
                    if (chosen != null) {
                      setState(() => _customOutputDir = chosen);
                    }
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProcessingView(bool isDark) {
    final progress = _currentProgress;
    final pct = progress?.percentage ?? 0.0;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: pct > 0 ? pct : null,
                strokeWidth: 4,
                valueColor: const AlwaysStoppedAnimation<Color>(ApertixColors.cyanAccent),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Processing Image ${(progress?.current ?? 0) + 1} of ${progress?.total ?? widget.selectedFilePaths.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              progress?.currentFileName ?? '',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: pct,
              backgroundColor: isDark ? const Color(0xFF1F243B) : Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(ApertixColors.cyanAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryView(bool isDark) {
    final s = _summary!;
    final mbSaved = (s.spaceSavedBytes / (1024 * 1024)).toStringAsFixed(1);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0x2200FFA3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: ApertixColors.secondary, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Batch Processing Complete!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.succeeded} succeeded • ${s.failed} failed • took ${s.duration.inSeconds}s',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            if (s.spaceSavedBytes > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Disk space saved: $mbSaved MB',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ApertixColors.secondary),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.folder_open_rounded, size: 16),
              label: const Text('Open Output Folder'),
              onPressed: () {
                launchUrl(Uri.directory(s.outputDirectory));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark, int count) {
    if (_isProcessing) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: OutlinedButton(
          onPressed: () => _processor.cancel(),
          child: const Text('Cancel Processing'),
        ),
      );
    }

    if (_summary != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Done'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141829) : const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF1F243B) : Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count files selected',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: const Text('Start Batch Run'),
                style: FilledButton.styleFrom(
                  backgroundColor: ApertixColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: _runBatch,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runBatch() async {
    setState(() {
      _isProcessing = true;
      _currentProgress = null;
      _summary = null;
    });

    final config = BatchConfig(
      inputPaths: widget.selectedFilePaths,
      outputDirectory: _customOutputDir,
      resizeOptions: _resizeOptions,
      convertOptions: _convertOptions,
      renameOptions: _renameOptions,
      overwriteOriginals: _overwrite,
    );

    final summary = await _processor.process(
      config: config,
      onProgress: (p) {
        if (mounted) setState(() => _currentProgress = p);
      },
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _summary = summary;
      });
    }
  }
}
