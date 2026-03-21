import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nanny_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Compact nanny list tile for the Nearby screen.
/// Shows: avatar · name · rating · price — clean & modern.
class NannyListTile extends StatelessWidget {
  final NannyModel nanny;
  final VoidCallback onTap;

  const NannyListTile({super.key, required this.nanny, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.borderCard,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            // ── Avatar ──
            _Avatar(nanny: nanny),
            const SizedBox(width: AppSpacing.xxl),

            // ── Name + rating ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nanny.user?.fullName ?? '',
                          style: AppTextStyles.label.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (nanny.isVerified) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.verified_rounded, color: AppColors.badgeVerified, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        nanny.rating.toStringAsFixed(1),
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                      ),
                      Text(
                        ' (${nanny.reviewsCount})',
                        style: AppTextStyles.caption,
                      ),
                      if (nanny.distanceKm != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textHint),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${nanny.distanceKm!.toStringAsFixed(1)} km',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Price ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.borderLg,
              ),
              child: Text(
                '₪${nanny.hourlyRateNis} /hr',
                style: AppTextStyles.priceSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final NannyModel nanny;
  const _Avatar({required this.nanny});

  @override
  Widget build(BuildContext context) {
    final hasImage = (nanny.user?.avatarUrl ?? '').isNotEmpty;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: nanny.isVerified
            ? const LinearGradient(colors: AppColors.gradientPrimary)
            : null,
        color: nanny.isVerified ? null : AppColors.divider,
      ),
      padding: const EdgeInsets.all(1.5),
      child: ClipOval(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.all(1),
          child: ClipOval(
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: nanny.user!.avatarUrl!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _Placeholder(name: nanny.user?.fullName),
                    errorWidget: (_, __, ___) => _Placeholder(name: nanny.user?.fullName),
                  )
                : _Placeholder(name: nanny.user?.fullName),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String? name;
  const _Placeholder({this.name});

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty == true) ? name![0].toUpperCase() : '?';
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: AppColors.gradientPrimary),
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
