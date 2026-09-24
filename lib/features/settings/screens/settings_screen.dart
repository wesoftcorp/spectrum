import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/licensing/providers/license_provider.dart';
import '../../../core/licensing/widgets/license_dialog.dart';
import '../../../core/update/services/update_checker_service.dart';
import '../../../data/sources/platform/windows_shell_service.dart';
import '../../cloud/widgets/cloud_vault_dialog.dart';
import '../widgets/shortcuts_dialog.dart';

/// Comprehensive Settings Control Center with Licensing, Cloud Vault, Shell Integration, and Update Checker.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _updateService = UpdateCheckerService();
  bool _isCheckingUpdate = false;
  UpdateInfo? _updateResult;

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateResult = null;
    });

    final info = await _updateService.checkForUpdates();
    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
        _updateResult = info;
      });

      if (!info.hasUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apertix is up to date! (v${AppConstants.appVersion})'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showWindowsShellSetupDialog() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final textTheme = theme.textTheme;
    final isPro = ref.watch(isProActiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Studio Preferences'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Pro Membership Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPro
                    ? [ApertixColors.primary.withValues(alpha: 0.2), ApertixColors.secondary.withValues(alpha: 0.2)]
                    : (isDark
                        ? [ApertixColors.darkSurfaceElevated, ApertixColors.darkSurface]
                        : [ApertixColors.lightSurfaceElevated, ApertixColors.lightSurface]),
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPro
                    ? ApertixColors.primary.withValues(alpha: 0.5)
                    : (isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [ApertixColors.primary, ApertixColors.secondary]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPro ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? 'Apertix Pro Active' : 'Apertix Free Edition',
                        style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPro
                            ? 'Commercial offline license unlocked with full studio capabilities.'
                            : 'Upgrade to Pro for Batch Processing, Unlimited Cloud Vault & Pro tools.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: isPro ? Colors.white12 : ApertixColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => showDialog(context: context, builder: (_) => const LicenseDialog()),
                  child: Text(isPro ? 'Manage' : 'Upgrade'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          const _SectionHeader(title: 'Appearance'),
          _SettingsTile(
            leading: const Icon(Icons.palette_outlined, color: ApertixColors.primary),
            title: 'Theme Mode',
            subtitle: switch (themeMode) {
              ThemeMode.dark => 'Studio Dark (Soothing Velvet Slate)',
              ThemeMode.light => 'Studio Light (Calming Mist)',
              ThemeMode.system => 'Follow Operating System',
            },
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined, size: 16), label: Text('Dark')),
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined, size: 16), label: Text('Light')),
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.auto_mode_outlined, size: 16), label: Text('System')),
              ],
              selected: {themeMode},
              onSelectionChanged: (modes) => ref.read(themeModeProvider.notifier).setMode(modes.first),
              style: ButtonStyle(textStyle: WidgetStatePropertyAll(textTheme.labelMedium)),
            ),
          ),
          const SizedBox(height: 20),

          // Storage & Integrations Section
          const _SectionHeader(title: 'Storage & Integrations'),
          _SettingsTile(
            leading: const Icon(Icons.cloud_upload_outlined, color: ApertixColors.secondary),
            title: 'Cloud Backup Vault',
            subtitle: 'Configure WebDAV, Supabase Storage, or private network NAS sync',
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            onTap: () => showDialog(context: context, builder: (_) => const CloudVaultDialog(filePaths: [])),
          ),
          if (Platform.isWindows)
            _SettingsTile(
              leading: const Icon(Icons.desktop_windows_outlined, color: ApertixColors.cyanAccent),
              title: 'Windows File Associations & Shell',
              subtitle: 'Associate 80+ media formats or export .reg script',
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              onTap: _showWindowsShellSetupDialog,
            ),
          const SizedBox(height: 20),

          // Shortcuts & Help
          const _SectionHeader(title: 'Help & Power Tools'),
          _SettingsTile(
            leading: const Icon(Icons.keyboard_outlined, color: Colors.amberAccent),
            title: 'Keyboard Shortcuts Reference',
            subtitle: 'Cheatsheet for rapid navigation, zoom, histograms and studios',
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            onTap: () => showDialog(context: context, builder: (_) => const ShortcutsDialog()),
          ),
          const SizedBox(height: 20),

          // About & Updates Section
          const _SectionHeader(title: 'About & Updates'),
          _SettingsTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: AppConstants.appName,
            subtitle: 'Version ${AppConstants.appVersion} • Open-core image viewer & editor',
            trailing: _isCheckingUpdate
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : OutlinedButton(
                    onPressed: _checkForUpdates,
                    child: const Text('Check for Updates'),
                  ),
          ),
          if (_updateResult != null && _updateResult!.hasUpdate)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ApertixColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ApertixColors.cyanAccent),
              ),
              child: Row(
                children: [
                  const Icon(Icons.new_releases_rounded, color: ApertixColors.cyanAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Version ${_updateResult!.latestVersion} Available!',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Text(
                          'A new release is ready for download.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      final uri = Uri.parse(_updateResult!.downloadUrl);
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: const Text('Download'),
                  ),
                ],
              ),
            ),
          _SettingsTile(
            leading: const Icon(Icons.code_rounded),
            title: 'GitHub Source Repository',
            subtitle: 'github.com/wesoftcorp/apertix',
            trailing: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white54),
            onTap: () => launchUrl(
              Uri.parse('https://github.com/wesoftcorp/apertix'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.2,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: ApertixColors.cyanAccent,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isDark ? ApertixColors.darkSurface : ApertixColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? ApertixColors.darkBorder : ApertixColors.lightBorder),
      ),
      child: ListTile(
        leading: leading,
        title: Text(title, style: TextStyle(color: colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11))
            : null,
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
