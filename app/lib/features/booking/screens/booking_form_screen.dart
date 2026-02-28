import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/booking_reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final String nannyId;
  const BookingFormScreen({super.key, required this.nannyId});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _childrenCount = 1;
  final _notesCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  // Nanny data
  String? _nannyName;
  String? _nannyUserId;
  int _hourlyRate = 0;

  @override
  void initState() {
    super.initState();
    _loadNanny();
  }

  Future<void> _loadNanny() async {
    try {
      final resp = await apiClient.dio.get('/nannies/${widget.nannyId}');
      final profile = resp.data['data']['profile'] as Map<String, dynamic>;
      final user = profile['user'] as Map<String, dynamic>;
      setState(() {
        _nannyName = user['fullName'] as String;
        _nannyUserId = user['id'] as String;
        _hourlyRate = profile['hourlyRateNis'] as int;
      });
    } catch (_) {}
  }

  int get _totalAmount {
    if (_startTime == null || _endTime == null) return 0;
    final startMin = _startTime!.hour * 60 + _startTime!.minute;
    final endMin = _endTime!.hour * 60 + _endTime!.minute;
    final durationHours = (endMin - startMin) / 60;
    if (durationHours <= 0) return 0;
    return (_hourlyRate * durationHours).round();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _startDate = d);
  }

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (t != null) setState(() => _startTime = t);
  }

  Future<void> _pickEndTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 17, minute: 0));
    if (t != null) setState(() => _endTime = t);
  }

  Future<void> _proceed() async {
    if (_startDate == null || _startTime == null || _endTime == null) {
      setState(() => _error = 'Please select date and time');
      return;
    }

    final startDt = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day,
      _startTime!.hour, _startTime!.minute,
    );
    final endDt = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day,
      _endTime!.hour, _endTime!.minute,
    );

    if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
      setState(() => _error = 'End time must be after start time');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final resp = await apiClient.dio.post('/bookings', data: {
        'nannyUserId': _nannyUserId ?? widget.nannyId,
        'startTime': startDt.toUtc().toIso8601String(),
        'endTime': endDt.toUtc().toIso8601String(),
        'childrenCount': _childrenCount,
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text,
        if (_addressCtrl.text.isNotEmpty) 'address': _addressCtrl.text,
      });

      final booking = resp.data['data'] as Map<String, dynamic>;

      // Schedule push notifications
      await BookingReminderService.instance.scheduleReminders(
        bookingId: booking['id'] as String,
        nannyName: _nannyName ?? 'your nanny',
        startTime: startDt,
      );

      if (mounted) {
        context.go('/home/nanny/${widget.nannyId}/book/success', extra: {'bookingId': booking['id']});
      }
    } catch (e) {
      setState(() {
        _error = (e as dynamic).response?.data?['message'] as String? ?? 'Booking failed';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${_nannyName ?? 'Nanny'}'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rate info
              if (_hourlyRate > 0)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '₪$_hourlyRate/hour',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 16),
                      ),
                      const Spacer(),
                      if (_totalAmount > 0)
                        Text('Total: ₪$_totalAmount', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Date
              const Text('Date', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _DateTimeTile(
                icon: Icons.calendar_month_rounded,
                label: _startDate != null ? fmt.format(_startDate!) : 'Select date',
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),

              // Time
              const Text('Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DateTimeTile(
                      icon: Icons.schedule_rounded,
                      label: _startTime != null ? _startTime!.format(context) : 'Start time',
                      onTap: _pickStartTime,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, color: AppColors.textHint),
                  ),
                  Expanded(
                    child: _DateTimeTile(
                      icon: Icons.schedule_rounded,
                      label: _endTime != null ? _endTime!.format(context) : 'End time',
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Children
              const Text('Number of children', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: _childrenCount > 1 ? () => setState(() => _childrenCount--) : null,
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: Center(
                      child: Text('$_childrenCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onPressed: _childrenCount < 6 ? () => setState(() => _childrenCount++) : null,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address
              AppTextField(
                label: 'Address (optional)',
                hint: 'Where will the care take place?',
                controller: _addressCtrl,
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textHint),
              ),
              const SizedBox(height: 16),

              // Notes
              AppTextField(
                label: 'Notes for the nanny (optional)',
                hint: "Child's routine, allergies, special instructions...",
                controller: _notesCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              AppButton(
                label: 'Request Booking',
                onTap: _proceed,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
      );
}
