import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';

/// Parsed standard envelope (API.md §2.4): `{success, message, data[, meta|errors]}`.
class ApiResult<T> {
  const ApiResult({
    required this.statusCode,
    required this.success,
    this.message = '',
    this.data,
    this.meta,
    this.errors = const {},
    this.retryAfter,
    this.isNetworkError = false,
    this.isTimeout = false,
  });

  final int statusCode;
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;
  final Map<String, List<String>> errors;
  final int? retryAfter;
  final bool isNetworkError;
  final bool isTimeout;

  bool get hasFieldErrors => errors.isNotEmpty;

  /// First validation message for a field, if any.
  String? fieldError(String field) => errors[field]?.first;

  /// Human-readable failure reason (validation → network → generic).
  String get errorText {
    if (errors.isNotEmpty) {
      final all = errors.values.expand((e) => e).toList();
      if (all.isNotEmpty) return all.first;
    }
    if (message.isNotEmpty) return message;
    if (isNetworkError) return 'Koneksi gagal. Periksa internet Anda.';
    if (isTimeout) return 'Koneksi waktu tunggu habis. Coba lagi.';
    return 'Terjadi kesalahan. Coba lagi.';
  }

  /// Pagination meta (API.md §2.5).
  int get currentPage => (meta?['current_page'] as num?)?.toInt() ?? 1;
  int get lastPage => (meta?['last_page'] as num?)?.toInt() ?? 1;
  int get total => (meta?['total'] as num?)?.toInt() ?? 0;
  int get perPage => (meta?['per_page'] as num?)?.toInt() ?? 15;
  int get unreadCount => (meta?['unread_count'] as num?)?.toInt() ?? 0;
}

typedef JsonParser<T> = T Function(dynamic json);

/// HTTP client for the Ngingu Laravel API.
///
/// All methods understand the standard envelope and never throw — failures
/// come back as `ApiResult(success: false)` so controllers can branch on it.
class ApiClient {
  ApiClient._();

  static late final Dio _dio;
  static late final Dio _pollDio;
  static void Function()? onUnauthorized;

  static void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: const {'Accept': 'application/json'},
    ));
    _pollDio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.longPollReceiveTimeout, // ≥320s (API.md §9.3)
      headers: const {'Accept': 'application/json'},
    ));
    for (final d in [_dio, _pollDio]) {
      d.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthService.token;
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401 &&
              !e.requestOptions.path.contains('/logout')) {
            onUnauthorized?.call();
          }
          handler.next(e);
        },
      ));
    }
  }

  // ── verbs ─────────────────────────────────────────────────────────────────

  static Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    JsonParser<T>? parse,
    bool longPoll = false,
    CancelToken? cancelToken,
  }) =>
      _request('GET', path,
          query: query, parse: parse, longPoll: longPoll, cancelToken: cancelToken);

  static Future<ApiResult<T>> post<T>(
    String path, {
    Object? data,
    JsonParser<T>? parse,
    bool longPoll = false,
    CancelToken? cancelToken,
  }) =>
      _request('POST', path,
          data: data, parse: parse, longPoll: longPoll, cancelToken: cancelToken);

  static Future<ApiResult<T>> put<T>(
    String path, {Object? data, JsonParser<T>? parse, CancelToken? cancelToken}) =>
      _request('PUT', path, data: data, parse: parse, cancelToken: cancelToken);

  static Future<ApiResult<T>> patch<T>(
    String path, {Object? data, JsonParser<T>? parse, CancelToken? cancelToken}) =>
      _request('PATCH', path, data: data, parse: parse, cancelToken: cancelToken);

  static Future<ApiResult<T>> delete<T>(
    String path, {JsonParser<T>? parse, CancelToken? cancelToken}) =>
      _request('DELETE', path, parse: parse, cancelToken: cancelToken);

  /// Multipart upload (scans, avatar, forum images).
  static Future<ApiResult<T>> postMultipart<T>(
    String path, {
    required FormData formData,
    JsonParser<T>? parse,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      _request('POST', path,
          data: formData,
          parse: parse,
          onSendProgress: onSendProgress,
          cancelToken: cancelToken);

  /// Authenticated binary download (CSV/PDF exports — API.md §4.5/§4.6).
  static Future<void> downloadFile(
    String path, {
    required String savePath,
    Map<String, dynamic>? query,
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    await _dio.download(path, savePath,
        queryParameters: query,
        options: Options(responseType: ResponseType.stream),
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken);
  }

  // ── core ──────────────────────────────────────────────────────────────────

  static Future<ApiResult<T>> _request<T>(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    JsonParser<T>? parse,
    bool longPoll = false,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await (longPoll ? _pollDio : _dio).request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          contentType: data is FormData ? 'multipart/form-data' : null,
        ),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      return _envelope<T>(response, parse);
    } on DioException catch (e) {
      return _fromDioError<T>(e, parse);
    } catch (e) {
      // Parser melempar error (payload tak terduga). Kontrak kelas ini adalah
      // "never throw" — kalau lolos, `isLoading = false` di controller tidak
      // pernah terjalankan dan layar nyangkut di loader (bug dashboard 10 Okt).
      debugLog('parse error $method $path: $e');
      return ApiResult<T>(
        statusCode: 200,
        success: false,
        message: 'Data dari server tidak dapat dibaca. Coba lagi.',
      );
    }
  }

  static ApiResult<T> _envelope<T>(Response response, JsonParser<T>? parse) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      // Non-envelope payload (should not happen for JSON endpoints).
      return ApiResult(
        statusCode: response.statusCode ?? 200,
        success: true,
        data: parse != null ? parse(body) : body as T?,
      );
    }
    final success = body['success'] == true;
    return ApiResult(
      statusCode: response.statusCode ?? 200,
      success: success,
      message: (body['message'] as String?) ?? '',
      data: success && parse != null && body['data'] != null
          ? parse(body['data'])
          : (success ? body['data'] as T? : null),
      meta: body['meta'] is Map<String, dynamic> ? body['meta'] as Map<String, dynamic> : null,
      errors: _parseErrors(body['errors']),
      retryAfter: (body['retry_after'] as num?)?.toInt(),
    );
  }

  static ApiResult<T> _fromDioError<T>(DioException e, JsonParser<T>? parse) {
    final status = e.response?.statusCode;
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiResult<T>(
        statusCode: status ?? 408,
        success: false,
        message: 'Koneksi waktu tunggu habis. Coba lagi.',
        isTimeout: true,
      );
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return ApiResult<T>(
        statusCode: status ?? 0,
        success: false,
        message: 'Koneksi gagal. Periksa internet Anda.',
        isNetworkError: true,
      );
    }
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      return ApiResult(
        statusCode: status ?? 500,
        success: false,
        message: (body['message'] as String?) ?? '',
        meta: body['meta'] is Map<String, dynamic> ? body['meta'] as Map<String, dynamic> : null,
        errors: _parseErrors(body['errors']),
        retryAfter: (body['retry_after'] as num?)?.toInt(),
      );
    }
    return ApiResult<T>(
      statusCode: status ?? 500,
      success: false,
      message: status == 503
          ? 'Layanan sedang tidak tersedia. Fitur scan mungkin dinonaktifkan.'
          : 'Terjadi kesalahan server. Coba lagi.',
    );
  }

  static Map<String, List<String>> _parseErrors(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map((k, v) => MapEntry(
          k,
          v is List
              ? v.map((e) => e.toString()).toList()
              : [v.toString()]));
    }
    return const {};
  }

  @visibleForTesting
  static void debugLog(Object? message) {
    if (kDebugMode) debugPrint('[API] $message');
  }
}
