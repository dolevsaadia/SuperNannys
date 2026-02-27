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
      icon: Icons.search_rounded,
      gradient: [Color(0xFF7C3AED), Color(0xFF9D5CF8)],
    ),
    _OnboardingPage(
      title: 'Book in Minutes',
      subtitle: 'Check availability, view real reviews, and book instantly — all in one place.',
      icon: Icons.calendar_month_rounded,
      gradient: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
    ),
    _OnboardingPage(
      title: 'Safe & Trusted',
      subtitle: 'All nannies are background-checked and verified. Chat before booking for peace of mind.',
      icon: Icons.shield_rounded,
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
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary)),
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
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _page < _pages.length - 1
                  ? AppButton(
                      label: 'Next',
                      onTap: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    )
                  : AppButton(
                      label: 'Get Started',
                      onTap: () => context.go('/role-select'),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Sign in'),
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
  final IconData icon;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.title, required this.subtitle,
    required this.icon, required this.gradient,
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
              width: 140, height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: page.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: page.gradient[0].withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: Icon(page.icon, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 48),
            Text(
              page.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
