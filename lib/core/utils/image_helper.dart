import '../config/app_config.dart';

String resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';

  final serverOrigin = AppConfig.baseUrl.replaceAll(RegExp(r'/api/?$'), '');

  // If backend returns localhost or local IP URLs from storage, map it to current serverOrigin
  if (url.startsWith('http://localhost') ||
      url.startsWith('http://127.0.0.1') ||
      url.startsWith('http://10.0.2.2')) {
    return url.replaceFirst(RegExp(r'^https?://[^/]+'), serverOrigin);
  }

  if (!url.startsWith('http')) {
    final cleanPath = url.startsWith('/') ? url.substring(1) : url;
    if (cleanPath.startsWith('storage/')) {
      return '$serverOrigin/$cleanPath';
    }
    return '$serverOrigin/storage/$cleanPath';
  }

  return url;
}
