import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Promo banner data model
class PromoBanner {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;

  const PromoBanner({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
  });
}

/// Default promo banners for SuperNanny
const kPromoBanners = [
  PromoBanner(
    title: 'Welcome to SuperNanny!',
    subtitle: 'Find your perfect babysitter in minutes',
    gradient: AppColors.gradientPrimary,
    icon: Icons.child_care_rounded,
  ),
  PromoBanner(
    title: 'Verified & Trusted',
    subtitle: 'All nannies are background-checked',
    gradient: AppColors.gradientSuccess,
    icon: Icons.verified_user_rounded,
  ),
  PromoBanner(
    title: 'Book Instantly',
    subtitle: 'No waiting, no hassle — just book & go',
    gradient: AppColors.gradientAccent,
    icon: Icons.flash_on_rounded,
  ),
];

/// Wolt-style auto-playing promotional carousel with page dots
class PromoCarousel extends StatefulWidget {
  final List<PromoBanner> banners;
  final Duration autoPlayInterval;

  const PromoCarousel({
    super.key,
    this.banners = kPromoBanners,
    this.autoPlayInterval = const Duration(seconds: 5),
  });

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  late final PageController _controller;
  int _currentPage = 0;
  Timer? _timer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!_isPaused && mounted && _controller.hasClients) {
        final next = (_currentPage + 1) % widget.banners.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: widget.banners.length,
            itemBuilder: (_, i) => _BannerCard(banner: widget.banners[i]),
          ),
        ),
        const SizedBox(height: 12),
        // Dots + Pause button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => _isPaused = !_isPaused),
              child: Icon(
                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 18,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(width: 12),
            ...List.generate(
              widget.banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == i ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBanner banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: banner.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: banner.gradient[0].withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background icon (large, faded)
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              banner.icon,
              size: 140,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  banner.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
