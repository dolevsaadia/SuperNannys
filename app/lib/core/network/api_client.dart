import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

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
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
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
