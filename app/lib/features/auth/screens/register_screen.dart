import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
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
  final _phone = TextEditingController();
  String _role = 'PARENT';
  DateTime? _dateOfBirth;

  // Google flow data
  String? _googleIdToken;
  bool get _isGoogleFlow => _googleIdToken != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map) {
        setState(() {
          _role = extra['role'] as String? ?? 'PARENT';
          // Prefill Google data if available
          final googleToken = extra['googleIdToken'] as String?;
          if (googleToken != null) {
            _googleIdToken = googleToken;
            final googleEmail = extra['googleEmail'] as String?;
            final googleName = extra['googleName'] as String?;
            if (googleEmail != null) _email.text = googleEmail;
            if (googleName != null) _name.text = googleName;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Validate email format with regex
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  String _roleBasedRoute() {
    final user = ref.read(authProvider).user;
    if (user?.isAdmin == true) return '/admin';
    if (user?.isNanny == true) return '/dashboard';
    return '/home';
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 13, now.month, now.day), // Must be at least 13
      helpText: 'Select your date of birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth'), backgroundColor: AppColors.error),
      );
      return;
    }

    final dobStr = _dateOfBirth!.toIso8601String().split('T').first; // "2000-01-15"

    if (_isGoogleFlow) {
      // Google registration — use loginWithGoogle with additional data
      final result = await ref.read(authProvider.notifier).loginWithGoogle(
        _googleIdToken!,
        role: _role,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        dateOfBirth: dobStr,
      );
      if (!mounted) return;
      if (result.success) {
        final route = _role == 'NANNY' ? '/nanny-onboarding' : _roleBasedRoute();
        context.go(route);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Registration failed'), backgroundColor: AppColors.error),
        );
      }
    } else {
      // Email registration
      final success = await ref.read(authProvider.notifier).register(
        _email.text.trim().toLowerCase(),
        _password.text,
        _name.text.trim(),
        _role,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        dateOfBirth: dobStr,
      );
      if (!mounted) return;
      if (success) {
        final route = _role == 'NANNY' ? '/nanny-onboarding' : '/home';
        context.go(route);
      } else {
        final err = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Registration failed'), backgroundColor: AppColors.error),
        );
      }
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

      // Prefill Google data into the form instead of registering immediately
      if (mounted) {
        setState(() {
          _googleIdToken = idToken;
          _name.text = googleUser.displayName ?? '';
          _email.text = googleUser.email;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google account linked! Please complete the remaining fields.'),
            backgroundColor: AppColors.success,
          ),
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

                // ── Google Sign-Up (only if NOT already in Google flow) ──
                if (!_isGoogleFlow) ...[
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
                ],

                // ── Google linked badge ──────────────
                if (_isGoogleFlow) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Google account linked. Complete the fields below to finish registration.',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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
                        readOnly: _isGoogleFlow && _name.text.isNotEmpty,
                        prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.textHint),
                        validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Enter your full name' : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Email',
                        hint: 'your@email.com',
                        controller: _email,
                        readOnly: _isGoogleFlow,
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

                      // ── Date of Birth picker ──────────
                      GestureDetector(
                        onTap: _pickDateOfBirth,
                        child: AbsorbPointer(
                          child: AppTextField(
                            label: 'Date of Birth',
                            hint: 'Select your date of birth',
                            controller: TextEditingController(
                              text: _dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!) : '',
                            ),
                            prefixIcon: const Icon(Icons.cake_outlined, size: 20, color: AppColors.textHint),
                            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textHint),
                            validator: (_) {
                              if (_dateOfBirth == null) return 'Date of birth is required';
                              return null;
                            },
                          ),
                        ),
                      ),

                      // ── Password (only for email registration) ──
                      if (!_isGoogleFlow) ...[
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Password',
                          controller: _password,
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textHint),
                          validator: (v) {
                            if (_isGoogleFlow) return null; // no password needed for Google
                            if (v == null || v.length < 8) return 'Password must be at least 8 characters';
                            if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) {
                              return 'Password must contain letters and numbers';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      AppButton(
                        label: _isGoogleFlow ? 'Complete Registration' : 'Create Account',
                        onTap: _register,
                        isLoading: isLoading,
                      ),
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
