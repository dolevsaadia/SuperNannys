import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/nanny_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

import 'badge_chip.dart';

/// Premium full-width nanny card — matches the reference design:
/// Large profile image left · Name + subtitle · Rating with reviews · "View" CTA · Badge chips below
class NannyCard extends StatefulWidget {
  final NannyModel nanny;
  final VoidCallback onTap;

  const NannyCard({super.key, required this.nanny, required this.onTap});

  @override
  State<NannyCard> createState() => _NannyCardState();
}

class _NannyCardState extends State<NannyCard> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nanny = widget.nanny;
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.borderCardLg,
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              // ── Main content: large avatar + info ──
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Large profile image
                    _ProfileImage(nanny: nanny),
                    const SizedBox(width: AppSpacing.xxxl),
                    // Info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            nanny.user?.fullName ?? '',
                            style: AppTextStyles.heading2.copyWith(fontSize: 19),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Headline
                          if (nanny.headline.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              nanny.headline,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          // Rating row
                          Row(
                            children: [
                              Text(
                                '(${nanny.reviewsCount})',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                nanny.rating.toStringAsFixed(1),
                                style: AppTextStyles.heading3.copyWith(fontSize: 16),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const Icon(Icons.star_rounded, size: 18, color: AppColors.star),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Price row
                          Row(
                            children: [
                              Text(
                                '₪${nanny.hourlyRateNis}/hr',
                                style: AppTextStyles.captionBold.copyWith(fontSize: 13, color: AppColors.primary),
                              ),
                              if (nanny.recurringHourlyRateNis != null) ...[
                                const SizedBox(width: AppSpacing.md),
                                Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textHint, shape: BoxShape.circle)),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  '₪${nanny.recurringHourlyRateNis}/hr recurring',
                                  style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.accent),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          // View button
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20, vertical: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: AppRadius.borderPill,
                                boxShadow: AppShadows.primaryGlow(0.15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 16, color: AppColors.white),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text('View', style: AppTextStyles.buttonSmall.copyWith(color: AppColors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Badges row ──
              _BadgesRow(nanny: nanny),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large circular profile image with gradient border
class _ProfileImage extends StatelessWidget {
  final NannyModel nanny;
  const _ProfileImage({required this.nanny});

  @override
  Widget build(BuildContext context) {
    final hasImage = (nanny.user?.avatarUrl ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: nanny.isVerified
            ? const LinearGradient(colors: AppColors.gradientPrimary)
            : null,
        color: nanny.isVerified ? null : AppColors.divider,
      ),
      child: ClipOval(
        child: Container(
          width: 100,
          height: 100,
          color: AppColors.white,
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: nanny.user!.avatarUrl!,
                    width: 94,
                    height: 94,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _AvatarPlaceholder(name: nanny.user?.fullName),
                    errorWidget: (_, __, ___) => _AvatarPlaceholder(name: nanny.user?.fullName),
                  )
                : _AvatarPlaceholder(name: nanny.user?.fullName),
          ),
        ),
      ),
    );
  }
}

/// Google Maps navigation button — reused in NannyCard and NannyProfileScreen
class NavigateButton extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String address;
  final String city;
  final double? iconSize;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const NavigateButton({
    super.key,
    this.latitude,
    this.longitude,
    this.address = '',
    this.city = '',
    this.iconSize,
    this.padding,
    this.borderRadius,
  });

  Future<void> _launch() async {
    String url;
    if (latitude != null && longitude != null) {
      url = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    } else if (address.isNotEmpty) {
      url = 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}';
    } else {
      url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(city)}';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.gradientGoogleMaps),
          borderRadius: borderRadius ?? AppRadius.borderLg,
          boxShadow: [
            BoxShadow(color: AppColors.googleBlue.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.navigation_rounded, size: iconSize ?? 15, color: AppColors.white),
            const SizedBox(height: 1),
            Text('Navigate', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: AppColors.white, height: 1)),
          ],
        ),
      ),
    );
  }
}

class _BadgesRow extends StatelessWidget {
  final NannyModel nanny;
  const _BadgesRow({required this.nanny});

  @override
  Widget build(BuildContext context) {
    final effectiveBadges = <String>[...nanny.badges];
    if (nanny.isVerified && !effectiveBadges.contains('VERIFIED')) {
      effectiveBadges.insert(0, 'VERIFIED');
    }
    if (nanny.skills.any((s) => s.toLowerCase().contains('first aid')) && !effectiveBadges.contains('FIRST_AID')) {
      effectiveBadges.add('FIRST_AID');
    }
    if (nanny.rating >= 4.5 && nanny.reviewsCount >= 3 && !effectiveBadges.contains('TOP_RATED')) {
      effectiveBadges.add('TOP_RATED');
    }
    if (nanny.yearsExperience >= 5 && !effectiveBadges.contains('EXPERIENCE_5_PLUS')) {
      effectiveBadges.add('EXPERIENCE_5_PLUS');
    }
    if (nanny.recurringHourlyRateNis != null && !effectiveBadges.contains('RECURRING')) {
      effectiveBadges.add('RECURRING');
    }
    if (effectiveBadges.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: SizedBox(
        height: 28,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: effectiveBadges.take(4).length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, i) => BadgeChip(badge: effectiveBadges[i]),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final String? name;
  const _AvatarPlaceholder({this.name});

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty == true) ? name![0].toUpperCase() : '?';
    return Container(
      width: 94,
      height: 94,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.heading1.copyWith(color: AppColors.white, fontSize: 36),
        ),
      ),
    );
  }
}
