import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nanny_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Compact nanny list tile for the Nearby screen — matches reference:
/// Large circular avatar · name · rating with stars · hourly price pill
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
            // ── Profile Avatar ──
            _ProfileAvatar(nanny: nanny, size: 54),
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
                          style: AppTextStyles.heading3.copyWith(fontSize: 16),
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
                      const Icon(Icons.star_rounded, size: 15, color: AppColors.star),
                      const SizedBox(width: 2),
                      Text(
                        nanny.rating.toStringAsFixed(1),
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary, fontSize: 13),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '(${nanny.reviewsCount})',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Price pill ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Text(
                '₪ ${nanny.hourlyRateNis} /hr',
                style: AppTextStyles.priceSmall.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular profile avatar with image or initials fallback.
/// Reused by NannyListTile and map marker widgets.
class _ProfileAvatar extends StatelessWidget {
  final NannyModel nanny;
  final double size;
  const _ProfileAvatar({required this.nanny, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasImage = (nanny.user?.avatarUrl ?? '').isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: nanny.isVerified
            ? const LinearGradient(colors: AppColors.gradientPrimary)
            : null,
        color: nanny.isVerified ? null : AppColors.divider,
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.all(1),
          child: ClipOval(
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: nanny.user!.avatarUrl!,
                    width: size - 6,
                    height: size - 6,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _Placeholder(name: nanny.user?.fullName, size: size - 6),
                    errorWidget: (_, __, ___) => _Placeholder(name: nanny.user?.fullName, size: size - 6),
                  )
                : _Placeholder(name: nanny.user?.fullName, size: size - 6),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String? name;
  final double size;
  const _Placeholder({this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty == true) ? name![0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: AppColors.gradientPrimary),
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.heading3.copyWith(color: AppColors.white, fontSize: size * 0.4),
        ),
      ),
    );
  }
}
