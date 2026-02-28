import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'I am a...',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your role to get started',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              _RoleCard(
                title: 'Parent',
                subtitle: 'I want to find and hire a babysitter for my children',
                emoji: '\uD83D\uDC68\u200D\uD83D\uDC69\u200D\uD83D\uDC67',
                color: AppColors.primary,
                selected: _selected == 'PARENT',
                onTap: () => setState(() => _selected = 'PARENT'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Nanny / Babysitter',
                subtitle: 'I want to offer childcare services and find families',
                emoji: '\uD83D\uDC76',
                color: AppColors.accent,
                selected: _selected == 'NANNY',
                onTap: () => setState(() => _selected = 'NANNY'),
              ),
              const Spacer(),
              AppButton(
                label: 'Continue',
                onTap: _selected == null
                    ? null
                    : () => context.go('/register', extra: {'role': _selected}),
              ),
              const SizedBox(height: 12),
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
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 2 : 1),
            boxShadow: selected ? AppShadows.md : AppShadows.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.12) : AppColors.bg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: selected ? color : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color : Colors.transparent,
                  border: Border.all(color: selected ? color : AppColors.border, width: 2),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      );
}
