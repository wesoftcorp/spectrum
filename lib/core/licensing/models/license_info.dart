import 'dart:convert';

enum LicenseTier {
  free('Apertix Core', 'Standard open-source features'),
  pro('Apertix Pro', 'Advanced creative suite, batch engine, social publishing & AI features');

  final String title;
  final String description;
  const LicenseTier(this.title, this.description);
}

/// Cryptographically verified license record.
class LicenseInfo {
  const LicenseInfo({
    required this.tier,
    this.key,
    this.email,
    this.activatedAt,
    this.deviceFingerprint,
    this.isPerpetual = true,
  });

  final LicenseTier tier;
  final String? key;
  final String? email;
  final DateTime? activatedAt;
  final String? deviceFingerprint;
  final bool isPerpetual;

  bool get isPro => tier == LicenseTier.pro;

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        'key': key,
        'email': email,
        'activatedAt': activatedAt?.toIso8601String(),
        'deviceFingerprint': deviceFingerprint,
        'isPerpetual': isPerpetual,
      };

  factory LicenseInfo.fromJson(Map<String, dynamic> map) {
    return LicenseInfo(
      tier: map['tier'] == 'pro' ? LicenseTier.pro : LicenseTier.free,
      key: map['key'] as String?,
      email: map['email'] as String?,
      activatedAt: DateTime.tryParse(map['activatedAt'] as String? ?? ''),
      deviceFingerprint: map['deviceFingerprint'] as String?,
      isPerpetual: map['isPerpetual'] as bool? ?? true,
    );
  }

  String serialize() => jsonEncode(toJson());

  static LicenseInfo deserialize(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LicenseInfo.fromJson(map);
    } catch (_) {
      return const LicenseInfo(tier: LicenseTier.free);
    }
  }
}
