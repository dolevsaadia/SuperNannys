import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/network/api_client.dart';

/// Provider that polls for bookings ready to start a live session.
/// Returns ACCEPTED bookings where the scheduled start time is near now
/// (within 15 min before to 30 min after), OR IN_PROGRESS bookings.
final pendingSessionProvider =
    StateNotifierProvider<PendingSessionNotifier, List<BookingModel>>((ref) {
  final notifier = PendingSessionNotifier();
  notifier.startPolling();
  ref.onDispose(() => notifier.stopPolling());
  return notifier;
});

class PendingSessionNotifier extends StateNotifier<List<BookingModel>> {
  Timer? _timer;

  PendingSessionNotifier() : super([]);

  void startPolling() {
    // Fetch immediately
    fetch();
    // Then every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetch());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> fetch() async {
    try {
      // Get ACCEPTED bookings
      final acceptedResp = await apiClient.dio.get('/bookings', queryParameters: {
        'status': 'ACCEPTED',
        'limit': '10',
      });
      final acceptedList = _parseBookings(acceptedResp.data);

      // Get IN_PROGRESS bookings
      final inProgressResp = await apiClient.dio.get('/bookings', queryParameters: {
        'status': 'IN_PROGRESS',
        'limit': '10',
      });
      final inProgressList = _parseBookings(inProgressResp.data);

      final now = DateTime.now();

      // Filter ACCEPTED bookings: start time window = 30 min before to 60 min after
      // (matches backend session confirm-start window)
      final readyToStart = acceptedList.where((b) {
        final windowStart = b.startTime.subtract(const Duration(minutes: 30));
        final windowEnd = b.startTime.add(const Duration(minutes: 60));
        return now.isAfter(windowStart) && now.isBefore(windowEnd);
      }).toList();

      // Combine: IN_PROGRESS first, then ready-to-start
      state = [...inProgressList, ...readyToStart];
    } catch (_) {
      // Don't clear state on error — keep showing last known
    }
  }

  List<BookingModel> _parseBookings(dynamic data) {
    final list = data['data']?['bookings'] as List<dynamic>? ?? [];
    return list.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Force refresh (e.g., after confirming start)
  void refresh() => fetch();
}
