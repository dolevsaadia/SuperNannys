import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nanny_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Compact Wolt-style card for horizontal scroll sections (160×210 px)
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
          width: 160,
          margin: const EdgeInsets.only(right: AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.borderCard,
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar section
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                ),
                child: Stack(
                  children: [
                    // Avatar image
                    Center(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                        child: nanny.user?.avatarUrl != null && nanny.user!.avatarUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: nanny.user!.avatarUrl!,
                                width: 160,
                                height: 110,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _placeholder(),
                                errorWidget: (_, __, ___) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                    ),
                    // Rating badge top-left
                    if (nanny.rating > 0)
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        child: Container(
                          padding: AppSpacing.chipPaddingSm,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: AppRadius.borderMd,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 12, color: AppColors.star),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                nanny.rating.toStringAsFixed(1),
                                style: AppTextStyles.captionBold.copyWith(fontSize: 11, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Price badge top-right
                    Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.borderMd,
                        ),
                        child: Text(
                          '₪${nanny.hourlyRateNis}/hr',
                          style: AppTextStyles.captionBold.copyWith(fontSize: 11, color: AppColors.white),
                        ),
                      ),
                    ),
                    // Recurring badge bottom-left
                    if (nanny.recurringHourlyRateNis != null)
                      Positioned(
                        bottom: AppSpacing.md,
                        left: AppSpacing.md,
                        child: Container(
                          padding: AppSpacing.chipPaddingSm,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: AppRadius.borderMd,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.repeat_rounded, size: 10, color: AppColors.white),
                              const SizedBox(width: 3),
                              Text(
                                '₪${nanny.recurringHourlyRateNis}',
                                style: AppTextStyles.captionBold.copyWith(fontSize: 10, color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Verified badge
                    if (nanny.isVerified)
                      const Positioned(
                        bottom: AppSpacing.md,
                        right: AppSpacing.md,
                        child: Icon(Icons.verified_rounded, size: 20, color: AppColors.badgeVerified),
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
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textHint),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            nanny.city,
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          '${nanny.yearsExperience}y exp',
                          style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textHint, shape: BoxShape.circle)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${nanny.completedJobs} jobs',
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
        width: 160,
        height: 110,
        color: AppColors.primaryLight,
        child: const Icon(Icons.person, size: 40, color: AppColors.primary),
      );
}
