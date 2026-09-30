import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../models/license_info.dart';
import '../providers/license_provider.dart';

/// Modal dialog for reviewing Pro features, entering license keys, and managing license tier.
class LicenseDialog extends ConsumerStatefulWidget {
  const LicenseDialog({super.key});

  @override
  ConsumerState<LicenseDialog> createState() => _LicenseDialogState();
}

class _LicenseDialogState extends ConsumerState<LicenseDialog> {
  late final TextEditingController _keyController;
  late final TextEditingController _emailController;
  bool _isActivating = false;
  String? _errorMessage;

  static const List<Map<String, dynamic>> _proPerks = [
    {
      'icon': Icons.dynamic_feed_rounded,
      'title': 'Batch Processing Studio',
      'desc': 'High-throughput parallel resizing, format conversion & template renaming'
    },
    {
      'icon': Icons.draw_rounded,
      'title': 'On-Image Vector Annotations',
      'desc': 'Draw, add arrows, shapes, and callout text with background burn-in'
    },
    {
      'icon': Icons.share_rounded,
      'title': 'Social Hub Multi-Platform Publisher',
      'desc': 'Direct in-app publishing & framing for 8 major social networks'
    },
    {
      'icon': Icons.sync_rounded,
      'title': 'Real-Time File Watcher',
      'desc': 'Background folder synchronization on external file system changes'
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Encrypted Token Vault & Audit Log',
      'desc': 'AES-256 secure credential storage and complete publishing history'
    },
    {
      'icon': Icons.tune_rounded,
      'title': 'Advanced Creative Shaders',
      'desc': 'Photographic vignette, film grain, and custom color matrices'
    },
  ];

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final licenseAsync = ref.watch(licenseProvider);
    final notifier = ref.read(licenseProvider.notifier);
    final license = licenseAsync.valueOrNull;
    final isPro = license?.isPro ?? false;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 780,
        height: 620,
        decoration: BoxDecoration(
          color: const Color(0xFF0C0F1A).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isPro ? ApertixColors.secondary.withValues(alpha: 0.4) : ApertixColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPro ? ApertixColors.secondary : ApertixColors.primary).withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Banner
            _buildHeader(isPro),

            // Content
            Expanded(
              child: Row(
                children: [
                  // Left Column: Perks List
                  Expanded(
                    flex: 5,
                    child: _buildPerksColumn(),
                  ),

                  // Divider
                  Container(width: 1, color: Colors.white.withValues(alpha: 0.08)),

                  // Right Column: Activation Form or Active Status
                  Expanded(
                    flex: 5,
                    child: isPro ? _buildActiveLicenseCard(license!, notifier) : _buildActivationForm(notifier),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isPro) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141829),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPro
                    ? [ApertixColors.secondary, const Color(0xFF00D2D3)]
                    : [ApertixColors.primary, ApertixColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPro ? Icons.verified_rounded : Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Spectrum Pro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPro ? ApertixColors.secondary : ApertixColors.cyanAccent).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (isPro ? ApertixColors.secondary : ApertixColors.cyanAccent).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      isPro ? 'ACTIVATED' : 'UPGRADE AVAILABLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isPro ? ApertixColors.secondary : ApertixColors.cyanAccent,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                isPro ? 'Full creative license active on this device' : 'Unlock professional creative & batch workflow tools',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPerksColumn() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pro Feature Matrix',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _proPerks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final perk = _proPerks[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ApertixColors.cyanAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(perk['icon'] as IconData, size: 16, color: ApertixColors.cyanAccent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perk['title'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            perk['desc'] as String,
                            style: const TextStyle(fontSize: 11, color: Colors.white54, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationForm(LicenseNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Activate License Key',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter your purchase key from Gumroad, LemonSqueezy, or Paddle.',
            style: TextStyle(fontSize: 11, color: Colors.white54),
          ),
          const SizedBox(height: 18),

          // Key Input
          const Text('License Key', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _keyController,
            style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 1.2, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'APTX-PRO-XXXX-XXXX-XXXX',
              hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 1.2),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.35),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
              prefixIcon: const Icon(Icons.key_rounded, size: 16, color: ApertixColors.cyanAccent),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),

          // Email Input (Optional)
          const Text('Registered Email (Optional)', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'user@example.com',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.35),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
              prefixIcon: const Icon(Icons.email_outlined, size: 16, color: Colors.white54),
            ),
            keyboardType: TextInputType.emailAddress,
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600)),
          ],

          const SizedBox(height: 20),

          // Activate Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              icon: _isActivating
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_open_rounded, size: 16),
              label: const Text('Unlock Spectrum Pro'),
              style: FilledButton.styleFrom(
                backgroundColor: ApertixColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: _isActivating ? null : () => _handleActivation(notifier),
            ),
          ),
          const SizedBox(height: 12),

          // Instant demo key shortcut for evaluation
          Center(
            child: TextButton(
              onPressed: () {
                _keyController.text = 'APTX-PRO-DEMO-2026-F9A1';
              },
              child: const Text('Fill evaluation key (APTX-PRO-DEMO-...)', style: TextStyle(fontSize: 11, color: ApertixColors.cyanAccent)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLicenseCard(LicenseInfo license, LicenseNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ApertixColors.secondary.withValues(alpha: 0.15),
                border: Border.all(color: ApertixColors.secondary.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.check_rounded, size: 36, color: ApertixColors.secondary),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Spectrum Pro Active',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Perpetual License • Offline Verified',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 20),

          // License Details Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('License Key', license.key ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow('Device ID', license.deviceFingerprint ?? 'Current Device'),
                if (license.email != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Licensed To', license.email!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Deactivate
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 14),
              label: const Text('Deactivate on this Device'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                textStyle: const TextStyle(fontSize: 11),
              ),
              onPressed: () async {
                await notifier.deactivate();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        Text(
          value,
          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Future<void> _handleActivation(LicenseNotifier notifier) async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _errorMessage = 'Please enter a license key');
      return;
    }

    setState(() {
      _isActivating = true;
      _errorMessage = null;
    });

    final success = await notifier.activate(key, email: _emailController.text.trim());

    if (!mounted) return;
    setState(() {
      _isActivating = false;
      if (!success) {
        _errorMessage = 'Invalid license key format or signature';
      }
    });
  }
}
