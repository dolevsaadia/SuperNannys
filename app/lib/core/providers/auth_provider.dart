import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';

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
  final String? error;

  const GoogleLoginResult({required this.success, this.isNewUser = false, this.error});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;

  AuthNotifier() : _storage = const FlutterSecureStorage(), super(const AuthState()) {
    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      final userData = await _storage.read(key: AppConstants.userKey);
      if (token != null && userData != null) {
        final user = UserModel.fromJson(jsonDecode(userData) as Map<String, dynamic>);
        state = AuthState(user: user);
        // Verify token is still valid
        await refreshMe();
      }
    } catch (_) {
      await logout();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await apiClient.dio.post('/auth/login', data: {'email': email, 'password': password});
      final data = resp.data['data'] as Map<String, dynamic>;
      await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await apiClient.dio.post('/auth/register', data: {
        'email': email, 'password': password, 'fullName': fullName, 'role': role,
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
      await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>);
      return GoogleLoginResult(success: true, isNewUser: isNewUser);
    } catch (e) {
      final err = _extractError(e);
      state = state.copyWith(isLoading: false, error: err);
      return GoogleLoginResult(success: false, error: err);
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
    await _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
    state = state.copyWith(user: user);
  }

  Future<void> _saveSession(String token, Map<String, dynamic> userData) async {
    await apiClient.setToken(token);
    final user = UserModel.fromJson(userData);
    await _storage.write(key: AppConstants.userKey, value: jsonEncode(userData));
    state = AuthState(user: user);
  }

  Future<void> logout() async {
    await apiClient.clearToken();
    await _storage.delete(key: AppConstants.userKey);
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
