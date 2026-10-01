/// App info model — `GET /api/app-info` (About page, APK update info).
library;

class AppInfo {
  const AppInfo({
    this.appName,
    this.description,
    this.developer,
    this.website,
    this.supportEmail,
    this.privacyPolicyUrl,
    this.termsUrl,
    this.privacyPolicyContent,
    this.termsContent,
    this.apkPath,
    this.apkFilename,
    this.apkVersion,
    this.apkUploadedAt,
  });

  final String? appName;
  final String? description;
  final String? developer;
  final String? website;
  final String? supportEmail;
  final String? privacyPolicyUrl;
  final String? termsUrl;
  final String? privacyPolicyContent;
  final String? termsContent;
  final String? apkPath;
  final String? apkFilename;
  final String? apkVersion;
  final String? apkUploadedAt;

  bool get hasApk => apkPath != null && apkPath!.isNotEmpty;

  factory AppInfo.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return AppInfo(
      appName: j['app_name'] as String?,
      description: j['description'] as String?,
      developer: j['developer'] as String?,
      website: j['website'] as String?,
      supportEmail: j['support_email'] as String?,
      privacyPolicyUrl: j['privacy_policy_url'] as String?,
      termsUrl: j['terms_url'] as String?,
      privacyPolicyContent: j['privacy_policy_content'] as String?,
      termsContent: j['terms_content'] as String?,
      apkPath: j['apk_path'] as String?,
      apkFilename: j['apk_filename'] as String?,
      apkVersion: j['apk_version'] as String?,
      apkUploadedAt: j['apk_uploaded_at'] as String?,
    );
  }
}
