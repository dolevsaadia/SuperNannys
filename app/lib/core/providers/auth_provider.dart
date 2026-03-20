import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';
import '../services/app_logger.dart';
import '../widgets/session_expired_dialog.dart';

/// Global navigator key — shared with GoRouter so we can show dialogs
/// from AuthNotifier without needing a BuildContext from the widget tree.
final navigatorKey = GlobalKey<NavigatorState>();

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

  late final _LifecycleObserver _lifecycleObserver;
  bool _isShowingSessionDialog = false;

  AuthNotifier() : super(const AuthState(isLoading: true)) {
    // Hook session-expired: show friendly dialog, then logout
    apiClient.onSessionExpired = _showSessionExpiredAndLogout;

    // Fallback for legacy behavior
    apiClient.onUnauthorized = () {
      if (state.isAuthenticated) {
        appLog.warn('auth', 'auto_logout', 'Token expired — logging out automatically');
        logout();
      }
    };

    // Observe app lifecycle so we validate tokens on resume
    _lifecycleObserver = _LifecycleObserver(onResumed: _onAppResumed);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    _loadStoredUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    apiClient.cancelProactiveRefresh();
    super.dispose();
  }

  /// Called when app comes back from background.
  Future<void> _onAppResumed() async {
    if (!state.isAuthenticated) return;
    appLog.debug('auth', 'app_resumed', 'Validating token after app resume');
    final valid = await apiClient.validateTokenOrRefresh();
    if (!valid) {
      _showSessionExpiredAndLogout();
    }
  }

  /// Show a friendly dialog, wait for dismissal, then logout.
  void _showSessionExpiredAndLogout() {
    if (_isShowingSessionDialog || !state.isAuthenticated) return;
    _isShowingSessionDialog = true;

    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      showSessionExpiredDialog(ctx).then((_) {
        _isShowingSessionDialog = false;
        logout();
      });
    } else {
      // No context available — just logout silently
      _isShowingSessionDialog = false;
      logout();
    }
  }

  Future<void> _loadStoredUser() async {
    try {
      // Timeout protects against iOS keychain hangs (when accessibility
      // policy changed and old entries deadlock on read).
      final token = await _storage.read(key: AppConstants.tokenKey)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      final userData = await _storage.read(key: AppConstants.userKey)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      if (token != null && userData != null) {
        // Sync the in-memory cache in ApiClient so the interceptor has the
        // token immediately without needing another storage read.
        await apiClient.setToken(token);
        if (refreshToken != null) {
          await apiClient.setRefreshToken(refreshToken);
        }

        // Schedule proactive refresh based on JWT exp claim
        final exp = ApiClient.extractExpFromJwt(token);
        if (exp != null) {
          apiClient.scheduleProactiveRefresh(exp * 1000);
        }

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
      await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>,
          refreshToken: data['refreshToken'] as String?,
          expiresAt: data['expiresAt'] as int?);
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
      await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>,
          refreshToken: data['refreshToken'] as String?,
          expiresAt: data['expiresAt'] as int?);
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
        return const GoogleLoginResult(success: true, isNewUser: true);
      }

      await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>,
          refreshToken: data['refreshToken'] as String?,
          expiresAt: data['expiresAt'] as int?);
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
    } catch (e) {
      // /auth/me is excluded from the interceptor's 401 handler (it starts
      // with /auth/), so we handle it explicitly here.
      appLog.warn('auth', 'refresh_me_failed', 'Token validation failed — logging out',
        extra: {'error': e.toString()},
      );
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
  Future<void> loginWithVerifiedToken(String token, Map<String, dynamic> userData, {String? refreshToken, int? expiresAt}) async {
    await _saveSession(token, userData, refreshToken: refreshToken, expiresAt: expiresAt);
  }

  Future<void> _saveSession(String token, Map<String, dynamic> userData, {String? refreshToken, int? expiresAt}) async {
    await apiClient.setToken(token);
    if (refreshToken != null) {
      await apiClient.setRefreshToken(refreshToken);
    }
    try {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    } catch (_) {}

    // Schedule proactive refresh: prefer server-provided expiresAt, fallback to JWT decode
    final expiresAtMs = expiresAt ?? ((ApiClient.extractExpFromJwt(token) ?? 0) * 1000);
    if (expiresAtMs > 0) {
      apiClient.scheduleProactiveRefresh(expiresAtMs);
    }

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
    apiClient.cancelProactiveRefresh();
    await apiClient.clearToken();
    try {
      await _storage.delete(key: AppConstants.userKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
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

/// Observes app lifecycle transitions (background ↔ foreground).
class _LifecycleObserver extends WidgetsBindingObserver {
  final Future<void> Function() onResumed;
  _LifecycleObserver({required this.onResumed});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
