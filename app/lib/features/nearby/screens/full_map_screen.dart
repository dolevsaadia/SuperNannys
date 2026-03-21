import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/nanny_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/geo_utils.dart';
import '../../home/providers/nannies_provider.dart';

/// Full-screen interactive map — opened from the MiniMapPreview tap.
class FullMapScreen extends ConsumerStatefulWidget {
  final LatLng? initialUserLocation;
  final List<NannyModel>? initialNannies;

  const FullMapScreen({super.key, this.initialUserLocation, this.initialNannies});

  @override
  ConsumerState<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends ConsumerState<FullMapScreen> {
  final _mapController = MapController();

  void _launchNavigation(NannyModel nanny) async {
    final lat = nanny.latitude!;
    final lng = nanny.longitude!;
    final url = Platform.isIOS
        ? 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d'
        : 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showNannySheet(NannyModel nanny) {
    final userLoc = widget.initialUserLocation;
    final dist = userLoc != null && nanny.latitude != null && nanny.longitude != null
        ? GeoUtils.distanceKm(userLoc.latitude, userLoc.longitude, nanny.latitude!, nanny.longitude!)
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: AppSpacing.sheetPadding,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.sheetTop,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: AppRadius.borderXs),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: nanny.user?.avatarUrl != null ? NetworkImage(nanny.user!.avatarUrl!) : null,
                  child: nanny.user?.avatarUrl == null
                      ? Text(
                          (nanny.user?.fullName ?? '?')[0].toUpperCase(),
                          style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nanny.user?.fullName ?? 'Nanny',
                              style: AppTextStyles.heading3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (nanny.isVerified) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(Icons.verified, color: AppColors.success, size: 18),
                          ],
                        ],
                      ),
                      if (nanny.headline.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(nanny.headline, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(Icons.star_rounded, '${nanny.rating}', AppColors.star),
                _StatItem(Icons.payments_rounded, '₪${nanny.hourlyRateNis}/hr', AppColors.primary),
                if (dist != null)
                  _StatItem(Icons.place_rounded, GeoUtils.formatDistance(dist), AppColors.accent),
                _StatItem(Icons.check_circle_rounded, '${nanny.completedJobs} jobs', AppColors.success),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Row(
              children: [
                if (nanny.latitude != null && nanny.longitude != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _launchNavigation(nanny);
                      },
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: Text('Navigate', style: AppTextStyles.label),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
                      ),
                    ),
                  ),
                if (nanny.latitude != null && nanny.longitude != null)
                  const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/home/nanny/${nanny.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
                    ),
                    child: Text('View Profile', style: AppTextStyles.label.copyWith(color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nanniesState = ref.watch(nanniesProvider);
    final nannies = widget.initialNannies ?? nanniesState.nannies.where((n) => n.latitude != null && n.longitude != null).toList();
    final center = widget.initialUserLocation ?? const LatLng(32.0853, 34.7818);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Nearby Nannies', style: AppTextStyles.heading2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.initialUserLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location_rounded),
              onPressed: () => _mapController.move(widget.initialUserLocation!, 14),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.supernanny.app',
              ),
              MarkerLayer(
                markers: [
                  if (widget.initialUserLocation != null)
                    Marker(
                      point: widget.initialUserLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.info, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.person, color: AppColors.info, size: 20),
                        ),
                      ),
                    ),
                  ...nannies.map((nanny) => Marker(
                        point: LatLng(nanny.latitude!, nanny.longitude!),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _showNannySheet(nanny),
                          child: Container(
                            decoration: BoxDecoration(
                              color: nanny.isVerified ? AppColors.primary : AppColors.textSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white, width: 2.5),
                              boxShadow: AppShadows.sm,
                            ),
                            child: const Center(
                              child: Icon(Icons.child_care_rounded, color: AppColors.white, size: 22),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),
          // Count badge
          Positioned(
            top: AppSpacing.xl,
            right: AppSpacing.xl,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.borderPill,
                boxShadow: AppShadows.md,
              ),
              child: Text(
                '${nannies.length} nannies nearby',
                style: AppTextStyles.captionBold.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _StatItem(this.icon, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.captionBold.copyWith(color: color)),
        ],
      );
}
