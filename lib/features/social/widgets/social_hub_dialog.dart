import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/app_theme.dart';
import '../../../core/di/providers.dart';
import '../models/social_platform.dart';
import '../providers/social_hub_provider.dart';
import '../services/publish_engine.dart';

/// Nordic Glass Social Hub dialog modal for cross-platform publishing, framing, and captioning.
class SocialHubDialog extends ConsumerStatefulWidget {
  const SocialHubDialog({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  ConsumerState<SocialHubDialog> createState() => _SocialHubDialogState();
}

class _SocialHubDialogState extends ConsumerState<SocialHubDialog> {
  bool _showHistory = false;
  bool _isMultiPublishMode = false;
  bool _isPublishingMulti = false;
  final Set<SocialPlatform> _multiPublishTargets = {SocialPlatform.instagram};
  final Map<SocialPlatform, PlatformDispatchState> _dispatchStates = {};
  late final TextEditingController _captionController;
  late final TextEditingController _altTextController;
  late final TextEditingController _discordWebhookController;
  late final TextEditingController _telegramTokenController;
  late final TextEditingController _telegramChatIdController;

  static const List<String> _suggestedTags = [
    '#shotonapertix',
    '#streetphotography',
    '#landscape',
    '#minimalism',
    '#nightphotography',
    '#portrait',
    '#visualsoflife',
    '#nature',
  ];

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    _altTextController = TextEditingController();
    _discordWebhookController = TextEditingController();
    _telegramTokenController = TextEditingController();
    _telegramChatIdController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _altTextController.dispose();
    _discordWebhookController.dispose();
    _telegramTokenController.dispose();
    _telegramChatIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialHubProvider(widget.imagePath));
    final notifier = ref.read(socialHubProvider(widget.imagePath).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final draft = state.draft;
    final platform = draft.platform;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 880,
        height: 660,
        decoration: BoxDecoration(
          color: isDark ? ApertixColors.darkSurface : ApertixColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: platform.brandColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: platform.brandColor.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Bar: Brand, Platform selector & Close
            _buildTopBar(platform, notifier),

            // Content Area: Either History or 2-Column Publisher Studio
            if (_showHistory)
              Expanded(child: _buildHistoryView(state))
            else
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column: Aspect Ratio & Image Framing Preview
                    Expanded(
                      flex: 4,
                      child: _buildAspectPreviewColumn(state, notifier, isDark),
                    ),

                    // Divider
                    Container(width: 1, color: Colors.white.withValues(alpha: 0.08)),

                    // Right Column: Caption, Tags, Character Limit & Webhooks
                    Expanded(
                      flex: 5,
                      child: _buildComposerColumn(state, notifier, isDark),
                    ),
                  ],
                ),
              ),

            // Live Dispatch Progress HUD if dispatching or recently dispatched
            if (_dispatchStates.isNotEmpty)
              _buildDispatchHUD(),

            // Bottom Action Dock
            _buildBottomDock(state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(SocialPlatform currentPlatform, SocialHubNotifier notifier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? ApertixColors.darkSurfaceElevated : ApertixColors.lightSurfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: currentPlatform.gradientColors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(currentPlatform.icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Social Hub',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ApertixColors.cyanAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: ApertixColors.cyanAccent.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: ApertixColors.cyanAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Multi-platform 1-tap publisher • ${p.basename(widget.imagePath)}',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
              const Spacer(),
              // Multi-Publish Mode Toggle
              InkWell(
                onTap: () => setState(() => _isMultiPublishMode = !_isMultiPublishMode),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isMultiPublishMode
                        ? const Color(0xFF6C5CE7).withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isMultiPublishMode ? const Color(0xFF6C5CE7) : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hub_rounded, size: 13, color: _isMultiPublishMode ? const Color(0xFF6C5CE7) : Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        'Multi-Publish',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _isMultiPublishMode ? FontWeight.w700 : FontWeight.w500,
                          color: _isMultiPublishMode ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // History / Studio Toggle
              IconButton(
                icon: Icon(
                  _showHistory ? Icons.tune_rounded : Icons.history_rounded,
                  color: _showHistory ? ApertixColors.cyanAccent : Colors.white70,
                  size: 20,
                ),
                tooltip: _showHistory ? 'Return to Studio' : 'Publish History',
                onPressed: () => setState(() => _showHistory = !_showHistory),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Platform Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SocialPlatform.values.map((p) {
                final isSelected = _isMultiPublishMode
                    ? _multiPublishTargets.contains(p)
                    : p == currentPlatform;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      if (_isMultiPublishMode) {
                        setState(() {
                          if (_multiPublishTargets.contains(p)) {
                            if (_multiPublishTargets.length > 1) {
                              _multiPublishTargets.remove(p);
                            }
                          } else {
                            _multiPublishTargets.add(p);
                          }
                        });
                        notifier.setPlatform(p);
                      } else {
                        notifier.setPlatform(p);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isSelected ? LinearGradient(colors: p.gradientColors) : null,
                        color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isMultiPublishMode) ...[
                            Icon(
                              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              size: 13,
                              color: isSelected ? Colors.white : Colors.white54,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Icon(p.icon, size: 14, color: isSelected ? Colors.white : Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectPreviewColumn(
    SocialHubState state,
    SocialHubNotifier notifier,
    bool isDark,
  ) {
    final draft = state.draft;
    final platform = draft.platform;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.aspect_ratio_rounded, size: 16, color: ApertixColors.cyanAccent),
              const SizedBox(width: 8),
              const Text(
                'Optimal Framing',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              Text(
                draft.preset.resolutionLabel,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Presets pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: platform.presets.map((preset) {
              final isSelected = preset == draft.preset;
              return InkWell(
                onTap: () => notifier.setPreset(preset),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ApertixColors.cyanAccent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? ApertixColors.cyanAccent : Colors.white12,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    preset.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? ApertixColors.cyanAccent : Colors.white70,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Visual Aspect Ratio Container
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: AspectRatio(
                  aspectRatio: draft.preset.ratio ?? 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.cover,
                        ),
                        // Platform watermark badge
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(platform.icon, size: 11, color: platform.brandColor),
                                const SizedBox(width: 4),
                                Text(
                                  platform.name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Export Platform-Optimized button
          OutlinedButton.icon(
            icon: const Icon(Icons.auto_fix_high_rounded, size: 15),
            label: const Text('Export Web-Optimized (EXIF Stripped)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ApertixColors.cyanAccent,
              side: const BorderSide(color: ApertixColors.cyanAccent),
              minimumSize: const Size(double.infinity, 38),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: state.isPublishing ? null : () => notifier.exportOptimized(),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerColumn(
    SocialHubState state,
    SocialHubNotifier notifier,
    bool isDark,
  ) {
    final draft = state.draft;
    final platform = draft.platform;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 18, color: ApertixColors.cyanAccent),
              const SizedBox(width: 8),
              const Text(
                'Caption & Tags',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              // Character limit countdown badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: draft.isOverLimit
                      ? Colors.red.withValues(alpha: 0.2)
                      : (draft.remainingChars < 40
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: draft.isOverLimit
                        ? Colors.redAccent
                        : (draft.remainingChars < 40 ? Colors.amber : Colors.white24),
                  ),
                ),
                child: Text(
                  '${draft.remainingChars} chars left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: draft.isOverLimit
                        ? Colors.redAccent
                        : (draft.remainingChars < 40 ? Colors.amber : Colors.white70),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Caption Text Field
          Expanded(
            child: TextField(
              controller: _captionController,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              decoration: InputDecoration(
                hintText: 'Compose caption for ${platform.name}...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: platform.brandColor),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: notifier.setCaption,
            ),
          ),
          const SizedBox(height: 10),

          // Suggested Hashtag Pills
          const Text('Quick Hashtags:', style: TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestedTags.map((tag) {
                final isSelected = draft.tags.contains(tag);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    selected: isSelected,
                    onSelected: (_) => notifier.toggleTag(tag),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    selectedColor: platform.brandColor.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected ? platform.brandColor : Colors.white12,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Alt-text accessibility field
          TextField(
            controller: _altTextController,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.accessibility_new_rounded, size: 16, color: Colors.white54),
              hintText: 'Alt-text (Accessibility image description)...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.25),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onChanged: notifier.setAltText,
          ),

          // Webhook options for Discord
          if (platform == SocialPlatform.discord) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _discordWebhookController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.link_rounded, size: 16, color: ApertixColors.cyanAccent),
                hintText: 'Discord Webhook URL (https://discord.com/api/webhooks/...)',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.25),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: notifier.setDiscordWebhook,
            ),
          ],

          // Bot options for Telegram
          if (platform == SocialPlatform.telegram) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _telegramTokenController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Bot Token (1234:ABC...)',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.25),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (t) => notifier.setTelegramCredentials(t, _telegramChatIdController.text),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _telegramChatIdController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Chat ID (@channel / 12345)',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.25),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (c) => notifier.setTelegramCredentials(_telegramTokenController.text, c),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomDock(SocialHubState state, SocialHubNotifier notifier) {
    final platform = state.draft.platform;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? ApertixColors.darkSurfaceElevated : ApertixColors.lightSurfaceElevated,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder),
        ),
      ),
      child: Row(
        children: [
          // Feedback message if available
          if (state.lastResult != null)
            Expanded(
              child: Row(
                children: [
                  Icon(
                    state.lastResult!.success
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 16,
                    color: state.lastResult!.success
                        ? ApertixColors.secondary
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.lastResult!.message,
                      style: TextStyle(
                        fontSize: 11,
                        color: state.lastResult!.success
                            ? ApertixColors.secondary
                            : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            const Spacer(),

          // 1-Tap Copy Caption
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 14),
            label: const Text('Copy Caption'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: () async {
              await notifier.copyCaption();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Caption and tags copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 10),

          // Open in Platform App/Web
          OutlinedButton.icon(
            icon: Icon(platform.icon, size: 14),
            label: Text('Open in ${platform.name}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: platform.brandColor.withValues(alpha: 0.5)),
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: state.isPublishing ? null : () => notifier.openPlatformAppOrWeb(),
          ),
          const SizedBox(width: 10),

          // Dedicated Webhook / Bot Action if Discord or Telegram
          if (_isMultiPublishMode && _multiPublishTargets.length > 1)
            FilledButton.icon(
              icon: _isPublishingMulti
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bolt_rounded, size: 16),
              label: Text('Publish to ${_multiPublishTargets.length} Platforms'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onPressed: _isPublishingMulti ? null : () => _handleMultiPublish(state),
            )
          else if (platform == SocialPlatform.discord)
            FilledButton.icon(
              icon: const Icon(Icons.send_rounded, size: 14),
              label: const Text('Post via Webhook'),
              style: FilledButton.styleFrom(
                backgroundColor: platform.brandColor,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onPressed: state.isPublishing ? null : () => notifier.publishToDiscord(),
            )
          else if (platform == SocialPlatform.telegram)
            FilledButton.icon(
              icon: const Icon(Icons.send_rounded, size: 14),
              label: const Text('Post via Bot'),
              style: FilledButton.styleFrom(
                backgroundColor: platform.brandColor,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onPressed: state.isPublishing ? null : () => notifier.publishToTelegram(),
            )
          else
            // System Share Sheet
            FilledButton.icon(
              icon: state.isPublishing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.share_rounded, size: 14),
              label: const Text('Publish / Share'),
              style: FilledButton.styleFrom(
                backgroundColor: platform.brandColor,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onPressed: state.isPublishing ? null : () => notifier.shareViaSystem(),
            ),
        ],
      ),
    );
  }

  Widget _buildDispatchHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Colors.black.withValues(alpha: 0.6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _multiPublishTargets.map((p) {
            final st = _dispatchStates[p]?.status ?? DispatchStatus.idle;
            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(p.icon, size: 13, color: p.brandColor),
                  const SizedBox(width: 4),
                  Text(p.name, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  const SizedBox(width: 4),
                  if (st == DispatchStatus.inProgress)
                    const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                  else if (st == DispatchStatus.success)
                    const Icon(Icons.check_circle_rounded, size: 13, color: ApertixColors.secondary)
                  else if (st == DispatchStatus.failed)
                    const Icon(Icons.error_outline_rounded, size: 13, color: Colors.redAccent)
                  else if (st == DispatchStatus.queued)
                    const Icon(Icons.hourglass_empty_rounded, size: 13, color: Colors.white38),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _handleMultiPublish(SocialHubState state) async {
    setState(() {
      _isPublishingMulti = true;
      _dispatchStates.clear();
    });

    final engine = ref.read(publishEngineProvider);
    await engine.publishMulti(
      draft: state.draft,
      targetPlatforms: _multiPublishTargets,
      onProgress: (platform, dispatchState) {
        if (mounted) {
          setState(() {
            _dispatchStates[platform] = dispatchState;
          });
        }
      },
    );

    if (mounted) {
      setState(() => _isPublishingMulti = false);
      ref.read(socialHubProvider(widget.imagePath).notifier).loadHistory();
    }
  }

  Widget _buildHistoryView(SocialHubState state) {
    if (state.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            const Text(
              'No publishing activity yet',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Posts and dispatches will be recorded here automatically.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: state.history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = state.history[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.success
                  ? ApertixColors.secondary.withValues(alpha: 0.2)
                  : Colors.redAccent.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: item.platform.gradientColors),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.platform.icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.platform.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (item.success ? ApertixColors.secondary : Colors.redAccent)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.success ? 'PUBLISHED' : 'FAILED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: item.success ? ApertixColors.secondary : Colors.redAccent,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${item.publishedAt.year}-${item.publishedAt.month.toString().padLeft(2, '0')}-${item.publishedAt.day.toString().padLeft(2, '0')} ${item.publishedAt.hour.toString().padLeft(2, '0')}:${item.publishedAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.caption.isNotEmpty ? item.caption : item.resultMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
