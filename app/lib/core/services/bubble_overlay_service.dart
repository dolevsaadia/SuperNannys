import 'dart:async';
import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../widgets/floating_booking_bubble.dart';

class BubbleOverlayService {
  BubbleOverlayService._();
  static final BubbleOverlayService instance = BubbleOverlayService._();

  Timer? _pollingTimer;
  OverlayEntry? _currentOverlay;
  String? _currentBookingId;
  final Set<String> _dismissedBookings = {};

  /// Start monitoring upcoming bookings. Call when user is authenticated.
  void startMonitoring(BuildContext context) {
    stopMonitoring();
    // Check immediately, then every 60 seconds
    _checkUpcoming(context);
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) => _checkUpcoming(context));
  }

  /// Stop monitoring and remove any active bubble
  void stopMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _removeBubble();
  }

  Future<void> _checkUpcoming(BuildContext context) async {
    try {
      // Check both ACCEPTED (ready to start) and IN_PROGRESS (active session)
      final acceptedResp = await apiClient.dio.get('/bookings', queryParameters: {
        'status': 'ACCEPTED',
        'limit': '5',
      });
      final inProgressResp = await apiClient.dio.get('/bookings', queryParameters: {
        'status': 'IN_PROGRESS',
        'limit': '5',
      });
      final acceptedData = acceptedResp.data['data'] as Map<String, dynamic>;
      final inProgressData = inProgressResp.data['data'] as Map<String, dynamic>;
      final bookings = [
        ...((inProgressData['bookings'] as List?) ?? []),
        ...((acceptedData['bookings'] as List?) ?? []),
      ];

      // Find first active or upcoming booking
      final now = DateTime.now();
      Map<String, dynamic>? upcomingBooking;

      for (final b in bookings) {
        final booking = b as Map<String, dynamic>;
        final status = booking['status'] as String? ?? '';
        // IN_PROGRESS bookings always show bubble
        if (status == 'IN_PROGRESS') {
          upcomingBooking = booking;
          break;
        }
        // ACCEPTED bookings: within 30 min before to 60 min after
        final startTime = DateTime.parse(booking['startTime'] as String);
        final diff = startTime.difference(now);
        if (diff.inMinutes <= 30 && diff.inMinutes >= -60) {
          upcomingBooking = booking;
          break;
        }
      }

      if (upcomingBooking != null) {
        final bookingId = upcomingBooking['id'] as String;

        // Don't show if dismissed
        if (_dismissedBookings.contains(bookingId)) return;

        // Don't recreate if already showing this booking
        if (_currentBookingId == bookingId && _currentOverlay != null) return;

        // Get nanny coordinates from the booking
        final nanny = upcomingBooking['nanny'] as Map<String, dynamic>?;
        if (nanny == null) return;

        // Try to get nanny profile coords
        double? nannyLat;
        double? nannyLng;
        String nannyName = nanny['fullName'] as String? ?? 'Nanny';

        // Fetch full booking detail for coordinates
        try {
          final detailResp = await apiClient.dio.get('/bookings/$bookingId');
          final detail = detailResp.data['data'] as Map<String, dynamic>;
          final nannyDetail = detail['nanny'] as Map<String, dynamic>?;
          final nannyProfile = nannyDetail?['nannyProfile'] as Map<String, dynamic>?;
          nannyLat = (nannyProfile?['latitude'] as num?)?.toDouble();
          nannyLng = (nannyProfile?['longitude'] as num?)?.toDouble();
        } catch (_) {}

        final startTime = DateTime.parse(upcomingBooking['startTime'] as String);

        _showBubble(
          context,
          bookingId: bookingId,
          nannyName: nannyName,
          startTime: startTime,
          nannyLat: nannyLat ?? 0,
          nannyLng: nannyLng ?? 0,
        );
      } else {
        // No upcoming booking, remove bubble
        if (_currentOverlay != null) {
          _removeBubble();
        }
      }
    } catch (_) {
      // Silently fail — don't crash for network issues
    }
  }

  void _showBubble(
    BuildContext context, {
    required String bookingId,
    required String nannyName,
    required DateTime startTime,
    required double nannyLat,
    required double nannyLng,
  }) {
    _removeBubble();

    final overlay = Overlay.of(context, rootOverlay: true);
    _currentBookingId = bookingId;

    _currentOverlay = OverlayEntry(
      builder: (ctx) => FloatingBookingBubble(
        bookingId: bookingId,
        nannyName: nannyName,
        startTime: startTime,
        nannyLat: nannyLat,
        nannyLng: nannyLng,
        onDismiss: () {
          _dismissedBookings.add(bookingId);
          _removeBubble();
        },
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  void _removeBubble() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _currentBookingId = null;
  }
}
