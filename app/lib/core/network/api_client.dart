import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../services/app_logger.dart';
import '../services/connectivity_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Reference to the connectivity notifier — set once from the provider
  /// so every API call can report its network result.
  ConnectivityNotifier? connectivityNotifier;

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
  String? _cachedRefreshToken;

  /// Callback invoked when token refresh also fails — true logout.
  /// Set by AuthNotifier to trigger automatic logout + redirect to login.
  void Function()? onUnauthorized;

  /// Prevents firing onUnauthorized multiple times when several requests
  /// fail with 401 simultaneously (e.g. expired token).
  bool _handlingUnauthorized = false;

  /// Guards concurrent refresh: only one refresh call at a time.
  /// Other 401'd requests wait for this completer.
  Completer<bool>? _refreshCompleter;

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

          // ── Report to connectivity: server responded = network works ──
          connectivityNotifier?.reportApiResult(networkReachable: true);

          handler.next(response);
        },
        onError: (error, handler) async {
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

          // ── Report to connectivity ──────────────────────────────
          if (error.response != null) {
            connectivityNotifier?.reportApiResult(networkReachable: true);
          } else if (_isNetworkError(error)) {
            connectivityNotifier?.reportApiResult(networkReachable: false);
          }

          // ── 401 Token Refresh Logic ─────────────────────────────
          // Skip for auth endpoints (login/register/refresh) to avoid loops.
          // Skip if this request was already a retry after refresh.
          if (status == 401 &&
              !path.startsWith('/auth/') &&
              error.requestOptions.extra['_isRetryAfterRefresh'] != true) {

            final refreshed = await _attemptTokenRefresh();
            if (refreshed) {
              // Retry the original request with the new token
              try {
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $_cachedToken';
                opts.extra['_isRetryAfterRefresh'] = true;
                final response = await dio.fetch(opts);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            } else {
              // Refresh failed — truly unauthorized, logout
              if (!_handlingUnauthorized && onUnauthorized != null) {
                _handlingUnauthorized = true;
                appLog.warn('api', 'token_expired', 'Refresh failed — triggering auto-logout');
                onUnauthorized!();
                Future.delayed(const Duration(seconds: 2), () {
                  _handlingUnauthorized = false;
                });
              }
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  /// Attempts to refresh the access token using the stored refresh token.
  /// Returns true if refresh succeeded, false otherwise.
  /// Ensures only one refresh request runs at a time — concurrent 401s
  /// wait for the same refresh call.
  Future<bool> _attemptTokenRefresh() async {
    // If already refreshing, wait for that to finish
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        appLog.warn('api', 'refresh_no_token', 'No refresh token available');
        _refreshCompleter!.complete(false);
        return false;
      }

      appLog.info('api', 'token_refresh_start', 'Attempting token refresh');

      // Use a separate Dio instance to avoid interceptor loops
      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ));

      final resp = await refreshDio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      final data = resp.data['data'] as Map<String, dynamic>;
      final newToken = data['token'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await setToken(newToken);
      await setRefreshToken(newRefreshToken);

      appLog.info('api', 'token_refresh_success', 'Token refreshed successfully');
      _refreshCompleter!.complete(true);
      return true;
    } catch (e) {
      appLog.warn('api', 'token_refresh_failed', 'Token refresh failed: $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Returns true if the error is a genuine network failure
  /// (not a server-side HTTP error).
  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.type == DioExceptionType.unknown && error.error is SocketException);
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
    _cachedRefreshToken = null;
    try {
      await _storage.delete(key: AppConstants.tokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
    } catch (_) {
      // Keychain may be temporarily locked — tokens already cleared from memory.
    }
  }

  Future<String?> _getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    try {
      _cachedRefreshToken = await _storage.read(key: AppConstants.refreshTokenKey)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (_) {}
    return _cachedRefreshToken;
  }

  Future<void> setRefreshToken(String token) async {
    _cachedRefreshToken = token;
    try {
      await _storage.write(key: AppConstants.refreshTokenKey, value: token);
    } catch (_) {}
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
