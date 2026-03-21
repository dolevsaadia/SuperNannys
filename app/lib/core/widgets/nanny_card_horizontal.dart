import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nanny_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Compact card for horizontal scroll sections — matches the reference:
/// Large profile image with rating overlay badge, verified icon, name + stats below.
class NannyCardHorizontal extends StatefulWidget {
  final NannyModel nanny;
  final VoidCallback onTap;

  const NannyCardHorizontal({super.key, required this.nanny, required this.onTap});

  @override
  State<NannyCardHorizontal> createState() => _NannyCardHorizontalState();
}

class _NannyCardHorizontalState extends State<NannyCardHorizontal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nanny = widget.nanny;
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: 170,
          margin: const EdgeInsets.only(right: AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.borderCard,
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image section
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                ),
                child: Stack(
                  children: [
                    // Profile image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                      child: nanny.user?.avatarUrl != null && nanny.user!.avatarUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: nanny.user!.avatarUrl!,
                              width: 170,
                              height: 120,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _placeholder(),
                              errorWidget: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    // Rating badge top-left
                    if (nanny.rating > 0)
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.star,
                            borderRadius: AppRadius.borderMd,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 12, color: AppColors.white),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                nanny.hourlyRateNis.toString(),
                                style: AppTextStyles.captionBold.copyWith(fontSize: 11, color: AppColors.white),
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              const Icon(Icons.star_rounded, size: 12, color: AppColors.white),
                            ],
                          ),
                        ),
                      ),
                    // Verified badge top-right
                    if (nanny.isVerified)
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.sm,
                          ),
                          child: const Icon(Icons.verified_rounded, size: 16, color: AppColors.badgeVerified),
                        ),
                      ),
                  ],
                ),
              ),
              // Info section
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nanny.user?.fullName ?? '',
                      style: AppTextStyles.heading3.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'jobs ${nanny.completedJobs}',
                          style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textHint, shape: BoxShape.circle)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${nanny.yearsExperience}y exp',
                          style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
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

  Widget _placeholder() => Container(
        width: 170,
        height: 120,
        color: AppColors.primaryLight,
        child: const Icon(Icons.person, size: 40, color: AppColors.primary),
      );
}
