/// Runtime configuration for the Ngingu mobile client.
///
/// Base URL is overridable at build/run time:
///   flutter run --dart-define=API_URL=http://10.0.2.2:8000/api
class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.ngingu.id/api',
  );

  /// Server origin (without `/api`) — used to resolve storage/CDN-relative URLs.
  static final String origin = baseUrl.replaceAll(RegExp(r'/api/?$'), '');

  // ── Long-polling (API.md §4.3, §9) ────────────────────────────────────────
  /// `wait` seconds held by the server on the first result request.
  static const int scanWaitSeconds = 300;

  /// Dio timeouts — long-poll must exceed the 300s server ceiling (§9.3: ≥320s).
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration longPollReceiveTimeout = Duration(seconds: 320);

  // ── Client-side rules ─────────────────────────────────────────────────────
  static const int maxScanImages = 5; // FR-02.2.5 / API.md §2.7
  static const int maxPostImages = 5; // FR-05.2.1
  static const int maxCommentImages = 3; // FR-05.3.2
  static const int maxTagsPerPost = 5; // FR-05.2.4
  static const int maxUploadBytes = 10 * 1024 * 1024; // 10 MB / file
  static const int compressTargetBytes = 500 * 1024; // < 500 KB (NFR-01.7)
  static const int lowConfidenceThreshold = 60; // FR-02.2.3

  /// Poll cadences (API.md §9.2).
  static const Duration notificationPollInterval = Duration(seconds: 60);
  static const Duration dashboardRefreshInterval = Duration(minutes: 5); // FR-07.1

  static const String appName = 'Ngingu';
}
