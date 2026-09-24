import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/app_theme.dart';
import '../models/cloud_config.dart';
import '../services/cloud_vault_service.dart';

/// Modal dialog for configuring cloud backup and uploading selected photos.
class CloudVaultDialog extends StatefulWidget {
  const CloudVaultDialog({
    super.key,
    required this.filePaths,
  });

  final List<String> filePaths;

  @override
  State<CloudVaultDialog> createState() => _CloudVaultDialogState();
}

class _CloudVaultDialogState extends State<CloudVaultDialog> {
  final _service = CloudVaultService();
  late final TextEditingController _urlController;
  late final TextEditingController _userController;
  late final TextEditingController _secretController;
  late final TextEditingController _targetController;

  CloudProviderType _providerType = CloudProviderType.webdav;
  bool _isLoading = true;
  bool _isTesting = false;
  bool? _testSuccess;
  bool _isUploading = false;
  double _currentFileProgress = 0.0;
  String _uploadStatusText = '';

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _userController = TextEditingController();
    _secretController = TextEditingController();
    _targetController = TextEditingController(text: 'apertix-vault');
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final saved = await _service.loadConfig();
    if (saved != null && mounted) {
      setState(() {
        _providerType = saved.providerType;
        _urlController.text = saved.serverUrl;
        _userController.text = saved.username;
        _secretController.text = saved.passwordOrToken;
        _targetController.text = saved.targetBucketOrFolder;
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  CloudConfig _buildConfig() {
    return CloudConfig(
      providerType: _providerType,
      serverUrl: _urlController.text.trim(),
      username: _userController.text.trim(),
      passwordOrToken: _secretController.text.trim(),
      targetBucketOrFolder: _targetController.text.trim(),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testSuccess = null;
    });

    final config = _buildConfig();
    await _service.saveConfig(config);
    final ok = await _service.testConnection(config);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = ok;
      });
    }
  }

  Future<void> _startUpload() async {
    final config = _buildConfig();
    await _service.saveConfig(config);

    setState(() {
      _isUploading = true;
      _currentFileProgress = 0.0;
    });

    int succeeded = 0;
    for (int i = 0; i < widget.filePaths.length; i++) {
      if (!mounted) return;
      final path = widget.filePaths[i];
      final name = p.basename(path);

      setState(() {
        _currentFileProgress = 0.0;
        _uploadStatusText = 'Uploading (${i + 1}/${widget.filePaths.length}): $name';
      });

      try {
        await _service.uploadFile(
          path,
          config,
          onProgress: (sent, total) {
            if (mounted && total > 0) {
              setState(() => _currentFileProgress = sent / total);
            }
          },
        );
        succeeded++;
      } catch (e) {
        // Continue with remaining files
      }
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadStatusText = 'Backup Complete! $succeeded of ${widget.filePaths.length} uploaded.';
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _secretController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 640),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D101A).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ApertixColors.primary, ApertixColors.secondary],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cloud Backup Vault',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Securely sync ${widget.filePaths.length} photo${widget.filePaths.length == 1 ? '' : 's'} to your private cloud storage',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Provider Type Selector
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: CloudProviderType.values.map((type) {
                            final isSel = _providerType == type;
                            return Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _providerType = type),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSel ? ApertixColors.primary.withValues(alpha: 0.4) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSel ? ApertixColors.cyanAccent.withValues(alpha: 0.5) : Colors.transparent,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      type == CloudProviderType.webdav
                                          ? 'WebDAV'
                                          : type == CloudProviderType.supabase
                                              ? 'Supabase'
                                              : 'Custom',
                                      style: TextStyle(
                                        color: isSel ? Colors.white : Colors.white60,
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Form Fields
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildField(
                                controller: _urlController,
                                label: 'Server / Endpoint URL',
                                hint: _providerType == CloudProviderType.supabase
                                    ? 'https://your-project.supabase.co'
                                    : 'https://nas.local:8080/remote.php/dav/files/user',
                                icon: Icons.link_rounded,
                              ),
                              const SizedBox(height: 12),
                              if (_providerType == CloudProviderType.webdav) ...[
                                _buildField(
                                  controller: _userController,
                                  label: 'Username',
                                  hint: 'admin',
                                  icon: Icons.person_rounded,
                                ),
                                const SizedBox(height: 12),
                              ],
                              _buildField(
                                controller: _secretController,
                                label: _providerType == CloudProviderType.supabase
                                    ? 'Supabase Service Role / Anon API Key'
                                    : 'Password / App Token',
                                hint: '••••••••••••••••••••••••',
                                icon: Icons.vpn_key_rounded,
                                isPassword: true,
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                controller: _targetController,
                                label: _providerType == CloudProviderType.supabase
                                    ? 'Target Storage Bucket'
                                    : 'Target Folder',
                                hint: 'photos-backup',
                                icon: Icons.folder_rounded,
                              ),
                              const SizedBox(height: 16),

                              // Test Connection & Status
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    icon: _isTesting
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.network_check_rounded, size: 16),
                                    label: const Text('Test Connection'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    onPressed: _isTesting ? null : _testConnection,
                                  ),
                                  const SizedBox(width: 12),
                                  if (_testSuccess != null)
                                    Row(
                                      children: [
                                        Icon(
                                          _testSuccess! ? Icons.check_circle_rounded : Icons.error_rounded,
                                          color: _testSuccess! ? Colors.greenAccent : Colors.redAccent,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _testSuccess! ? 'Connected Successfully' : 'Connection Failed',
                                          style: TextStyle(
                                            color: _testSuccess! ? Colors.greenAccent : Colors.redAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Upload Progress HUD
                      if (_isUploading || _uploadStatusText.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _uploadStatusText,
                                style: const TextStyle(color: ApertixColors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              if (_isUploading) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _currentFileProgress,
                                  backgroundColor: Colors.white10,
                                  valueColor: const AlwaysStoppedAnimation<Color>(ApertixColors.cyanAccent),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                            label: Text('Backup ${widget.filePaths.length} Photos'),
                            style: FilledButton.styleFrom(
                              backgroundColor: ApertixColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: _isUploading || widget.filePaths.isEmpty ? null : _startUpload,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: Colors.white38),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ApertixColors.cyanAccent),
            ),
          ),
        ),
      ],
    );
  }
}
