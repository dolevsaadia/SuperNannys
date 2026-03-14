import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../network/api_client.dart';

/// Calendar widget showing nanny availability by date.
/// Green = available, Red = booked/blocked, Gray = no info.
class AvailabilityCalendar extends StatefulWidget {
  final String nannyProfileId;
  final Function(DateTime)? onDateSelected;
  final bool compact;

  const AvailabilityCalendar({
    super.key,
    required this.nannyProfileId,
    this.onDateSelected,
    this.compact = false,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late CalendarFormat _calendarFormat;

  // Data from API
  List<dynamic> _weeklyAvailability = [];
  List<dynamic> _dateSlots = [];
  List<dynamic> _bookings = [];
  double _minimumHours = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _calendarFormat = widget.compact ? CalendarFormat.twoWeeks : CalendarFormat.month;
    _loadCalendar(_focusedDay);
  }

  Future<void> _loadCalendar(DateTime month) async {
    setState(() => _loading = true);
    try {
      final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final resp = await apiClient.dio.get(
        '/nannies/${widget.nannyProfileId}/availability/calendar',
        queryParameters: {'month': monthStr},
      );
      final data = resp.data['data'] as Map<String, dynamic>;
      setState(() {
        _weeklyAvailability = data['weeklyAvailability'] as List? ?? [];
        _dateSlots = data['dateSlots'] as List? ?? [];
        _bookings = data['bookings'] as List? ?? [];
        _minimumHours = (data['minimumHoursPerBooking'] as num?)?.toDouble() ?? 0;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /// Check if a given date has availability based on weekly pattern.
  bool _isAvailableByWeekly(DateTime date) {
    final dayOfWeek = date.weekday == 7 ? 0 : date.weekday; // convert to 0=Sun
    for (final slot in _weeklyAvailability) {
      if (slot['dayOfWeek'] == dayOfWeek && slot['isAvailable'] == true) {
        return true;
      }
    }
    return false;
  }

  /// Check if a date has specific availability set.
  Map<String, dynamic>? _getDateSlot(DateTime date) {
    for (final slot in _dateSlots) {
      final slotDate = DateTime.parse(slot['date'] as String);
      if (slotDate.year == date.year && slotDate.month == date.month && slotDate.day == date.day) {
        return slot as Map<String, dynamic>;
      }
    }
    return null;
  }

  /// Check if a date has existing bookings.
  bool _hasBooking(DateTime date) {
    for (final b in _bookings) {
      final start = DateTime.parse(b['startTime'] as String);
      final end = DateTime.parse(b['endTime'] as String);
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      if (start.isBefore(dayEnd) && end.isAfter(dayStart)) return true;
    }
    return false;
  }

  /// Get time range string for a date.
  String? _getTimeRange(DateTime date) {
    final dateSlot = _getDateSlot(date);
    if (dateSlot != null && dateSlot['isBlocked'] != true) {
      return '${dateSlot['startTime']} - ${dateSlot['endTime']}';
    }
    final dayOfWeek = date.weekday == 7 ? 0 : date.weekday;
    for (final slot in _weeklyAvailability) {
      if (slot['dayOfWeek'] == dayOfWeek && slot['isAvailable'] == true) {
        return '${slot['fromTime']} - ${slot['toTime']}';
      }
    }
    return null;
  }

  Color _getDayColor(DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return Colors.grey.shade200;
    }
    final dateSlot = _getDateSlot(date);
    if (dateSlot != null && dateSlot['isBlocked'] == true) {
      return AppColors.error.withValues(alpha: 0.15);
    }
    if (_hasBooking(date)) {
      return Colors.orange.withValues(alpha: 0.15);
    }
    if (dateSlot != null) {
      return AppColors.success.withValues(alpha: 0.15);
    }
    if (_isAvailableByWeekly(date)) {
      return AppColors.success.withValues(alpha: 0.08);
    }
    return Colors.grey.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else ...[
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 180)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => _selectedDay != null && isSameDay(_selectedDay!, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                widget.onDateSelected?.call(selected);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadCalendar(focusedDay);
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                weekendTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: widget.compact,
                formatButtonTextStyle: const TextStyle(fontSize: 12, color: AppColors.primary),
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final color = _getDayColor(day);
                  return Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: day.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _LegendDot(color: AppColors.success.withValues(alpha: 0.15), label: 'Available'),
                  const SizedBox(width: 12),
                  _LegendDot(color: Colors.orange.withValues(alpha: 0.15), label: 'Booked'),
                  const SizedBox(width: 12),
                  _LegendDot(color: AppColors.error.withValues(alpha: 0.15), label: 'Blocked'),
                ],
              ),
            ),

            // Selected date details
            if (_selectedDay != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(14),
                child: _buildSelectedDayDetails(),
              ),
            ],

            // Minimum hours note
            if (_minimumHours > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: AppColors.info),
                      const SizedBox(width: 6),
                      Text(
                        'Minimum ${_minimumHours.toStringAsFixed(_minimumHours == _minimumHours.roundToDouble() ? 0 : 1)} hours per session',
                        style: const TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetails() {
    final day = _selectedDay!;
    final dateSlot = _getDateSlot(day);
    final isBlocked = dateSlot != null && dateSlot['isBlocked'] == true;
    final hasBooking = _hasBooking(day);
    final timeRange = _getTimeRange(day);

    if (isBlocked) {
      return Row(
        children: [
          Icon(Icons.block_rounded, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          const Text('Blocked', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
        ],
      );
    }

    if (hasBooking) {
      return Row(
        children: [
          Icon(Icons.event_busy_rounded, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Has existing booking(s)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange)),
          ),
        ],
      );
    }

    if (timeRange != null) {
      return Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          Text('Available: $timeRange', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.help_outline_rounded, size: 18, color: AppColors.textHint),
        const SizedBox(width: 8),
        const Text('No availability set', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textHint)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ],
      );
}
