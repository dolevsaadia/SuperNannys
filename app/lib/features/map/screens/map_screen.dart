import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/nanny_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geo_utils.dart';
import '../../home/providers/nannies_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  LatLng? _userLocation;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          setState(() => _loadingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        _loadingLocation = false;
      });
    } catch (_) {
      setState(() => _loadingLocation = false);
    }
  }

  void _showNannySheet(NannyModel nanny) {
    final dist = _userLocation != null && nanny.latitude != null && nanny.longitude != null
        ? GeoUtils.distanceKm(_userLocation!.latitude, _userLocation!.longitude, nanny.latitude!, nanny.longitude!)
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: nanny.user?.avatarUrl != null ? NetworkImage(nanny.user!.avatarUrl!) : null,
                  child: nanny.user?.avatarUrl == null
                      ? Text(
                          (nanny.user?.fullName ?? '?')[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nanny.user?.fullName ?? 'Nanny',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (nanny.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppColors.success, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (nanny.headline.isNotEmpty)
                        Text(nanny.headline, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Stats row
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/home/nanny/${nanny.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nanniesState = ref.watch(nanniesProvider);
    final nannies = nanniesState.nannies.where((n) => n.latitude != null && n.longitude != null).toList();

    // Default center: Tel Aviv or user location
    final center = _userLocation ?? const LatLng(32.0853, 34.7818);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Nearby Nannies'),
        actions: [
          if (_userLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location_rounded),
              onPressed: () => _mapController.move(_userLocation!, 14),
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
                  // User location marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
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
                  // Nanny markers
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
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: const Center(
                              child: Icon(Icons.child_care_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),

          // Loading overlay
          if (_loadingLocation || nanniesState.isLoading)
            const Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Loading...', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Nanny count badge
          if (!nanniesState.isLoading)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                ),
                child: Text(
                  '${nannies.length} nannies nearby',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      );
}
