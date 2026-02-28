import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nanny_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

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
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              // ── Top section: avatar + info ──────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with gradient border
                    Container(
                      padding: const EdgeInsets.all(2),
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
                          color: Colors.white,
                          padding: const EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: nanny.user?.avatarUrl != null && nanny.user!.avatarUrl!.isNotEmpty
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
                    const SizedBox(width: 14),
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
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (nanny.isVerified)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.badgeVerified.withOpacity(0.1),
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
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Rating
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.star.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                                    const SizedBox(width: 2),
                                    Text(
                                      nanny.rating.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      ' (${nanny.reviewsCount})',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Location
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  nanny.city,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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

              // ── Badges row ───────────────────────────
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

              // ── Bottom: stats + availability + price ───
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFCFCFD),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    _Stat(icon: Icons.work_outline_rounded, label: '${nanny.yearsExperience}y exp'),
                    const SizedBox(width: 14),
                    _Stat(icon: Icons.check_circle_outline, label: '${nanny.completedJobs} jobs'),
                    const Spacer(),
                    // Price tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '₪${nanny.hourlyRateNis}/hr',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
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
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      );
}
