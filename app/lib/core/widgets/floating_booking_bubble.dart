import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../utils/geo_utils.dart';
import '../../features/booking/screens/booking_map_screen.dart';

class FloatingBookingBubble extends StatefulWidget {
  final String bookingId;
  final String nannyName;
  final DateTime startTime;
  final double nannyLat;
  final double nannyLng;
  final VoidCallback onDismiss;

  const FloatingBookingBubble({
    super.key,
    required this.bookingId,
    required this.nannyName,
    required this.startTime,
    required this.nannyLat,
    required this.nannyLng,
    required this.onDismiss,
  });

  @override
  State<FloatingBookingBubble> createState() => _FloatingBookingBubbleState();
}

class _FloatingBookingBubbleState extends State<FloatingBookingBubble> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late Timer _countdownTimer;
  Duration _remaining = Duration.zero;
  double? _distanceKm;
  LatLng? _userLocation;
  late AnimationController _pulseController;

  // Dragging state
  double _top = 120;
  double _right = 16;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _getUserLocation();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final diff = widget.startTime.difference(now);
    if (diff.isNegative) {
      _countdownTimer.cancel();
    }
    if (mounted) setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  Future<void> _getUserLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final dist = GeoUtils.distanceKm(pos.latitude, pos.longitude, widget.nannyLat, widget.nannyLng);
      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _distanceKm = dist;
        });
      }
    } catch (_) {}
  }

  String _formatCountdown() {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _openFullMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingMapScreen(
          nannyName: widget.nannyName,
          nannyLat: widget.nannyLat,
          nannyLng: widget.nannyLng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nannyLL = LatLng(widget.nannyLat, widget.nannyLng);

    if (_expanded) {
      return Positioned(
        top: _top,
        right: _right,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Starts in ${_formatCountdown()}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _expanded = false),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),

                // Mini map
                ClipRRect(
                  child: SizedBox(
                    height: 130,
                    child: IgnorePointer(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: nannyLL,
                          initialZoom: 14,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.supernanny.app',
                          ),
                          if (_userLocation != null)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [_userLocation!, nannyLL],
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                  strokeWidth: 2,
                                  isDotted: true,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              if (_userLocation != null)
                                Marker(
                                  point: _userLocation!,
                                  width: 28,
                                  height: 28,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.info,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 14),
                                  ),
                                ),
                              Marker(
                                point: nannyLL,
                                width: 28,
                                height: 28,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.child_care, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Info + actions
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.nannyName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_distanceKm != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                GeoUtils.formatDistance(_distanceKm!),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openFullMap(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map_rounded, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('Open Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onDismiss,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Dismiss', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ),
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

    // Collapsed bubble
    return Positioned(
      top: _top,
      right: _right,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = true),
        onPanUpdate: (d) {
          setState(() {
            _top = (_top + d.delta.dy).clamp(50, MediaQuery.of(context).size.height - 120);
            _right = (_right - d.delta.dx).clamp(0, MediaQuery.of(context).size.width - 70);
          });
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, child) {
            final scale = 1.0 + _pulseController.value * 0.06;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.child_care_rounded, color: Colors.white, size: 20),
                Text(
                  _formatCountdown(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
