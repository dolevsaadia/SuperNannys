import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nanny_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

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
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    // Avatar image
                    Center(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 12, color: AppColors.star),
                              const SizedBox(width: 2),
                              Text(
                                nanny.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Price badge top-right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₪${nanny.hourlyRateNis}/hr',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Verified badge
                    if (nanny.isVerified)
                      const Positioned(
                        bottom: 8,
                        right: 8,
                        child: Icon(Icons.verified_rounded, size: 20, color: AppColors.badgeVerified),
                      ),
                  ],
                ),
              ),
              // Info section
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nanny.user?.fullName ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            nanny.city,
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${nanny.yearsExperience}y exp',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 6),
                        Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textHint, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                          '${nanny.completedJobs} jobs',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
