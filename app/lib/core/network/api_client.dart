import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../services/app_logger.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // iOS: use first_unlock so keychain is readable right after device boots
  // (before first user unlock). Without this the app hangs on launch.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  late final Dio dio;

  /// In-memory token cache — avoids reading secure storage on every request
  /// and prevents crashes if the keychain is temporarily locked on app restart.
  String? _cachedToken;

  /// Callback invoked when any API call returns 401 Unauthorized.
  /// Set by AuthNotifier to trigger automatic logout + redirect to login.
  void Function()? onUnauthorized;

  /// Prevents firing onUnauthorized multiple times when several requests
  /// fail with 401 simultaneously (e.g. expired token).
  bool _handlingUnauthorized = false;

  void init() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // ── Retry interceptor — handles transient network failures ──
    // Retries up to 2 times with exponential backoff (1s, 2s) for:
    //   - Connection timeout / send timeout / receive timeout
    //   - SocketException (no internet)
    //   - 502, 503, 504 server errors
    // Does NOT retry: 4xx client errors, POST/PUT/DELETE (not idempotent)
    dio.interceptors.add(_RetryInterceptor(dio));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Use cached token first; fall back to storage read with error handling
          String? token = _cachedToken;
          if (token == null) {
            try {
              token = await _storage.read(key: AppConstants.tokenKey)
                  .timeout(const Duration(seconds: 3), onTimeout: () => null);
              _cachedToken = token;
            } catch (_) {
              // Secure storage may be temporarily unavailable after app restart.
              // Proceed without token — the request will return 401, which
              // triggers a normal re-login flow instead of crashing.
            }
          }
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Store start time for duration measurement
          options.extra['_reqStartMs'] = DateTime.now().millisecondsSinceEpoch;

          appLog.debug('api', 'request_start', '${options.method} ${options.path}',
            endpoint: '${options.method} ${options.path}',
          );

          handler.next(options);
        },
        onResponse: (response, handler) {
          final startMs = response.requestOptions.extra['_reqStartMs'] as int? ?? 0;
          final durationMs = DateTime.now().millisecondsSinceEpoch - startMs;
          final path = response.requestOptions.path;
          final method = response.requestOptions.method;
          final status = response.statusCode ?? 0;
          final requestId = response.headers.value('x-request-id');

          appLog.info('api', 'request_end', '$method $path → $status (${durationMs}ms)',
            endpoint: '$method $path',
            requestId: requestId,
            extra: {'status': status, 'durationMs': durationMs},
          );

          handler.next(response);
        },
        onError: (error, handler) {
          final startMs = error.requestOptions.extra['_reqStartMs'] as int? ?? 0;
          final durationMs = DateTime.now().millisecondsSinceEpoch - startMs;
          final path = error.requestOptions.path;
          final method = error.requestOptions.method;
          final status = error.response?.statusCode ?? 0;
          final requestId = error.response?.headers.value('x-request-id');
          final serverMsg = _extractServerMessage(error);

          appLog.error('api', 'request_failed', '$method $path → $status (${durationMs}ms)',
            endpoint: '$method $path',
            requestId: requestId,
            errorCode: '$status',
            extra: {
              'status': status,
              'durationMs': durationMs,
              'type': error.type.name,
              if (serverMsg != null) 'serverMessage': serverMsg,
            },
          );

          // Auto-logout on 401 — skip for auth endpoints (login/register/etc.)
          // to avoid logout loops during login attempts.
          if (status == 401 && !path.startsWith('/auth/')) {
            if (!_handlingUnauthorized && onUnauthorized != null) {
              _handlingUnauthorized = true;
              appLog.warn('api', 'token_expired', 'Got 401 — triggering auto-logout');
              onUnauthorized!();
              // Reset after a short delay so future 401s (after re-login) work
              Future.delayed(const Duration(seconds: 2), () {
                _handlingUnauthorized = false;
              });
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  String? _extractServerMessage(DioException error) {
    try {
      final data = error.response?.data;
      if (data is Map) return data['message'] as String?;
    } catch (_) {}
    return null;
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      _cachedToken = await _storage.read(key: AppConstants.tokenKey)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (_) {}
    return _cachedToken;
  }

  Future<void> setToken(String token) async {
    _cachedToken = token;
    try {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    } catch (_) {
      // Keychain may be temporarily locked on iOS — token is still cached
      // in memory and will be persisted on the next successful write.
    }
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    try {
      await _storage.delete(key: AppConstants.tokenKey);
    } catch (_) {
      // Keychain may be temporarily locked — token already cleared from memory.
    }
  }
}

final apiClient = ApiClient();

// ═══════════════════════════════════════════════════════════
// Retry Interceptor — auto-retries transient network failures
// ═══════════════════════════════════════════════════════════
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  static const _maxRetries = 2;
  static const _retryKey = '_retryCount';

  _RetryInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = err.requestOptions.extra[_retryKey] as int? ?? 0;

    // Only retry GET requests (idempotent) and specific error types
    if (retryCount >= _maxRetries ||
        err.requestOptions.method != 'GET' ||
        !_shouldRetry(err)) {
      return handler.next(err);
    }

    final nextRetry = retryCount + 1;
    final delayMs = 1000 * nextRetry; // 1s, 2s exponential backoff

    appLog.warn('api', 'retry',
      '${err.requestOptions.method} ${err.requestOptions.path} — retry $nextRetry/$_maxRetries in ${delayMs}ms',
      extra: {'reason': err.type.name, 'status': err.response?.statusCode ?? 0},
    );

    await Future.delayed(Duration(milliseconds: delayMs));

    // Clone the request with incremented retry count
    final opts = err.requestOptions;
    opts.extra[_retryKey] = nextRetry;

    try {
      final response = await _dio.fetch(opts);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    // Network-level failures (no internet, DNS, timeout)
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // SocketException (wrapped inside DioExceptionType.unknown)
    if (err.type == DioExceptionType.unknown && err.error is SocketException) {
      return true;
    }

    // Server-side transient errors
    final status = err.response?.statusCode ?? 0;
    if (status == 502 || status == 503 || status == 504) {
      return true;
    }

    return false;
  }
}
