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

  void init() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

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
