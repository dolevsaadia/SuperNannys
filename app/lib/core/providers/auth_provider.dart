import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';
import '../services/app_logger.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) => AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  AuthState logout() => const AuthState();
}

class GoogleLoginResult {
  final bool success;
  final bool isNewUser;
  final bool pendingVerification;
  final String? email;
  final String? error;

  const GoogleLoginResult({
    required this.success,
    this.isNewUser = false,
    this.pendingVerification = false,
    this.email,
    this.error,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    try {
      // Timeout protects against iOS keychain hangs (when accessibility
      // policy changed and old entries deadlock on read).
      final token = await _storage.read(key: AppConstants.tokenKey)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      final userData = await _storage.read(key: AppConstants.userKey)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      if (token != null && userData != null) {
        // Sync the in-memory cache in ApiClient so the interceptor has the
        // token immediately without needing another storage read.
        await apiClient.setToken(token);
        final user = UserModel.fromJson(jsonDecode(userData) as Map<String, dynamic>);
        state = AuthState(user: user);
        // Verify token is still valid
        await refreshMe();
      } else {
        // No stored session — done loading
        state = const AuthState();
      }
    } catch (_) {
      // Storage read may fail on first launch after reboot (keychain locked).
      // Silently fall back to logged-out state — user can sign in again.
      try { await logout(); } catch (_) {}
    }
  }

  Future<bool> login(String email, String password) async {
    appLog.info('auth', 'login_start', 'Email login attempt', extra: {'email': email.toLowerCase()});
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await apiClient.dio.post('/auth/login', data: {'email': email.toLowerCase(), 'password': password});
      final data = resp.data['data'] as Map<String, dynamic>;
      await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>);
      appLog.info('auth', 'login_success', 'Email login succeeded');
      return true;
    } catch (e) {
      final err = _extractError(e);
      appLog.warn('auth', 'login_failed', 'Email login failed: $err');
      state = state.copyWith(isLoading: false, error: err);
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName, String role, {String? phone, String? idNumber}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await apiClient.dio.post('/auth/register', data: {
        'email': email.toLowerCase(), 'password': password, 'fullName': fullName, 'role': role,
        if (phone != null) 'phone': phone,
        if (idNumber != null) 'idNumber': idNumber,
      });
      final data = resp.data['data'] as Map<String, dynamic>;
      await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<GoogleLoginResult> loginWithGoogle(String idToken, {String? role}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final body = <String, dynamic>{'idToken': idToken};
      if (role != null) body['role'] = role;
      final resp = await apiClient.dio.post('/auth/google', data: body);
      final data = resp.data['data'] as Map<String, dynamic>;
      final isNewUser = data['isNewUser'] == true;
      final pendingVerification = data['pendingVerification'] == true;

      if (pendingVerification) {
        state = state.copyWith(isLoading: false);
        return GoogleLoginResult(
          success: true,
          pendingVerification: true,
          email: data['email'] as String?,
          isNewUser: isNewUser,
        );
      }

      if (isNewUser && data['token'] == null) {
        // New user needs role selection — don't save session yet
        state = state.copyWith(isLoading: false);
        return GoogleLoginResult(success: true, isNewUser: true);
      }

      await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>);
      return GoogleLoginResult(success: true, isNewUser: isNewUser);
    } catch (e) {
      final err = _extractError(e);
      state = state.copyWith(isLoading: false, error: err);
      return GoogleLoginResult(success: false, error: err);
    }
  }

  /// Restore session from a saved JWT token (used for biometric login)
  Future<bool> restoreWithToken(String token) async {
    appLog.info('auth', 'biometric_restore_start', 'Restoring session from biometric token');
    state = state.copyWith(isLoading: true, error: null);
    try {
      await apiClient.setToken(token);
      await _storage.write(key: AppConstants.tokenKey, value: token);
      final resp = await apiClient.dio.get('/auth/me');
      final user = UserModel.fromJson(resp.data['data'] as Map<String, dynamic>);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      state = AuthState(user: user);
      appLog.info('auth', 'biometric_restore_success', 'Biometric session restored',
        extra: {'userId': user.id},
      );
      appLog.setUserId(user.id);
      return true;
    } catch (e) {
      appLog.warn('auth', 'biometric_restore_failed', 'Failed to restore biometric session',
        extra: {'error': e.toString()},
      );
      await apiClient.clearToken();
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Get the current stored token (for biometric save)
  Future<String?> getStoredToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshMe() async {
    try {
      final resp = await apiClient.dio.get('/auth/me');
      final user = UserModel.fromJson(resp.data['data'] as Map<String, dynamic>);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      state = state.copyWith(user: user, isLoading: false);
    } catch (_) {
      // If token invalid, logout
      await logout();
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
    } catch (_) {}
    state = state.copyWith(user: user);
  }

  /// Complete login after OTP verification (called from OTP screen)
  Future<void> loginWithVerifiedToken(String token, Map<String, dynamic> userData) async {
    await _saveSession(token, userData);
  }

  Future<void> _saveSession(String token, Map<String, dynamic> userData) async {
    await apiClient.setToken(token);
    try {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    } catch (_) {}
    final user = UserModel.fromJson(userData);
    try {
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(userData));
    } catch (_) {}
    state = AuthState(user: user);
    appLog.setUserId(user.id);
    appLog.info('auth', 'session_saved', 'Session saved', extra: {'userId': user.id, 'role': user.role});
  }

  Future<void> logout() async {
    appLog.info('auth', 'logout', 'User logged out');
    appLog.setUserId(null);
    await apiClient.clearToken();
    try {
      await _storage.delete(key: AppConstants.userKey);
    } catch (_) {}
    state = const AuthState();
  }

  String _extractError(dynamic e) {
    try {
      final resp = (e as dynamic).response;
      return resp?.data?['message'] as String? ?? 'Something went wrong';
    } catch (_) {
      return 'Network error. Please check your connection.';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
final currentUserProvider = Provider<UserModel?>((ref) => ref.watch(authProvider).user);
