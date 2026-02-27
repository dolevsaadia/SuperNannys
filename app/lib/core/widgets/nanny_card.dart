import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nanny_model.dart';
import '../theme/app_colors.dart';
import 'rating_bar_widget.dart';
import 'badge_chip.dart';

class NannyCard extends StatelessWidget {
  final NannyModel nanny;
  final VoidCallback onTap;

  const NannyCard({super.key, required this.nanny, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(avatarUrl: nanny.user?.avatarUrl, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nanny.user?.fullName ?? '',
                                style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (nanny.isVerified)
                              const Icon(Icons.verified_rounded, color: AppColors.badgeVerified, size: 18),
                          ],
                        ),
                        if (nanny.headline.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              nanny.headline,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            RatingDisplay(rating: nanny.rating, count: nanny.reviewsCount, compact: true),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint),
                            const SizedBox(width: 2),
                            Text(nanny.city, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                            if (nanny.distanceKm != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '· ${nanny.distanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Badges row
            if (nanny.badges.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: nanny.badges.take(4).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => BadgeChip(badge: nanny.badges[i]),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Bottom: rate + experience + availability
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _Stat(icon: Icons.attach_money_rounded, label: '₪${nanny.hourlyRateNis}/hr'),
                  const SizedBox(width: 16),
                  _Stat(icon: Icons.work_outline_rounded, label: '${nanny.yearsExperience}y exp'),
                  const SizedBox(width: 16),
                  _Stat(icon: Icons.check_circle_outline, label: '${nanny.completedJobs} jobs'),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: nanny.isAvailable ? AppColors.successLight : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      nanny.isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: nanny.isAvailable ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;

  const _Avatar({this.avatarUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              width: size, height: size, fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(),
              errorWidget: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: size, height: size,
        color: AppColors.primaryLight,
        child: Icon(Icons.person, size: size * 0.5, color: AppColors.primary),
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      );
}
