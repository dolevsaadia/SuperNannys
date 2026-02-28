import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geo_utils.dart';

class BookingMapScreen extends StatefulWidget {
  final String nannyName;
  final double nannyLat;
  final double nannyLng;

  const BookingMapScreen({
    super.key,
    required this.nannyName,
    required this.nannyLat,
    required this.nannyLng,
  });

  @override
  State<BookingMapScreen> createState() => _BookingMapScreenState();
}

class _BookingMapScreenState extends State<BookingMapScreen> {
  final _mapController = MapController();
  LatLng? _userLocation;
  double? _distanceKm;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final userLL = LatLng(pos.latitude, pos.longitude);
      final dist = GeoUtils.distanceKm(
        pos.latitude, pos.longitude,
        widget.nannyLat, widget.nannyLng,
      );
      setState(() {
        _userLocation = userLL;
        _distanceKm = dist;
        _loading = false;
      });
      // Fit both markers in view
      _fitBounds();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _fitBounds() {
    final nannyLL = LatLng(widget.nannyLat, widget.nannyLng);
    if (_userLocation != null) {
      final bounds = LatLngBounds.fromPoints([_userLocation!, nannyLL]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nannyLL = LatLng(widget.nannyLat, widget.nannyLng);
    final center = _userLocation != null
        ? LatLng(
            (_userLocation!.latitude + nannyLL.latitude) / 2,
            (_userLocation!.longitude + nannyLL.longitude) / 2,
          )
        : nannyLL;

    return Scaffold(
      appBar: AppBar(
        title: Text('Route to ${widget.nannyName}'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.supernanny.app',
              ),
              // Line between user and nanny
              if (_userLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_userLocation!, nannyLL],
                      color: AppColors.primary.withValues(alpha: 0.6),
                      strokeWidth: 3,
                      isDotted: true,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // User marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
                        ),
                        child: const Center(child: Icon(Icons.person, color: Colors.white, size: 22)),
                      ),
                    ),
                  // Nanny marker
                  Marker(
                    point: nannyLL,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
                      ),
                      child: const Center(child: Icon(Icons.child_care_rounded, color: Colors.white, size: 22)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Distance card at bottom
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_walk_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.nannyName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        if (_loading)
                          const Text('Calculating distance...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
                        else if (_distanceKm != null)
                          Text(
                            'Distance: ${GeoUtils.formatDistance(_distanceKm!)}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          )
                        else
                          const Text('Location not available', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                      ],
                    ),
                  ),
                  if (_distanceKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        GeoUtils.formatDistance(_distanceKm!),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Fit bounds button
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              onPressed: _fitBounds,
              backgroundColor: Colors.white,
              child: const Icon(Icons.fit_screen_rounded, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
