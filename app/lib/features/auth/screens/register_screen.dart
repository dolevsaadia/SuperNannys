import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

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
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).register(
      _email.text.trim(), _password.text, _name.text.trim(), _role,
    );
    if (!mounted) return;
    if (success) {
      context.go(_role == 'NANNY' ? '/nanny-onboarding' : '/home');
    } else {
      final err = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Registration failed'), backgroundColor: AppColors.error),
      );
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
                          if (v?.isEmpty == true) return 'Email is required';
                          if (!v!.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Password',
                        controller: _password,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textHint),
                        validator: (v) => (v?.length ?? 0) < 8 ? 'Password must be at least 8 characters' : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
