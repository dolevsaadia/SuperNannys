import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nanny_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Compact map preview that shows nanny markers and a count badge.
/// Tapping it opens the full-screen map.
class MiniMapPreview extends StatelessWidget {
  final LatLng center;
  final List<NannyModel> nannies;
  final LatLng? userLocation;
  final double height;
  final VoidCallback onTap;

  const MiniMapPreview({
    super.key,
    required this.center,
    required this.nannies,
    this.userLocation,
    this.height = 200,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderCard,
          boxShadow: AppShadows.sm,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.borderCard,
          child: Stack(
            children: [
              // Map (non-interactive — tap goes to full screen)
              AbsorbPointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.supernanny.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // User location
                        if (userLocation != null)
                          Marker(
                            point: userLocation!,
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.info, width: 2),
                              ),
                              child: const Center(
                                child: Icon(Icons.person, color: AppColors.info, size: 16),
                              ),
                            ),
                          ),
                        // Nanny markers — profile image circles
                        ...nannies.where((n) => n.latitude != null && n.longitude != null).map(
                          (nanny) => Marker(
                            point: LatLng(nanny.latitude!, nanny.longitude!),
                            width: 44,
                            height: 44,
                            child: _ProfileMarker(nanny: nanny, size: 40),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Count badge
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.borderPill,
                    boxShadow: AppShadows.md,
                  ),
                  child: Text(
                    'nannies nearby ${nannies.length}',
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.white),
                  ),
                ),
              ),

              // "Tap to expand" hint
              Positioned(
                bottom: AppSpacing.md,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.9),
                      borderRadius: AppRadius.borderPill,
                      boxShadow: AppShadows.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fullscreen_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Text('Tap to expand map', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile image map marker — circular photo with border and shadow.
/// Falls back to initials if no avatar.
class _ProfileMarker extends StatelessWidget {
  final NannyModel nanny;
  final double size;

  const _ProfileMarker({required this.nanny, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasImage = (nanny.user?.avatarUrl ?? '').isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: nanny.isVerified ? AppColors.primary : AppColors.white,
          width: 2.5,
        ),
        boxShadow: AppShadows.md,
      ),
      child: ClipOval(
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: nanny.user!.avatarUrl!,
                width: size - 5,
                height: size - 5,
                fit: BoxFit.cover,
                placeholder: (_, __) => _MarkerPlaceholder(name: nanny.user?.fullName, size: size - 5),
                errorWidget: (_, __, ___) => _MarkerPlaceholder(name: nanny.user?.fullName, size: size - 5),
              )
            : _MarkerPlaceholder(name: nanny.user?.fullName, size: size - 5),
      ),
    );
  }
}

class _MarkerPlaceholder extends StatelessWidget {
  final String? name;
  final double size;
  const _MarkerPlaceholder({this.name, required this.size});

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
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
