import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/licensing/widgets/license_dialog.dart';
import '../../../core/licensing/providers/license_provider.dart';
import '../../../data/sources/platform/windows_shell_service.dart';
import '../../../data/sources/local/image_file_service.dart';
import '../providers/gallery_provider.dart';
import '../widgets/image_thumbnail.dart';
import '../../batch/widgets/batch_dialog.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/widgets/album_picker_dialog.dart';
import '../../cloud/widgets/cloud_vault_dialog.dart';

enum _SortOption { nameAsc, nameDesc, dateNewest, dateOldest, sizeLargest }
enum _GridDensity { compact, comfortable, large }

/// Modern Nordic Frost & Cyber Luminescence Gallery Screen with Multi-Selection & Batch Processing.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.dateNewest;
  String _formatFilter = 'ALL';
  bool _favoritesFilter = false;
  _GridDensity _density = _GridDensity.comfortable;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Multi-Selection State
  final Set<String> _selectedPaths = {};
  bool get _isSelectionMode => _selectedPaths.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelect(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _selectAll(List<ImageFile> currentImages) {
    setState(() {
      _selectedPaths.addAll(currentImages.map((e) => e.path));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPaths.clear();
    });
  }

  List<ImageFile> _processImages(List<ImageFile> rawList) {
    var list = List<ImageFile>.from(rawList);

    // Filter by favorites
    if (_favoritesFilter) {
      final favs = ref.watch(favoritesProvider);
      list = list.where((img) => favs.contains(img.path)).toList();
    }

    // Filter by format
    if (_formatFilter != 'ALL') {
      if (_formatFilter == 'RAW') {
        list = list
            .where((img) =>
                ['raw', 'dng', 'nef', 'cr2', 'arw']
                    .contains(img.extension.toLowerCase()))
            .toList();
      } else {
        list = list
            .where((img) =>
                img.extension.toLowerCase() == _formatFilter.toLowerCase())
            .toList();
      }
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((img) => img.name.toLowerCase().contains(q)).toList();
    }

    // Sort
    switch (_sortOption) {
      case _SortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _SortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case _SortOption.dateNewest:
        list.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      case _SortOption.dateOldest:
        list.sort((a, b) => a.modifiedAt.compareTo(b.modifiedAt));
      case _SortOption.sizeLargest:
        list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    }

    return list;
  }

  double _getThumbnailSize() {
    switch (_density) {
      case _GridDensity.compact:
        return 130;
      case _GridDensity.comfortable:
        return 190;
      case _GridDensity.large:
        return 270;
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ApertixColors.darkBackground : ApertixColors.lightBackground,
      appBar: _buildTopAppBar(context, isDark),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              // Sub-header / Status Toolbar
              galleryState.maybeWhen(
                data: (images) => images.isNotEmpty
                    ? _buildStatusToolbar(context, images, isDark)
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),

              // Main content
              Expanded(
                child: galleryState.when(
                  loading: () => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(ApertixColors.cyanAccent),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Indexing images...',
                          style: TextStyle(
                            color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (err, _) => _ErrorView(message: err.toString()),
                  data: (images) {
                    if (images.isEmpty) {
                      return _EmptyState(onPickFolder: _pickFolder);
                    }

                    final processed = _processImages(images);
                    if (processed.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48,
                                color: isDark ? Colors.white30 : Colors.black26),
                            const SizedBox(height: 12),
                            const Text(
                              'No images match the active filters',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                  _formatFilter = 'ALL';
                                });
                              },
                              child: const Text('Reset filters'),
                            ),
                          ],
                        ),
                      );
                    }

                    return _ThumbnailGrid(
                      images: processed,
                      allImages: images,
                      tileSize: _getThumbnailSize(),
                      selectedPaths: _selectedPaths,
                      isSelectionMode: _isSelectionMode,
                      onToggleSelect: _toggleSelect,
                    );
                  },
                ),
              ),
            ],
          ),

          // Floating Batch Selection Dock
          if (_isSelectionMode)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: galleryState.maybeWhen(
                  data: (images) => _buildSelectionDock(_processImages(images), isDark),
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionDock(List<ImageFile> currentImages, bool isDark) {
    final count = _selectedPaths.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: (isDark ? ApertixColors.darkSurfaceElevated : Colors.white).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ApertixColors.primary.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ApertixColors.cyanAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count Selected',
                  style: const TextStyle(
                    color: ApertixColors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Select All / Deselect
              TextButton(
                onPressed: () {
                  if (_selectedPaths.length == currentImages.length) {
                    _clearSelection();
                  } else {
                    _selectAll(currentImages);
                  }
                },
                child: Text(
                  _selectedPaths.length == currentImages.length ? 'Deselect All' : 'Select All',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              // Compare (2) button if exactly 2 images selected
              if (count == 2) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.compare_rounded, size: 16, color: ApertixColors.cyanAccent),
                  label: const Text('Compare (2)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ApertixColors.cyanAccent,
                    side: BorderSide(color: ApertixColors.cyanAccent.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final list = _selectedPaths.toList();
                    context.push('/comparison', extra: {
                      'imagePathA': list[0],
                      'imagePathB': list[1],
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],

              // Launch Batch Processing Studio
              FilledButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: const Text('Batch Process'),
                style: FilledButton.styleFrom(
                  backgroundColor: ApertixColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final changed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => BatchDialog(selectedFilePaths: _selectedPaths.toList()),
                  );
                  if (changed == true && mounted) {
                    _clearSelection();
                    ref.read(galleryProvider.notifier).refresh();
                  }
                },
              ),
              const SizedBox(width: 8),

              // Album assignment button
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('Album'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final albumName = await showDialog<String>(
                    context: context,
                    builder: (_) => AlbumPickerDialog(imagePaths: _selectedPaths.toList()),
                  );
                  if (albumName != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added to "$albumName"')),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),

              // Cloud Vault Backup button
              OutlinedButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined, size: 16, color: ApertixColors.cyanAccent),
                label: const Text('Backup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ApertixColors.cyanAccent,
                  side: BorderSide(color: ApertixColors.cyanAccent.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CloudVaultDialog(filePaths: _selectedPaths.toList()),
                  );
                },
              ),
              const SizedBox(width: 8),

              // Dismiss selection
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white60),
                tooltip: 'Exit Selection',
                onPressed: _clearSelection,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context, bool isDark) {
    final folderPath = ref.watch(currentFolderProvider);
    final folderName = folderPath != null ? p.basename(folderPath) : null;

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? ApertixColors.darkSurface : ApertixColors.lightSurface)
              .withValues(alpha: 0.95),
          border: Border(
            bottom: BorderSide(
              color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Brand Logo Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ApertixColors.cyanAccent, ApertixColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: ApertixColors.primary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.camera_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'APERTIX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Folder crumb pill
                if (folderName != null) ...[
                  Tooltip(
                    message: folderPath!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? ApertixColors.darkCard : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 14,
                            color: isDark ? ApertixColors.cyanAccent : ApertixColors.primary,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              folderName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Search field or search trigger
                if (_isSearching)
                  Container(
                    width: 220,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Filter by filename...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    tooltip: 'Search in folder',
                    onPressed: () => setState(() => _isSearching = true),
                  ),

                // Open Folder CTA
                FilledButton.icon(
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: const Text('Open Folder'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ApertixColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  onPressed: _pickFolder,
                ),
                const SizedBox(width: 8),

                // Open Single File
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  tooltip: 'Open Image File',
                  onPressed: _pickFile,
                ),

                // Apertix Pro License
                IconButton(
                  icon: Icon(
                    ref.watch(isProActiveProvider) ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                    color: ref.watch(isProActiveProvider) ? ApertixColors.secondary : ApertixColors.cyanAccent,
                  ),
                  tooltip: ref.watch(isProActiveProvider) ? 'Apertix Pro Active' : 'Unlock Apertix Pro',
                  onPressed: () => showDialog(context: context, builder: (_) => const LicenseDialog()),
                ),

                // Windows Shell Setup
                if (Platform.isWindows)
                  IconButton(
                    icon: const Icon(Icons.app_registration_rounded),
                    tooltip: 'Windows Default App & Shell Setup',
                    onPressed: _showWindowsShellSetupDialog,
                  ),

                // Settings
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusToolbar(BuildContext context, List<ImageFile> images, bool isDark) {
    final processed = _processImages(images);
    final totalBytes = images.fold<int>(0, (sum, f) => sum + f.sizeBytes);
    final totalSizeLabel = totalBytes < 1024 * 1024
        ? '${(totalBytes / 1024).toStringAsFixed(1)} KB'
        : '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? ApertixColors.darkSurfaceElevated : const Color(0xFFF8FAFC)),
        border: Border(
          bottom: BorderSide(
            color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Counter pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ApertixColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${processed.length} of ${images.length} items • $totalSizeLabel',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? ApertixColors.primaryLight : ApertixColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Format filters
          Wrap(
            spacing: 4,
            children: ['ALL', 'JPG', 'PNG', 'WEBP', 'RAW'].map((fmt) {
              final isSelected = _formatFilter == fmt;
              return InkWell(
                onTap: () => setState(() => _formatFilter = fmt),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ApertixColors.primary.withValues(alpha: isDark ? 0.25 : 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? ApertixColors.primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    fmt,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? ApertixColors.primaryLight : ApertixColors.primary)
                          : (isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),

          // Favorites Filter Pill
          InkWell(
            onTap: () => setState(() => _favoritesFilter = !_favoritesFilter),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _favoritesFilter
                    ? const Color(0xFFFF4757).withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _favoritesFilter ? const Color(0xFFFF4757) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _favoritesFilter ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 13,
                    color: _favoritesFilter ? const Color(0xFFFF4757) : (isDark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'FAVORITES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _favoritesFilter ? FontWeight.w800 : FontWeight.w500,
                      color: _favoritesFilter ? const Color(0xFFFF4757) : (isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Selection Mode Toggle Button
          InkWell(
            onTap: () {
              if (_isSelectionMode) {
                _clearSelection();
              } else {
                _selectAll(processed);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isSelectionMode
                    ? ApertixColors.cyanAccent.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isSelectionMode
                      ? ApertixColors.cyanAccent
                      : (isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    size: 14,
                    color: _isSelectionMode ? ApertixColors.cyanAccent : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isSelectionMode ? 'Cancel Selection' : 'Select',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isSelectionMode ? ApertixColors.cyanAccent : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sort dropdown
          PopupMenuButton<_SortOption>(
            tooltip: 'Sort images',
            initialValue: _sortOption,
            onSelected: (opt) => setState(() => _sortOption = opt),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: _SortOption.dateNewest,
                child: Text('Date: Newest First'),
              ),
              const PopupMenuItem(
                value: _SortOption.dateOldest,
                child: Text('Date: Oldest First'),
              ),
              const PopupMenuItem(
                value: _SortOption.nameAsc,
                child: Text('Name: A to Z'),
              ),
              const PopupMenuItem(
                value: _SortOption.nameDesc,
                child: Text('Name: Z to A'),
              ),
              const PopupMenuItem(
                value: _SortOption.sizeLargest,
                child: Text('Size: Largest First'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sort',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Density toggle
          IconButton(
            icon: Icon(
              _density == _GridDensity.compact
                  ? Icons.grid_view_rounded
                  : (_density == _GridDensity.comfortable
                      ? Icons.grid_4x4_rounded
                      : Icons.photo_size_select_actual_outlined),
              size: 18,
            ),
            tooltip: 'Toggle Grid Size',
            onPressed: () {
              setState(() {
                switch (_density) {
                  case _GridDensity.compact:
                    _density = _GridDensity.comfortable;
                  case _GridDensity.comfortable:
                    _density = _GridDensity.large;
                  case _GridDensity.large:
                    _density = _GridDensity.compact;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickFolder() async {
    final folder = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Image Folder',
    );
    if (folder != null && mounted) {
      _clearSelection();
      ref.read(galleryProvider.notifier).loadFolder(folder);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: SupportedFormats.pickerExtensions,
      dialogTitle: 'Open Image',
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      final path = result.files.first.path!;
      final folder = ref.read(imageFileServiceProvider).folderOf(path);
      final images = await ref.read(imageFileServiceProvider).listImages(folder);
      final index = images.indexWhere((f) => f.path == path);
      if (!mounted) return;
      context.push('/viewer', extra: {
        'filePath': path,
        'fileList': images.map((f) => f.path).toList(),
        'index': index < 0 ? 0 : index,
      });
    }
  }

  Future<void> _showWindowsShellSetupDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.desktop_windows_rounded, color: ApertixColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Windows File Associations', style: TextStyle(color: colorScheme.onSurface, fontSize: 16)),
          ],
        ),
        content: Text(
          'Configure Apertix as your primary image player for JPEG, PNG, WebP, GIF, BMP, RAW, and 80+ media formats.\n\nYou can open Windows Default Apps settings or export a customized registry (.reg) script to your Desktop.',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.file_download_outlined, size: 14),
            label: const Text('Export .reg File'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final path = await WindowsShellService.generateRegistryFile();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Registry file generated: $path')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.settings_rounded, size: 14),
            label: const Text('Open Default Apps'),
            style: FilledButton.styleFrom(backgroundColor: ApertixColors.primary),
            onPressed: () {
              Navigator.of(ctx).pop();
              WindowsShellService.openDefaultAppsSettings();
            },
          ),
        ],
      ),
    );
  }
}

class _ThumbnailGrid extends StatelessWidget {
  const _ThumbnailGrid({
    required this.images,
    required this.allImages,
    required this.tileSize,
    required this.selectedPaths,
    required this.isSelectionMode,
    required this.onToggleSelect,
  });

  final List<ImageFile> images;
  final List<ImageFile> allImages;
  final double tileSize;
  final Set<String> selectedPaths;
  final bool isSelectionMode;
  final void Function(String path) onToggleSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: tileSize,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final img = images[index];
        final globalIndex = allImages.indexWhere((f) => f.path == img.path);
        final isSelected = selectedPaths.contains(img.path);

        return ImageThumbnail(
          imageFile: img,
          isSelected: isSelected,
          isSelectionMode: isSelectionMode,
          onToggleSelect: () => onToggleSelect(img.path),
          onTap: () => context.push('/viewer', extra: {
            'filePath': img.path,
            'fileList': allImages.map((f) => f.path).toList(),
            'index': globalIndex < 0 ? 0 : globalIndex,
          }),
          onQuickEdit: () => context.push('/editor', extra: {'filePath': img.path}),
        ).animate().fadeIn(
              duration: 250.ms,
              delay: (index * 15).clamp(0, 300).ms,
            );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPickFolder});
  final VoidCallback onPickFolder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: isDark ? ApertixColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Aperture Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    ApertixColors.cyanAccent.withValues(alpha: 0.2),
                    ApertixColors.primary.withValues(alpha: 0.2),
                  ],
                ),
                border: Border.all(
                  color: ApertixColors.cyanAccent.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.shutter_speed_rounded,
                  size: 42,
                  color: ApertixColors.cyanAccent,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Apertix Studio',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Ultra-fast, hardware-accelerated image viewer & color grading studio. Select a folder to begin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // Action Button
            FilledButton.icon(
              onPressed: onPickFolder,
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Open Images Folder'),
              style: FilledButton.styleFrom(
                backgroundColor: ApertixColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: ApertixColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Error loading images',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
