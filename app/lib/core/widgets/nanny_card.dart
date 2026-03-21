import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/nanny_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

import 'badge_chip.dart';

/// Premium Wolt-style full-width nanny card
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
              // ── Top section: avatar + info ──────────────
              Padding(
                padding: AppSpacing.cardPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with gradient border
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxs),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: nanny.isVerified
                            ? const LinearGradient(colors: AppColors.gradientPrimary)
                            : null,
                        color: nanny.isVerified ? null : AppColors.divider,
                      ),
                      child: ClipOval(
                        child: Container(
                          width: 68,
                          height: 68,
                          color: AppColors.white,
                          padding: const EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: (nanny.user?.avatarUrl ?? '').isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: nanny.user!.avatarUrl!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => _AvatarPlaceholder(name: nanny.user?.fullName),
                                    errorWidget: (_, __, ___) => _AvatarPlaceholder(name: nanny.user?.fullName),
                                  )
                                : _AvatarPlaceholder(name: nanny.user?.fullName),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nanny.user?.fullName ?? '',
                                  style: AppTextStyles.heading3.copyWith(letterSpacing: -0.2),
                                ),
                              ),
                              if (nanny.isVerified)
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xxs),
                                  decoration: BoxDecoration(
                                    color: AppColors.badgeVerified.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.verified_rounded, color: AppColors.badgeVerified, size: 18),
                                ),
                            ],
                          ),
                          if (nanny.headline.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                nanny.headline,
                                style: AppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              // Rating
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                                decoration: BoxDecoration(
                                  color: AppColors.star.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.borderSm,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                                    const SizedBox(width: AppSpacing.xxs),
                                    Text(
                                      nanny.rating.toStringAsFixed(1),
                                      style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      ' (${nanny.reviewsCount})',
                                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              // Location
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint),
                              const SizedBox(width: AppSpacing.xxs),
                              Flexible(
                                child: Text(
                                  nanny.city,
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (nanny.distanceKm != null) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '· ${nanny.distanceKm!.toStringAsFixed(1)} km',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ── Navigate button ──────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: _NavigateButton(nanny: nanny),
                    ),
                  ],
                ),
              ),

              // ── Badges row ───────────────────────────
              _BadgesRow(nanny: nanny),

              const SizedBox(height: AppSpacing.xl),

              // ── Bottom: stats + price ───
              Container(
                padding: AppSpacing.cardBottomPadding,
                decoration: const BoxDecoration(
                  color: AppColors.cardFooterBg,
                  borderRadius: AppRadius.cardBottom,
                ),
                child: Row(
                  children: [
                    _Stat(icon: Icons.work_outline_rounded, label: '${nanny.yearsExperience}y exp'),
                    const SizedBox(width: AppSpacing.xxl),
                    _Stat(icon: Icons.check_circle_outline, label: '${nanny.completedJobs} jobs'),
                    const Spacer(),
                    // Price tags
                    if (nanny.recurringHourlyRateNis != null)
                      Container(
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.repeat_rounded, size: 12, color: AppColors.accent),
                            const SizedBox(width: 3),
                            Text(
                              '₪${nanny.recurringHourlyRateNis}',
                              style: AppTextStyles.captionBold.copyWith(fontSize: 11, color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                        borderRadius: AppRadius.borderLg,
                      ),
                      child: Text(
                        '₪${nanny.hourlyRateNis}/hr',
                        style: AppTextStyles.buttonSmall.copyWith(color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

class _NavigateButton extends StatelessWidget {
  final NannyModel nanny;
  const _NavigateButton({required this.nanny});

  @override
  Widget build(BuildContext context) => NavigateButton(
        latitude: nanny.latitude,
        longitude: nanny.longitude,
        address: nanny.address,
        city: nanny.city,
      );
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
      width: 64,
      height: 64,
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
          style: AppTextStyles.heading1.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      );
}
