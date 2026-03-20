import 'dart:async';
import 'dart:convert';
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

  /// Callback for showing a friendly "session expired" dialog before logout.
  /// Unlike onUnauthorized (which fires silently), this shows a dialog first.
  void Function()? onSessionExpired;

  /// Prevents firing onUnauthorized multiple times when several requests
  /// fail with 401 simultaneously (e.g. expired token).
  bool _handlingUnauthorized = false;

  /// Guards concurrent refresh: only one refresh call at a time.
  /// Other 401'd requests wait for this completer.
  Completer<bool>? _refreshCompleter;

  /// Proactive refresh: schedules a refresh BEFORE the token expires
  /// so the user never sees a 401 error or gets logged out unexpectedly.
  Timer? _proactiveRefreshTimer;
  int? _tokenExpiresAtMs;

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
              // Refresh failed — truly unauthorized
              _triggerSessionExpired();
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

  // ═══════════════════════════════════════════════════════════
  // Proactive Token Refresh
  // ═══════════════════════════════════════════════════════════

  /// Schedule a background refresh at ~80% of the token's lifetime.
  /// Example: 7-day token → refresh after ~5.6 days.
  void scheduleProactiveRefresh(int expiresAtMs) {
    _tokenExpiresAtMs = expiresAtMs;
    _proactiveRefreshTimer?.cancel();

    final now = DateTime.now().millisecondsSinceEpoch;
    final lifetimeMs = expiresAtMs - now;
    if (lifetimeMs <= 0) return; // already expired

    // Refresh at 80% of lifetime
    final refreshInMs = (lifetimeMs * 0.8).toInt();
    appLog.info('api', 'proactive_refresh_scheduled',
      'Token refresh scheduled in ${(refreshInMs / 1000 / 60).toStringAsFixed(0)}min '
      '(token lifetime: ${(lifetimeMs / 1000 / 60 / 60).toStringAsFixed(1)}h)',
    );

    _proactiveRefreshTimer = Timer(Duration(milliseconds: refreshInMs), _doProactiveRefresh);
  }

  Future<void> _doProactiveRefresh() async {
    appLog.info('api', 'proactive_refresh_start', 'Running proactive token refresh');
    final success = await _attemptTokenRefresh();
    if (success) {
      // After successful refresh, the new token's expiry is unknown unless
      // we decode it. Use the JWT exp claim as fallback.
      final exp = extractExpFromJwt(_cachedToken);
      if (exp != null) {
        scheduleProactiveRefresh(exp * 1000);
      }
    } else {
      _triggerSessionExpired();
    }
  }

  /// Called on app resume — checks if token is expired or close to expiry
  /// and refreshes if needed. Returns true if session is valid.
  Future<bool> validateTokenOrRefresh() async {
    final token = _cachedToken ?? await getToken();
    if (token == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Use stored expiresAt first, fall back to JWT decode
    int? expiresAtMs = _tokenExpiresAtMs;
    if (expiresAtMs == null) {
      final exp = extractExpFromJwt(token);
      if (exp != null) expiresAtMs = exp * 1000;
    }

    if (expiresAtMs == null) return true; // can't determine — assume valid

    final remainingMs = expiresAtMs - now;

    if (remainingMs <= 0) {
      // Token already expired — try refresh
      appLog.info('api', 'resume_token_expired', 'Token expired on resume — attempting refresh');
      final success = await _attemptTokenRefresh();
      if (success) {
        final exp = extractExpFromJwt(_cachedToken);
        if (exp != null) scheduleProactiveRefresh(exp * 1000);
      }
      return success;
    }

    // If less than 20% lifetime remaining, refresh proactively
    // (e.g., < ~1.4 days for a 7-day token)
    if (expiresAtMs > 0) {
      // Estimate original lifetime: if we have less than 20% left, refresh now
      const thresholdMs = 30 * 60 * 1000; // 30 minutes minimum threshold
      if (remainingMs < thresholdMs) {
        appLog.info('api', 'resume_token_near_expiry',
          'Token near expiry on resume (${(remainingMs / 1000 / 60).toStringAsFixed(0)}min left)');
        final success = await _attemptTokenRefresh();
        if (success) {
          final exp = extractExpFromJwt(_cachedToken);
          if (exp != null) scheduleProactiveRefresh(exp * 1000);
        }
        return success;
      }
    }

    // Token still valid — make sure proactive timer is running
    if (_proactiveRefreshTimer == null || !_proactiveRefreshTimer!.isActive) {
      scheduleProactiveRefresh(expiresAtMs);
    }

    return true;
  }

  void cancelProactiveRefresh() {
    _proactiveRefreshTimer?.cancel();
    _proactiveRefreshTimer = null;
    _tokenExpiresAtMs = null;
  }

  /// Unified handler: show friendly dialog, then logout.
  void _triggerSessionExpired() {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    appLog.warn('api', 'session_expired', 'Session expired — showing dialog');

    if (onSessionExpired != null) {
      onSessionExpired!();
    } else if (onUnauthorized != null) {
      onUnauthorized!();
    }

    Future.delayed(const Duration(seconds: 2), () {
      _handlingUnauthorized = false;
    });
  }

  /// Decode the `exp` claim from a JWT without verifying signature.
  /// Returns the Unix timestamp (seconds) or null if decoding fails.
  static int? extractExpFromJwt(String? token) {
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      // JWT payload is base64url-encoded
      String payload = parts[1];
      // Pad to multiple of 4
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return map['exp'] as int?;
    } catch (_) {
      return null;
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
