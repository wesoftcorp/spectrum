import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/social_account.dart';
import '../models/social_platform.dart';

/// Secure Token Vault providing AES-encrypted persistent storage for social credentials & webhooks.
class TokenVaultService {
  TokenVaultService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              wOptions: WindowsOptions(useBackwardCompatibility: true),
            );

  final FlutterSecureStorage _storage;
  static const String _keyPrefix = 'apertix_social_acc_';

  Future<void> saveAccount(SocialAccount account) async {
    final key = '$_keyPrefix${account.platform.name}';
    await _storage.write(key: key, value: account.serialize());
  }

  Future<SocialAccount?> getAccount(SocialPlatform platform) async {
    try {
      final key = '$_keyPrefix${platform.name}';
      final val = await _storage.read(key: key);
      if (val == null) return null;
      return SocialAccount.deserialize(val);
    } catch (_) {
      return null;
    }
  }

  Future<List<SocialAccount>> getAllAccounts() async {
    try {
      final all = await _storage.readAll();
      final accounts = <SocialAccount>[];
      for (final entry in all.entries) {
        if (entry.key.startsWith(_keyPrefix)) {
          final acc = SocialAccount.deserialize(entry.value);
          if (acc != null) {
            accounts.add(acc);
          }
        }
      }
      return accounts;
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteAccount(SocialPlatform platform) async {
    final key = '$_keyPrefix${platform.name}';
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      if (key.startsWith(_keyPrefix)) {
        await _storage.delete(key: key);
      }
    }
  }
}
