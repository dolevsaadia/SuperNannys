import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/biometric_prompt_dialog.dart';
import '../../../core/widgets/google_sign_in_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _idNumber = TextEditingController();
  final _phone = TextEditingController();
  String _role = 'PARENT';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map) setState(() => _role = extra['role'] as String? ?? 'PARENT');
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _idNumber.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Validate Israeli ID number (Luhn mod-10 check)
  bool _isValidIsraeliId(String id) {
    if (id.length < 5 || id.length > 9) return false;
    final padded = id.padLeft(9, '0');
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      int digit = int.parse(padded[i]);
      int val = digit * ((i % 2 == 0) ? 1 : 2);
      if (val > 9) val -= 9;
      sum += val;
    }
    return sum % 10 == 0;
  }

  /// Validate email format with regex
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _promptBiometricAndNavigate(String route) async {
    final token = await ref.read(authProvider.notifier).getStoredToken();
    if (token != null && mounted) {
      await showBiometricPrompt(context, token);
    }
    if (mounted) context.go(route);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).register(
      _email.text.trim().toLowerCase(),
      _password.text,
      _name.text.trim(),
      _role,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      idNumber: _idNumber.text.trim().isEmpty ? null : _idNumber.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      // Navigate immediately to prevent GoRouter redirect from racing
      // (auth state change triggers redirect on next microtask which would
      // send nannies to /dashboard before we can navigate to onboarding)
      final route = _role == 'NANNY' ? '/nanny-onboarding' : '/home';
      context.go(route);
    } else {
      final err = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Registration failed'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _googleSignUp() async {
    if (AppConstants.googleServerClientId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In is not configured yet. Please use email registration.'),
            backgroundColor: AppColors.error,
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

      // Register directly with the selected role
      final result = await ref.read(authProvider.notifier).loginWithGoogle(idToken, role: _role);
      if (!mounted) return;
      if (result.success) {
        if (mounted) context.go(_role == 'NANNY' ? '/nanny-onboarding' : '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Google sign-up failed'), backgroundColor: AppColors.error),
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
          message = 'Google Sign-Up error: ${e.message ?? e.code}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error, duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-Up error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final isNanny = _role == 'NANNY';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: BackButton(onPressed: () => context.go('/role-select')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Role Badge ──────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isNanny ? AppColors.gradientAccent : AppColors.gradientPrimary,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isNanny ? Icons.child_care_rounded : Icons.family_restroom_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Signing up as ${isNanny ? 'Nanny' : 'Parent'}',
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Google Sign-Up ──────────────────
                GoogleSignInButton(
                  onTap: _googleSignUp,
                  label: 'Sign up with Google',
                ),
                const SizedBox(height: 20),

                // ── OR divider ──────────────────────
                Row(children: [
                  Expanded(child: Container(height: 1, color: AppColors.divider)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Container(height: 1, color: AppColors.divider)),
                ]),
                const SizedBox(height: 20),

                // ── Form Card ───────────────────────
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
                        label: 'Full Name',
                        hint: 'Your full name',
                        controller: _name,
                        prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.textHint),
                        validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Enter your full name' : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Email',
                        hint: 'your@email.com',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textHint),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!_isValidEmail(v.trim())) return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Phone',
                        hint: '050-1234567',
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.textHint),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null; // optional
                          final cleaned = v.replaceAll(RegExp(r'[\s\-]'), '');
                          if (cleaned.length < 9 || cleaned.length > 13) return 'Enter a valid phone number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'ID Number',
                        hint: 'Israeli ID number',
                        controller: _idNumber,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.textHint),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'ID number is required';
                          if (!_isValidIsraeliId(v.trim())) return 'Enter a valid Israeli ID number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Password',
                        controller: _password,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textHint),
                        validator: (v) {
                          if (v == null || v.length < 8) return 'Password must be at least 8 characters';
                          if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) {
                            return 'Password must contain letters and numbers';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      AppButton(label: 'Create Account', onTap: _register, isLoading: isLoading),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        children: [
                          TextSpan(text: 'Sign in', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ],
                      ),
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
