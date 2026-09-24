import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/license_info.dart';
import '../services/license_service.dart';

final licenseServiceProvider = Provider<LicenseService>((ref) {
  return LicenseService();
});

final licenseProvider =
    AsyncNotifierProvider<LicenseNotifier, LicenseInfo>(LicenseNotifier.new);

class LicenseNotifier extends AsyncNotifier<LicenseInfo> {
  @override
  Future<LicenseInfo> build() async {
    final service = ref.watch(licenseServiceProvider);
    return service.getActiveLicense();
  }

  Future<bool> activate(String key, {String? email}) async {
    final service = ref.read(licenseServiceProvider);
    final success = await service.activateLicense(key: key, email: email);
    if (success) {
      state = AsyncData(await service.getActiveLicense());
    }
    return success;
  }

  Future<void> deactivate() async {
    final service = ref.read(licenseServiceProvider);
    await service.deactivateLicense();
    state = AsyncData(await service.getActiveLicense());
  }
}

/// Convenience selector checking if Pro tier is unlocked.
final isProActiveProvider = Provider<bool>((ref) {
  final license = ref.watch(licenseProvider).valueOrNull;
  return license?.isPro ?? false;
});
