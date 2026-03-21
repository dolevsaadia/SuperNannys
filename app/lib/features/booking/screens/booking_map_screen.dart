import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../l10n/app_localizations.dart';

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

  Future<void> _openGoogleMapsNavigation() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.nannyLat},${widget.nannyLng}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nannyLL = LatLng(widget.nannyLat, widget.nannyLng);
    final center = _userLocation != null
        ? LatLng(
            (_userLocation!.latitude + nannyLL.latitude) / 2,
            (_userLocation!.longitude + nannyLL.longitude) / 2,
          )
        : nannyLL;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.routeTo(widget.nannyName)),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            onPressed: _openGoogleMapsNavigation,
            icon: const Icon(Icons.navigation_rounded),
            tooltip: l.navigateWithGoogleMaps,
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

          // Distance card + navigate button at bottom
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                              Text(l.calculatingDistance, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))
                            else if (_distanceKm != null)
                              Text(
                                l.distanceValue(GeoUtils.formatDistance(_distanceKm!)),
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              )
                            else
                              Text(l.locationNotAvailable, style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
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
                const SizedBox(height: 12),
                // Navigate with Google Maps button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openGoogleMapsNavigation,
                    icon: const Icon(Icons.navigation_rounded, size: 20),
                    label: Text(l.navigateWithGoogleMaps, style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
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
