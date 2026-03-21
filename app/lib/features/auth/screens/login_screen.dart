import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/biometric_prompt_dialog.dart';
import '../../../core/widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _biometric = BiometricService();
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    // Only show biometric buttons if user has previously enabled biometric login
    final isEnabled = await _biometric.isEnabled;
    if (!isEnabled) return;

    final supported = await _biometric.isDeviceSupported;
    if (supported) {
      var types = await _biometric.getAvailableBiometrics();
      if (types.isEmpty) {
        if (Platform.isIOS) {
          types = [BiometricType.face];
        } else {
          types = [BiometricType.fingerprint];
        }
      }
      if (mounted) {
        setState(() => _availableBiometrics = types);
        // Auto-trigger biometric login after a short delay so the UI renders first
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && types.isNotEmpty) {
            _biometricLogin(types.first);
          }
        });
      }
    }
  }

  String _labelForType(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Platform.isIOS ? 'Face ID' : 'Face Recognition';
      case BiometricType.fingerprint:
      case BiometricType.strong:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scan';
      default:
        return 'Biometric';
    }
  }

  Future<void> _biometricLogin(BiometricType type) async {
    final label = _labelForType(type);

    // Check if user has a saved biometric session
    final isEnabled = await _biometric.isEnabled;
    final token = await _biometric.getSavedToken();

    if (!isEnabled || token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in first to enable $label for quick login.'),
          backgroundColor: AppColors.textSecondary,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Authenticate with biometrics — result is never an exception
    appLog.debug('auth', 'biometric_prompt', 'Showing $label prompt');
    final result = await _biometric.authenticate(
      reason: 'Use $label to sign in',
    );

    if (!mounted) return;

    appLog.debug('auth', 'biometric_result', 'Biometric result: ${result.name}');

    switch (result) {
      case BiometricResult.success:
        // Biometric succeeded — restore the session
        break;

      case BiometricResult.cancelledByUser:
      case BiometricResult.timeout:
        // User cancelled or prompt timed out — this is a normal UI action.
        // Silently fall back to manual login. No error, no toast, no log.
        return;

      case BiometricResult.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label is not set up. Please enable it in your device settings first.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        return;

      case BiometricResult.lockedOut:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label is locked. Try again later or use your passcode.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        return;

      case BiometricResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_biometric.lastError ?? '$label error occurred.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
    }

    // Restore session with saved token
    final success = await ref.read(authProvider.notifier).restoreWithToken(token);
    if (!mounted) return;
    if (success) {
      // Refresh the stored biometric token with the current valid token
      final freshToken = await ref.read(authProvider.notifier).getStoredToken();
      if (freshToken != null) {
        await _biometric.saveToken(freshToken);
      }
      context.go(_roleBasedRoute());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please sign in again.'), backgroundColor: AppColors.error),
      );
      await _biometric.disable();
    }
  }

  Future<void> _googleSignIn() async {
    if (AppConstants.googleServerClientId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In is not configured yet. Please use email login.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: AppConstants.googleServerClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign-In failed: no ID token'), backgroundColor: AppColors.error),
          );
        }
        return;
      }
      final result = await ref.read(authProvider.notifier).loginWithGoogle(idToken);
      if (!mounted) return;
      if (result.success) {
        if (result.isNewUser) {
          // New user from Google — redirect to role selection with profile data
          context.go('/role-select', extra: {
            'googleIdToken': idToken,
            'googleEmail': result.email,
            'googleName': result.fullName,
            'googleAvatar': result.avatarUrl,
          });
        } else {
          await _promptBiometricAndNavigate();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Google login failed'), backgroundColor: AppColors.error),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        final String message;
        if (e.code == 'sign_in_failed' && e.message != null && e.message!.contains('10')) {
          message = 'Google Sign-In configuration error. Please check SHA-1 fingerprint in Firebase Console.';
        } else if (e.code == 'sign_in_canceled') {
          return;
        } else if (e.code == 'network_error') {
          message = 'Network error. Please check your internet connection.';
        } else {
          message = 'Google Sign-In error: ${e.message ?? e.code}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error, duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _roleBasedRoute() {
    final user = ref.read(authProvider).user;
    if (user?.isAdmin == true) return '/admin';
    if (user?.isNanny == true) return '/dashboard';
    return '/home';
  }

  Future<void> _promptBiometricAndNavigate() async {
    final token = await ref.read(authProvider.notifier).getStoredToken();
    if (token != null && mounted) {
      await showBiometricPrompt(context, token);
    }
    if (mounted) context.go(_roleBasedRoute());
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(_email.text.trim().toLowerCase(), _password.text);
    if (!mounted) return;
    if (success) {
      await _promptBiometricAndNavigate();
    } else {
      final err = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Login failed'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 48),

                // ── Brand Logo ─────────────
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppShadows.primaryGlow(0.3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset('assets/brand/app_icon.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Welcome text ─────────────────────
                const Text(
                  'Welcome back!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to your SuperNanny account',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 36),

                // ── Form Card ────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.md,
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Email',
                        hint: 'your@email.com',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textHint),
                        validator: (v) => v?.isEmpty == true || !v!.contains('@') ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Password',
                        controller: _password,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textHint),
                        validator: (v) => (v?.length ?? 0) < 6 ? 'Password too short' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot password?', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(label: 'Sign In', onTap: _login, isLoading: isLoading),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── OR divider ───────────────────────
                Row(children: [
                  Expanded(child: Container(height: 1, color: AppColors.divider)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Container(height: 1, color: AppColors.divider)),
                ]),
                const SizedBox(height: 24),

                // ── Google Sign-In ───────────────────
                GoogleSignInButton(onTap: _googleSignIn),

                // ── Biometric Login ──────────────────
                for (final type in _availableBiometrics) ...[
                  const SizedBox(height: 12),
                  _BiometricButton(
                    onTap: () => _biometricLogin(type),
                    biometricType: type,
                  ),
                ],

                const SizedBox(height: 36),

                // ── Sign up ──────────────────────────
                TextButton(
                  onPressed: () => context.go('/role-select'),
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(text: 'Sign up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  final VoidCallback onTap;
  final BiometricType biometricType;

  const _BiometricButton({required this.onTap, required this.biometricType});

  IconData get _icon {
    switch (biometricType) {
      case BiometricType.face:
        return Icons.face_rounded;
      case BiometricType.fingerprint:
      case BiometricType.strong:
        return Icons.fingerprint_rounded;
      case BiometricType.iris:
        return Icons.remove_red_eye_rounded;
      default:
        return Icons.security_rounded;
    }
  }

  String get _label {
    switch (biometricType) {
      case BiometricType.face:
        return Platform.isIOS ? 'Sign in with Face ID' : 'Sign in with Face Recognition';
      case BiometricType.fingerprint:
      case BiometricType.strong:
        return 'Sign in with Fingerprint';
      case BiometricType.weak:
        return 'Sign in with Biometric';
      case BiometricType.iris:
        return 'Sign in with Iris Scan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1.5),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              _label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
