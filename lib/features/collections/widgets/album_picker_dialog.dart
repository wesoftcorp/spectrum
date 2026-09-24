import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/collections_provider.dart';

/// Modal dialog for adding image paths to an existing or new virtual album.
class AlbumPickerDialog extends ConsumerStatefulWidget {
  const AlbumPickerDialog({
    super.key,
    required this.imagePaths,
  });

  final List<String> imagePaths;

  @override
  ConsumerState<AlbumPickerDialog> createState() => _AlbumPickerDialogState();
}

class _AlbumPickerDialogState extends ConsumerState<AlbumPickerDialog> {
  final TextEditingController _newAlbumController = TextEditingController();
  bool _isCreatingNew = false;

  @override
  void dispose() {
    _newAlbumController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAlbum() async {
    final name = _newAlbumController.text.trim();
    if (name.isEmpty) return;

    final album = await ref.read(albumsProvider.notifier).createAlbum(
      name: name,
      initialPaths: widget.imagePaths,
    );

    if (mounted) {
      Navigator.of(context).pop(album.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final albums = ref.watch(albumsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 420,
            constraints: const BoxConstraints(maxHeight: 520),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0D101A).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.photo_library_rounded, color: ApertixColors.cyanAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Add to Album (${widget.imagePaths.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Create New Album input or button
                if (_isCreatingNew) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newAlbumController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter album name...',
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.06),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                          onSubmitted: (_) => _handleCreateAlbum(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _handleCreateAlbum,
                        style: FilledButton.styleFrom(
                          backgroundColor: ApertixColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Create New Virtual Album'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ApertixColors.cyanAccent,
                      side: BorderSide(color: ApertixColors.cyanAccent.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => setState(() => _isCreatingNew = true),
                  ),
                ],
                const SizedBox(height: 16),

                const Text(
                  'EXISTING ALBUMS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),

                // Existing Albums List
                if (albums.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No albums created yet.\nCreate one above to organize your photos without duplicating files.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, height: 1.4),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: albums.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        return InkWell(
                          onTap: () async {
                            await ref.read(albumsProvider.notifier).addImagesToAlbum(album.id, widget.imagePaths);
                            if (context.mounted) {
                              Navigator.of(context).pop(album.name);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.folder_special_rounded, color: ApertixColors.secondary, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        album.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${album.count} photos',
                                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.add_circle_outline_rounded, color: ApertixColors.cyanAccent, size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
