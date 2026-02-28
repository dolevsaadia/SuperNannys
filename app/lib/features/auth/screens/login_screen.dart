import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Whether Google Sign-In has real credentials configured
  bool get _isGoogleConfigured {
    // On Android we need google-services.json (checked at build time)
    // On iOS we need a real URL scheme (not the placeholder)
    // Both need a serverClientId for backend token verification
    // If the env var is empty, credentials are not configured
    return AppConstants.googleServerClientId.isNotEmpty;
  }

  Future<void> _googleSignIn() async {
    if (!_isGoogleConfigured) {
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
          // New user from Google — redirect to role selection
          context.go('/role-select', extra: {'googleIdToken': idToken});
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Google login failed'), backgroundColor: AppColors.error),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.code == 'sign_in_failed'
                ? 'Google Sign-In is not configured for this app.'
                : 'Google Sign-In error: ${e.message}'),
            backgroundColor: AppColors.error,
          ),
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (success) {
      context.go('/home');
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

                // ── Brand Logo with glow ─────────────
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientPrimary,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppShadows.primaryGlow(0.3),
                  ),
                  child: const Icon(Icons.child_care_rounded, size: 44, color: Colors.white),
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
                _GoogleButton(onTap: _googleSignIn),
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

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

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
            SvgPicture.asset('assets/images/google_logo.svg', width: 20, height: 20),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
