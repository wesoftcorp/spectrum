import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_background.dart';
import '../../../core/licensing/widgets/license_dialog.dart';
import '../../../core/licensing/providers/license_provider.dart';
import '../../../data/sources/platform/windows_shell_service.dart';
import '../../../data/sources/local/image_file_service.dart';
import '../providers/gallery_provider.dart';
import '../widgets/image_thumbnail.dart';
import '../widgets/studio_sidebar.dart';
import '../../batch/widgets/batch_dialog.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/models/album.dart';
import '../../collections/widgets/album_picker_dialog.dart';
import '../../cloud/widgets/cloud_vault_dialog.dart';
import '../../social/widgets/social_hub_dialog.dart';

enum _SortOption { nameAsc, nameDesc, dateNewest, dateOldest, sizeLargest }
enum _GridDensity { compact, comfortable, large }

/// Modern Glassmorphism & High-Tech Studio Gallery Screen with Pro Feature Rail.
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
  String? _activeAlbumId;
  bool _isSidebarCollapsed = false;
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

  List<ImageFile> _processImages(
    List<ImageFile> rawList,
    Set<String> favorites,
    List<Album> albums,
  ) {
    var list = List<ImageFile>.from(rawList);

    // Filter by active virtual album
    if (_activeAlbumId != null) {
      final activeAlbum = albums.where((a) => a.id == _activeAlbumId).firstOrNull;
      if (activeAlbum != null) {
        final albumPaths = activeAlbum.imagePaths.toSet();
        list = list.where((img) => albumPaths.contains(img.path)).toList();
      }
    }

    // Filter by favorites
    if (_favoritesFilter) {
      list = list.where((img) => favorites.contains(img.path)).toList();
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
    final currentFolder = ref.watch(currentFolderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorites = ref.watch(favoritesProvider);
    final albums = ref.watch(albumsProvider);

    final activeAlbum = _activeAlbumId != null
        ? albums.where((a) => a.id == _activeAlbumId).firstOrNull
        : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0F14) : const Color(0xFFF3F5FA),
      body: GlassBackground(
        child: Row(
          children: [
            // Glass Studio Sidebar on the left
            StudioSidebar(
              totalImagesCount: galleryState.maybeWhen(
                data: (imgs) => imgs.length,
                orElse: () => 0,
              ),
              currentFolder: currentFolder,
              isFavoritesActive: _favoritesFilter,
              activeAlbumId: _activeAlbumId,
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
              onShowAllPhotos: () {
                setState(() {
                  _favoritesFilter = false;
                  _activeAlbumId = null;
                });
              },
              onToggleFavorites: () {
                setState(() {
                  _favoritesFilter = !_favoritesFilter;
                  _activeAlbumId = null;
                });
              },
              onSelectAlbum: (albumId) {
                setState(() {
                  _activeAlbumId = albumId;
                  _favoritesFilter = false;
                });
              },
              onPickFolder: _pickFolder,
              onPickFile: _pickFile,
              onOpenBatchStudio: () {
                galleryState.whenData((images) {
                  if (images.isNotEmpty) {
                    final targetPaths = _isSelectionMode
                        ? _selectedPaths.toList()
                        : images.map((f) => f.path).toList();
                    showDialog(
                      context: context,
                      builder: (_) => BatchDialog(selectedFilePaths: targetPaths),
                    );
                  }
                });
              },
              onOpenComparisonStudio: () {
                galleryState.whenData((images) {
                  if (images.length >= 2) {
                    final selected = images.where((f) => _selectedPaths.contains(f.path)).toList();
                    final pathA = selected.isNotEmpty ? selected[0].path : images[0].path;
                    final pathB = selected.length >= 2 ? selected[1].path : images[1].path;
                    context.push('/comparison', extra: {'imagePathA': pathA, 'imagePathB': pathB});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('At least 2 images are required in folder to compare')),
                    );
                  }
                });
              },
              onOpenCloudVault: () {
                galleryState.whenData((images) {
                  final targetPaths = _isSelectionMode
                      ? _selectedPaths.toList()
                      : images.map((f) => f.path).toList();
                  showDialog(
                    context: context,
                    builder: (_) => CloudVaultDialog(filePaths: targetPaths),
                  );
                });
              },
              onOpenWindowsShell: _showWindowsShellSetupDialog,
              onOpenPhotoEditor: () => _openPhotoEditor(),
              onOpenSocialHub: () => _openSocialHub(),
            ),

            // Main Studio Content Area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    children: [
                      // Top Frosted Glass App Bar
                      _buildTopAppBar(context, isDark, activeAlbum: activeAlbum),

                      // Status & Filter Toolbar
                      galleryState.maybeWhen(
                        data: (images) => images.isNotEmpty
                            ? _buildStatusToolbar(context, images, isDark, favorites, albums)
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),

                      // Main Image Grid Area
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

                            final processed = _processImages(images, favorites, albums);
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
                                          _favoritesFilter = false;
                                          _activeAlbumId = null;
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
                          data: (images) => _buildSelectionDock(_processImages(images, favorites, albums), isDark),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
            color: (isDark ? const Color(0xFF141722) : Colors.white).withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.75),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
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

  Widget _buildTopAppBar(BuildContext context, bool isDark, {Album? activeAlbum}) {
    final folderPath = ref.watch(currentFolderProvider);
    final folderName = folderPath != null ? p.basename(folderPath) : null;
    final isPro = ref.watch(isProActiveProvider);

    String currentContextTitle = 'Library';
    IconData currentContextIcon = Icons.photo_library_outlined;
    if (activeAlbum != null) {
      currentContextTitle = 'Album: ${activeAlbum.name}';
      currentContextIcon = Icons.collections_bookmark_rounded;
    } else if (_favoritesFilter) {
      currentContextTitle = 'Favorites';
      currentContextIcon = Icons.favorite_rounded;
    } else if (folderName != null) {
      currentContextTitle = folderName;
      currentContextIcon = Icons.folder_outlined;
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF13161F) : Colors.white).withValues(alpha: 0.70),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final isNarrow = availableWidth < 680;
                final isUltraNarrow = availableWidth < 460;

                return Row(
                  children: [
                    // If sidebar is collapsed, show quick toggle
                    if (_isSidebarCollapsed) ...[
                      IconButton(
                        icon: const Icon(Icons.menu_rounded, size: 20),
                        tooltip: 'Expand Studio Rail',
                        onPressed: () => setState(() => _isSidebarCollapsed = false),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Current Context Pill (Breadcrumb)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isUltraNarrow ? 120 : (isNarrow ? 170 : 280)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              currentContextIcon,
                              size: 15,
                              color: _favoritesFilter
                                  ? const Color(0xFFFF4757)
                                  : (isDark ? ApertixColors.cyanAccent : ApertixColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                currentContextTitle,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            if (activeAlbum != null || _favoritesFilter) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _activeAlbumId = null;
                                    _favoritesFilter = false;
                                  });
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Spacer expands dynamically across all window sizes,
                    // keeping right action icons docked cleanly to the far right edge!
                    const Spacer(),

                    // Action tools (float dynamically according to screen size)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search field or search trigger
                        if (_isSearching)
                          Container(
                            width: isNarrow ? 130 : 200,
                            height: 36,
                            margin: const EdgeInsets.only(right: 8),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Filter...',
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
                        if (!isUltraNarrow)
                          FilledButton.icon(
                            icon: const Icon(Icons.folder_open_rounded, size: 16),
                            label: Text(isNarrow ? 'Folder' : 'Open Folder'),
                            style: FilledButton.styleFrom(
                              backgroundColor: ApertixColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 14, vertical: 10),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            onPressed: _pickFolder,
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.folder_open_rounded),
                            tooltip: 'Open Folder',
                            onPressed: _pickFolder,
                          ),
                        const SizedBox(width: 4),

                        // Open Single File (direct button on wider screens)
                        if (!isUltraNarrow)
                          IconButton(
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            tooltip: 'Open Image File',
                            onPressed: _pickFile,
                          ),

                        // Apertix Pro License Status
                        IconButton(
                          icon: Icon(
                            isPro ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                            color: isPro ? ApertixColors.secondary : ApertixColors.cyanAccent,
                          ),
                          tooltip: isPro ? 'Apertix Pro Active' : 'Unlock Apertix Pro',
                          onPressed: () => showDialog(context: context, builder: (_) => const LicenseDialog()),
                        ),

                        // Windows Shell Setup (collapses into more menu on narrow viewports)
                        if (Platform.isWindows && !isNarrow)
                          IconButton(
                            icon: const Icon(Icons.desktop_windows_rounded),
                            tooltip: 'Windows Default App & Shell Setup',
                            onPressed: _showWindowsShellSetupDialog,
                          ),

                        // Settings
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: 'Settings',
                          onPressed: () => context.push('/settings'),
                        ),

                        // Responsive dropdown menu for compact viewports
                        if (isNarrow)
                          PopupMenuButton<String>(
                            tooltip: 'More actions',
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (val) {
                              if (val == 'file') _pickFile();
                              if (val == 'windows') _showWindowsShellSetupDialog();
                              if (val == 'editor') _openPhotoEditor();
                              if (val == 'social') _openSocialHub();
                            },
                            itemBuilder: (ctx) => [
                              if (isUltraNarrow)
                                const PopupMenuItem(
                                  value: 'file',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 18),
                                      SizedBox(width: 10),
                                      Text('Open Image File'),
                                    ],
                                  ),
                                ),
                              if (Platform.isWindows)
                                const PopupMenuItem(
                                  value: 'windows',
                                  child: Row(
                                    children: [
                                      Icon(Icons.desktop_windows_rounded, size: 18),
                                      SizedBox(width: 10),
                                      Text('Windows Shell Setup'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'editor',
                                child: Row(
                                  children: [
                                    Icon(Icons.tune_rounded, size: 18),
                                    SizedBox(width: 10),
                                    Text('Photo Editor'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'social',
                                child: Row(
                                  children: [
                                    Icon(Icons.share_rounded, size: 18),
                                    SizedBox(width: 10),
                                    Text('Social Hub'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusToolbar(
    BuildContext context,
    List<ImageFile> images,
    bool isDark,
    Set<String> favorites,
    List<Album> albums,
  ) {
    final processed = _processImages(images, favorites, albums);
    final totalBytes = images.fold<int>(0, (sum, f) => sum + f.sizeBytes);
    final totalSizeLabel = totalBytes < 1024 * 1024
        ? '${(totalBytes / 1024).toStringAsFixed(1)} KB'
        : '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF141722) : Colors.white).withValues(alpha: 0.65),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                onTap: () => setState(() {
                  _favoritesFilter = !_favoritesFilter;
                  _activeAlbumId = null;
                }),
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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  _density == _GridDensity.compact
                      ? Icons.grid_view_rounded
                      : (_density == _GridDensity.comfortable
                          ? Icons.view_comfy_rounded
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
        ),
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

  Future<void> _openPhotoEditor([String? path]) async {
    String? targetPath = path;
    if (targetPath == null && _selectedPaths.isNotEmpty) {
      targetPath = _selectedPaths.first;
    } else if (targetPath == null) {
      final galleryState = ref.read(galleryProvider);
      final images = galleryState.maybeWhen(data: (imgs) => imgs, orElse: () => <ImageFile>[]);
      if (images.isNotEmpty) {
        targetPath = images.first.path;
      }
    }

    if (targetPath == null) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: SupportedFormats.pickerExtensions,
        dialogTitle: 'Select Image to Edit',
      );
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        targetPath = result.files.first.path;
      }
    }

    if (mounted) {
      context.push('/editor', extra: {'filePath': targetPath ?? ''});
    }
  }

  Future<void> _openSocialHub([String? path]) async {
    String? targetPath = path;
    if (targetPath == null && _selectedPaths.isNotEmpty) {
      targetPath = _selectedPaths.first;
    } else if (targetPath == null) {
      final galleryState = ref.read(galleryProvider);
      final images = galleryState.maybeWhen(data: (imgs) => imgs, orElse: () => <ImageFile>[]);
      if (images.isNotEmpty) {
        targetPath = images.first.path;
      }
    }

    if (targetPath == null) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: SupportedFormats.pickerExtensions,
        dialogTitle: 'Select Image for Social Hub',
      );
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        targetPath = result.files.first.path;
      }
    }

    if (targetPath != null && mounted) {
      showDialog(
        context: context,
        builder: (_) => SocialHubDialog(imagePath: targetPath!),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or open an image to use Social Hub')),
      );
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
    final allPaths = allImages.map((f) => f.path).toList();

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
            'fileList': allPaths,
            'index': globalIndex < 0 ? 0 : globalIndex,
          }),
          onQuickEdit: () => context.push('/editor', extra: {'filePath': img.path}),
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
      child: GlassContainer(
        blur: 20,
        opacity: isDark ? 0.08 : 0.80,
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(36),
        margin: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
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
