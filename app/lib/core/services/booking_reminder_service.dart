import 'notification_service.dart';

class BookingReminderService {
  BookingReminderService._();
  static final BookingReminderService instance = BookingReminderService._();

  /// Schedule both 30-min and 15-min reminders for a booking
  Future<void> scheduleReminders({
    required String bookingId,
    required String nannyName,
    required DateTime startTime,
  }) async {
    final notif = NotificationService.instance;

    // 30 minutes before
    final time30 = startTime.subtract(const Duration(minutes: 30));
    await notif.scheduleNotification(
      id: NotificationIds.reminder30(bookingId),
      title: '🕐 Booking in 30 minutes!',
      body: 'Your session with $nannyName starts at ${_formatTime(startTime)}',
      scheduledTime: time30,
      payload: bookingId,
    );

    // 15 minutes before
    final time15 = startTime.subtract(const Duration(minutes: 15));
    await notif.scheduleNotification(
      id: NotificationIds.reminder15(bookingId),
      title: '⏰ Booking in 15 minutes!',
      body: 'Get ready! $nannyName will be there at ${_formatTime(startTime)}',
      scheduledTime: time15,
      payload: bookingId,
    );
  }

  /// Cancel all reminders for a booking
  Future<void> cancelReminders(String bookingId) async {
    final notif = NotificationService.instance;
    await notif.cancel(NotificationIds.reminder30(bookingId));
    await notif.cancel(NotificationIds.reminder15(bookingId));
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
