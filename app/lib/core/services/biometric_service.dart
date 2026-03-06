import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._();
  factory BiometricService() => _instance;
  BiometricService._();

  final _auth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();

  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kBiometricToken = 'biometric_token';

  /// Check if device has biometric hardware (Face ID / Fingerprint)
  Future<bool> get isDeviceSupported async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Check if biometrics are enrolled on the device
  Future<bool> get isBiometricEnrolled async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Check if biometric login is enabled by the user
  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  /// Check if biometrics are ready to use (hardware + enrolled + user enabled)
  Future<bool> get isAvailable async {
    return await isDeviceSupported && await isBiometricEnrolled && await isEnabled;
  }

  /// Get available biometric types (face, fingerprint, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate user with biometrics
  Future<bool> authenticate({String reason = 'Authenticate to sign in'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  /// Save token for biometric login
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _kBiometricToken, value: token);
  }

  /// Get saved token for biometric login
  Future<String?> getSavedToken() async {
    return await _secureStorage.read(key: _kBiometricToken);
  }

  /// Enable biometric login and store the session token
  Future<void> enable(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, true);
    await saveToken(token);
  }

  /// Disable biometric login
  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, false);
    await _secureStorage.delete(key: _kBiometricToken);
  }
}
