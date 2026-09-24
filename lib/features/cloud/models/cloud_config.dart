enum CloudProviderType {
  webdav('WebDAV (Nextcloud / ownCloud / NAS)', 'Standard WebDAV PUT protocol'),
  supabase('Supabase Storage', 'Supabase S3-compatible REST Storage API'),
  customHttp('Custom HTTP Endpoint', 'Multipart POST endpoint');

  const CloudProviderType(this.label, this.description);
  final String label;
  final String description;
}

enum UploadStatus { pending, uploading, success, failed }

class CloudConfig {
  const CloudConfig({
    required this.providerType,
    required this.serverUrl,
    this.username = '',
    this.passwordOrToken = '',
    this.targetBucketOrFolder = 'apertix-vault',
  });

  final CloudProviderType providerType;
  final String serverUrl;
  final String username;
  final String passwordOrToken;
  final String targetBucketOrFolder;

  CloudConfig copyWith({
    CloudProviderType? providerType,
    String? serverUrl,
    String? username,
    String? passwordOrToken,
    String? targetBucketOrFolder,
  }) {
    return CloudConfig(
      providerType: providerType ?? this.providerType,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      passwordOrToken: passwordOrToken ?? this.passwordOrToken,
      targetBucketOrFolder: targetBucketOrFolder ?? this.targetBucketOrFolder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerType': providerType.name,
      'serverUrl': serverUrl,
      'username': username,
      'targetBucketOrFolder': targetBucketOrFolder,
      // Note: passwordOrToken is saved separately in secure storage
    };
  }

  factory CloudConfig.fromJson(Map<String, dynamic> json, {String passwordOrToken = ''}) {
    return CloudConfig(
      providerType: CloudProviderType.values.firstWhere(
        (t) => t.name == json['providerType'],
        orElse: () => CloudProviderType.webdav,
      ),
      serverUrl: json['serverUrl'] as String? ?? '',
      username: json['username'] as String? ?? '',
      passwordOrToken: passwordOrToken,
      targetBucketOrFolder: json['targetBucketOrFolder'] as String? ?? 'apertix-vault',
    );
  }
}

class CloudUploadItem {
  CloudUploadItem({
    required this.filePath,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.errorMessage,
  });

  final String filePath;
  UploadStatus status;
  double progress;
  String? errorMessage;
}
