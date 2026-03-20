import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of a biometric authentication attempt.
/// Clearly distinguishes between success, user cancellation,
/// unavailable hardware, and real errors.
enum BiometricResult {
  /// User authenticated successfully
  success,

  /// User explicitly cancelled (pressed X / Cancel / swipe-away)
  cancelledByUser,

  /// Biometric not available (no hardware or not enrolled)
  unavailable,

  /// Biometric is locked out (too many failed attempts)
  lockedOut,

  /// Timed out waiting for user interaction
  timeout,

  /// A real unexpected error occurred
  error,
}

class BiometricService {
  static final BiometricService _instance = BiometricService._();
  factory BiometricService() => _instance;
  BiometricService._();

  final _auth = LocalAuthentication();
  static const _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kBiometricToken = 'biometric_token';

  /// Last error message from a failed biometric attempt (for UI display)
  String? lastError;

  /// Check if device has biometric hardware (Face ID / Fingerprint)
  Future<bool> get isDeviceSupported async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Check if biometrics are actually enrolled on the device
  Future<bool> get isBiometricEnrolled async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
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

  /// Authenticate user with biometrics.
  /// Returns a [BiometricResult] that clearly indicates what happened.
  /// Never throws — all outcomes are captured in the result enum.
  /// Includes a 30-second timeout to prevent indefinite hanging.
  Future<BiometricResult> authenticate({String reason = 'Authenticate to sign in'}) async {
    lastError = null;

    // Cancel any stale authentication sessions first
    try { await _auth.stopAuthentication(); } catch (_) {}

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        debugPrint('[Biometric] authenticate timed out after 30s');
        return false;
      });

      if (authenticated) {
        debugPrint('[Biometric] authentication succeeded');
        return BiometricResult.success;
      }

      // authenticate() returns false when user cancels or times out.
      // This is a perfectly normal outcome — NOT an error.
      debugPrint('[Biometric] authentication returned false (user cancelled or dismissed)');
      return BiometricResult.cancelledByUser;
    } on LocalAuthException catch (e) {
      // local_auth v3+ throws LocalAuthException with typed codes
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.authInProgress:
        case LocalAuthExceptionCode.userRequestedFallback:
          debugPrint('[Biometric] user cancelled via LocalAuthException: ${e.code.name}');
          return BiometricResult.cancelledByUser;

        case LocalAuthExceptionCode.timeout:
          debugPrint('[Biometric] timed out via LocalAuthException');
          return BiometricResult.timeout;

        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        case LocalAuthExceptionCode.uiUnavailable:
          debugPrint('[Biometric] unavailable via LocalAuthException: ${e.code.name}');
          lastError = 'Biometric is not set up. Please enable it in your device settings.';
          return BiometricResult.unavailable;

        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          debugPrint('[Biometric] locked out via LocalAuthException: ${e.code.name}');
          lastError = 'Biometric is locked. Try again later or use your passcode.';
          return BiometricResult.lockedOut;

        default:
          debugPrint('[Biometric] error via LocalAuthException: ${e.code.name} — ${e.description}');
          lastError = 'Biometric error: ${e.description ?? e.code.name}';
          return BiometricResult.error;
      }
    } on PlatformException catch (e) {
      // Fallback for older platform channels that still throw PlatformException
      final code = e.code;
      final msg = e.message ?? '';
      final combined = '$code $msg'.toLowerCase();

      if (combined.contains('notavailable') ||
          combined.contains('not available') ||
          combined.contains('nobiometricsenrolled') ||
          combined.contains('not enrolled')) {
        debugPrint('[Biometric] not available/enrolled: $code');
        lastError = 'Biometric is not set up. Please enable it in your device settings.';
        return BiometricResult.unavailable;
      }

      if (combined.contains('lockedout') ||
          combined.contains('locked out') ||
          combined.contains('permanentlylocked')) {
        debugPrint('[Biometric] locked out: $code');
        lastError = 'Biometric is locked. Try again later or use your passcode.';
        return BiometricResult.lockedOut;
      }

      // User cancelled via platform exception (some Android devices report
      // cancellation this way instead of returning false)
      if (combined.contains('notfragment') ||
          combined.contains('user canceled') ||
          combined.contains('canceled') ||
          combined.contains('cancelled') ||
          code == 'auth_in_progress') {
        debugPrint('[Biometric] user cancelled via PlatformException: $code');
        return BiometricResult.cancelledByUser;
      }

      // Genuine error
      debugPrint('[Biometric] error: $code — $msg');
      lastError = 'Biometric error: ${e.message ?? e.code}';
      return BiometricResult.error;
    } catch (e) {
      // Any other unexpected error — log it, don't crash
      debugPrint('[Biometric] unexpected error: $e');
      lastError = 'Biometric error: $e';
      return BiometricResult.error;
    }
  }

  /// Save token for biometric login
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _kBiometricToken, value: token);
    } catch (_) {
      // Keychain may be temporarily locked on iOS after reboot
    }
  }

  /// Get saved token for biometric login
  Future<String?> getSavedToken() async {
    try {
      return await _secureStorage.read(key: _kBiometricToken)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (_) {
      return null;
    }
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
    try {
      await _secureStorage.delete(key: _kBiometricToken);
    } catch (_) {}
  }
}
