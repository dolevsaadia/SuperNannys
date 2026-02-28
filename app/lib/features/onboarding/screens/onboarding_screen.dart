import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  final _controller = PageController();

  static const _pages = [
    _OnboardingPage(
      title: 'Find Your Perfect Nanny',
      subtitle: 'Browse hundreds of verified babysitters near you, filtered by your exact needs.',
      emoji: '\uD83D\uDD0D',
      gradient: [Color(0xFF7C3AED), Color(0xFF9D5CF8)],
    ),
    _OnboardingPage(
      title: 'Book in Minutes',
      subtitle: 'Check availability, view real reviews, and book instantly \u2014 all in one place.',
      emoji: '\uD83D\uDCC5',
      gradient: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
    ),
    _OnboardingPage(
      title: 'Safe & Trusted',
      subtitle: 'All nannies are background-checked and verified. Chat before booking for peace of mind.',
      emoji: '\uD83D\uDEE1\uFE0F',
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
              ),
            ),
            // Animated pill dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _page < _pages.length - 1
                  ? AppButton(
                      label: 'Next',
                      onTap: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      ),
                    )
                  : AppButton(
                      label: 'Get Started',
                      variant: AppButtonVariant.gradient,
                      onTap: () => context.go('/role-select'),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
  });
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: page.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: page.gradient[0].withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(page.emoji, style: const TextStyle(fontSize: 60)),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              page.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              page.subtitle,
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
