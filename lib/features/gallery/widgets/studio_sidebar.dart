import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/app_theme.dart';
import '../../../core/licensing/providers/license_provider.dart';
import '../../../core/licensing/widgets/license_dialog.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/widgets/album_picker_dialog.dart';
import '../../settings/widgets/shortcuts_dialog.dart';

/// Glassmorphic Studio Sidebar displaying all Apertix engines, albums, and Pro features.
class StudioSidebar extends ConsumerWidget {
  const StudioSidebar({
    super.key,
    required this.totalImagesCount,
    required this.currentFolder,
    required this.isFavoritesActive,
    required this.activeAlbumId,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onShowAllPhotos,
    required this.onToggleFavorites,
    required this.onSelectAlbum,
    required this.onPickFolder,
    required this.onPickFile,
    required this.onOpenBatchStudio,
    required this.onOpenComparisonStudio,
    required this.onOpenCloudVault,
    required this.onOpenWindowsShell,
    this.onOpenPhotoEditor,
    this.onOpenSocialHub,
  });

  final int totalImagesCount;
  final String? currentFolder;
  final bool isFavoritesActive;
  final String? activeAlbumId;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onShowAllPhotos;
  final VoidCallback onToggleFavorites;
  final ValueChanged<String?> onSelectAlbum;
  final VoidCallback onPickFolder;
  final VoidCallback onPickFile;
  final VoidCallback onOpenBatchStudio;
  final VoidCallback onOpenComparisonStudio;
  final VoidCallback onOpenCloudVault;
  final VoidCallback onOpenWindowsShell;
  final VoidCallback? onOpenPhotoEditor;
  final VoidCallback? onOpenSocialHub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPro = ref.watch(isProActiveProvider);
    final albums = ref.watch(albumsProvider);
    final favorites = ref.watch(favoritesProvider);

    final width = isCollapsed ? 68.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF13161F).withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.75),
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: isCollapsed ? 68.0 : 260.0,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
              // Top Brand Header & Collapse Toggle
              _buildHeader(context, isDark, isPro),

              const Divider(height: 1),

              // Scrollable studio navigation items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  children: [
                    // Pro Status Banner Capsule
                    _buildProBanner(context, isDark, isPro),
                    const SizedBox(height: 12),

                    // Section: Library
                    if (!isCollapsed)
                      _buildSectionTitle('LIBRARY', isDark),
                    _buildNavTile(
                      icon: Icons.photo_library_outlined,
                      activeIcon: Icons.photo_library_rounded,
                      label: 'All Photos',
                      count: totalImagesCount,
                      isActive: !isFavoritesActive && activeAlbumId == null,
                      onTap: onShowAllPhotos,
                      isDark: isDark,
                    ),
                    _buildNavTile(
                      icon: Icons.favorite_border_rounded,
                      activeIcon: Icons.favorite_rounded,
                      label: 'Favorites',
                      count: favorites.length,
                      isActive: isFavoritesActive,
                      activeColor: const Color(0xFFFF4757),
                      onTap: onToggleFavorites,
                      isDark: isDark,
                    ),
                    _buildNavTile(
                      icon: Icons.folder_open_rounded,
                      label: currentFolder != null
                          ? p.basename(currentFolder!)
                          : 'Open Folder',
                      subtitle: currentFolder,
                      isActive: false,
                      onTap: onPickFolder,
                      isDark: isDark,
                    ),
                    _buildNavTile(
                      icon: Icons.add_photo_alternate_outlined,
                      label: 'Open Image...',
                      isActive: false,
                      onTap: onPickFile,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 14),

                    // Section: Virtual Albums & Collections
                    if (!isCollapsed) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('ALBUMS', isDark),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 16),
                            tooltip: 'New Virtual Album',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => const AlbumPickerDialog(imagePaths: []),
                            ),
                          ),
                        ],
                      ),
                      if (albums.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Text(
                            'No albums yet. Click + to create.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white30 : Colors.black26,
                            ),
                          ),
                        )
                      else
                        ...albums.map((album) {
                          final isSelected = activeAlbumId == album.id;
                          return _buildNavTile(
                            icon: Icons.collections_bookmark_outlined,
                            activeIcon: Icons.collections_bookmark_rounded,
                            label: album.name,
                            count: album.imagePaths.length,
                            isActive: isSelected,
                            onTap: () => onSelectAlbum(isSelected ? null : album.id),
                            isDark: isDark,
                          );
                        }),
                      const SizedBox(height: 14),
                    ],

                    // Section: Studio Tools (Visible 1-Click Launchers!)
                    if (!isCollapsed)
                      _buildSectionTitle('STUDIO PRO TOOLS', isDark),

                    _buildNavTile(
                      icon: Icons.compare_arrows_rounded,
                      label: 'Comparison Studio',
                      badge: 'PRO',
                      isProFeature: true,
                      onTap: onOpenComparisonStudio,
                      isDark: isDark,
                    ),
                    _buildNavTile(
                      icon: Icons.auto_awesome_motion_rounded,
                      label: 'Batch Studio Pro',
                      badge: 'PRO',
                      isProFeature: true,
                      onTap: onOpenBatchStudio,
                      isDark: isDark,
                    ),
                    _buildNavTile(
                      icon: Icons.cloud_sync_rounded,
                      label: 'Cloud Vault Sync',
                      badge: 'VAULT',
                      isProFeature: true,
                      onTap: onOpenCloudVault,
                      isDark: isDark,
                    ),
                    _buildNavTile(
                      icon: Icons.tune_rounded,
                      label: 'Photo Editor',
                      onTap: onOpenPhotoEditor ?? () => context.push('/editor'),
                      isDark: isDark,
                    ),
                    _buildNavTile(
                      icon: Icons.share_rounded,
                      label: 'Social Hub',
                      onTap: onOpenSocialHub ?? () {},
                      isDark: isDark,
                    ),

                    if (Platform.isWindows)
                      _buildNavTile(
                        icon: Icons.desktop_windows_rounded,
                        label: 'Windows Shell',
                        onTap: onOpenWindowsShell,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Bottom Utilities Bar (Shortcuts & Settings)
              _buildBottomBar(context, isDark),
            ],
          ),
        ),
      );
    },
  ),
),
),
);
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isPro) {
    if (isCollapsed) {
      return Container(
        height: 64,
        alignment: Alignment.center,
        child: IconButton(
          icon: const Icon(Icons.menu_rounded, size: 22),
          tooltip: 'Expand Studio Rail',
          onPressed: onToggleCollapse,
        ),
      );
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Official Apertix Cyber-Iris Logo (from Stitch)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: ApertixColors.cyanAccent.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icons/apertix_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Brand Title
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'APERTIX',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isPro
                              ? ApertixColors.secondary.withValues(alpha: 0.2)
                              : ApertixColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isPro ? ApertixColors.secondary : ApertixColors.primary,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isPro ? 'PRO' : 'STUDIO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isPro ? ApertixColors.secondary : ApertixColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Next-Gen Image Suite',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Collapse button
          IconButton(
            icon: const Icon(Icons.menu_open_rounded, size: 20),
            tooltip: 'Collapse Rail',
            onPressed: onToggleCollapse,
          ),
        ],
      ),
    );
  }

  Widget _buildProBanner(BuildContext context, bool isDark, bool isPro) {
    if (isCollapsed) {
      return IconButton(
        icon: Icon(
          isPro ? Icons.verified_rounded : Icons.workspace_premium_outlined,
          color: isPro ? ApertixColors.secondary : ApertixColors.cyanAccent,
          size: 22,
        ),
        tooltip: isPro ? 'Apertix Pro Active' : 'Unlock Apertix Pro',
        onPressed: () => showDialog(context: context, builder: (_) => const LicenseDialog()),
      );
    }

    return InkWell(
      onTap: () => showDialog(context: context, builder: (_) => const LicenseDialog()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isPro
                ? [
                    ApertixColors.secondary.withValues(alpha: isDark ? 0.20 : 0.15),
                    ApertixColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                  ]
                : [
                    ApertixColors.cyanAccent.withValues(alpha: isDark ? 0.15 : 0.12),
                    ApertixColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                  ],
          ),
          border: Border.all(
            color: isPro
                ? ApertixColors.secondary.withValues(alpha: 0.5)
                : ApertixColors.cyanAccent.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPro ? Icons.verified_rounded : Icons.workspace_premium_rounded,
              color: isPro ? ApertixColors.secondary : ApertixColors.cyanAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPro ? 'PRO ACTIVATED' : 'UNLOCK PRO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isPro ? ApertixColors.secondary : ApertixColors.cyanAccent,
                    ),
                  ),
                  Text(
                    isPro ? 'All 12 Studio Engines Active' : 'Batch, Compare & Cloud Sync',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: isDark ? ApertixColors.darkTextMuted : ApertixColors.lightTextMuted,
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    IconData? activeIcon,
    required String label,
    String? subtitle,
    int? count,
    String? badge,
    bool isProFeature = false,
    bool isActive = false,
    Color? activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final effectiveActiveColor = activeColor ?? ApertixColors.primary;

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: IconButton(
            icon: Icon(
              isActive && activeIcon != null ? activeIcon : icon,
              color: isActive
                  ? effectiveActiveColor
                  : (isDark ? Colors.white70 : Colors.black87),
              size: 20,
            ),
            tooltip: label,
            onPressed: onTap,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isActive
                  ? effectiveActiveColor.withValues(alpha: isDark ? 0.22 : 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? effectiveActiveColor.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive && activeIcon != null ? activeIcon : icon,
                  size: 17,
                  color: isActive
                      ? effectiveActiveColor
                      : (isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? ApertixColors.darkTextPrimary : ApertixColors.lightTextPrimary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: ApertixColors.cyanAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: ApertixColors.cyanAccent.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: ApertixColors.cyanAccent,
                      ),
                    ),
                  ),
                if (count != null)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    if (isCollapsed) {
      return Column(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_rounded, size: 20),
            tooltip: 'Shortcuts Cheatsheet',
            onPressed: () => showDialog(context: context, builder: (_) => const ShortcutsDialog()),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(height: 6),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => showDialog(context: context, builder: (_) => const ShortcutsDialog()),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.keyboard_rounded,
                      size: 16,
                      color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Shortcuts',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? ApertixColors.darkTextSecondary : ApertixColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 18),
            tooltip: 'Studio Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}
