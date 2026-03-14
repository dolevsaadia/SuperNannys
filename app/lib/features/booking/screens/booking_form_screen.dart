import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/booking_reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/constants/israeli_cities.dart';
import '../../../core/widgets/availability_calendar.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final String nannyId;
  const BookingFormScreen({super.key, required this.nannyId});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  // ── Booking type toggle ──────────────────
  bool _isRecurring = false;

  // ── One-time fields ──────────────────
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // ── Recurring fields ──────────────────
  final Set<int> _selectedDays = {}; // 0=Sun … 6=Sat
  TimeOfDay? _recurringStartTime;
  TimeOfDay? _recurringEndTime;
  DateTime? _recurringStartDate;
  DateTime? _recurringEndDate;

  // ── Shared fields ──────────────────
  int _childrenCount = 1;
  final _notesCtrl = TextEditingController();
  final _addressCtrl = TextEditingController(); // kept for backward compat display
  final _cityCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _houseNumCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _showCitySuggestions = false;

  // Address source: 'registered' | 'current' | 'manual'
  String _addressSource = 'registered';
  bool _loadingLocation = false;

  // Nanny data
  String? _nannyName;
  String? _nannyUserId;
  int _hourlyRate = 0;
  int? _recurringHourlyRate;
  double _minimumHours = 0;
  bool _nannyAllowsHome = false;
  String _locationType = 'parent_home';

  // Visual stepper
  int _currentStep = 0; // 0=When, 1=Details, 2=Confirm

  @override
  void initState() {
    super.initState();
    _loadNanny();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    try {
      final resp = await apiClient.dio.get('/auth/me');
      final user = resp.data['data'] as Map<String, dynamic>;
      setState(() {
        _cityCtrl.text = (user['city'] as String?) ?? '';
        _streetCtrl.text = (user['streetName'] as String?) ?? '';
        _houseNumCtrl.text = (user['houseNumber'] as String?) ?? '';
        _postalCodeCtrl.text = (user['postalCode'] as String?) ?? '';
        _addressCtrl.text = _buildAddressString();
      });
    } catch (_) {}
  }

  String _buildAddressString() {
    final parts = <String>[];
    if (_streetCtrl.text.isNotEmpty) parts.add(_streetCtrl.text);
    if (_houseNumCtrl.text.isNotEmpty) parts.add(_houseNumCtrl.text);
    if (_cityCtrl.text.isNotEmpty) parts.add(_cityCtrl.text);
    return parts.join(', ');
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        setState(() { _error = 'Location permission denied'; _loadingLocation = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _cityCtrl.text = p.locality ?? p.subAdministrativeArea ?? '';
          _streetCtrl.text = p.street ?? p.thoroughfare ?? '';
          _houseNumCtrl.text = p.subThoroughfare ?? '';
          _postalCodeCtrl.text = p.postalCode ?? '';
          _addressSource = 'current';
          _addressCtrl.text = _buildAddressString();
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not get location');
    }
    setState(() => _loadingLocation = false);
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
        _recurringHourlyRate = profile['recurringHourlyRateNis'] as int?;
        _minimumHours = (profile['minimumHoursPerBooking'] as num?)?.toDouble() ?? 0;
        _nannyAllowsHome = profile['allowsBabysittingAtHome'] as bool? ?? false;
      });
    } catch (_) {}
  }

  int get _effectiveRate => _isRecurring
      ? (_recurringHourlyRate ?? _hourlyRate)
      : _hourlyRate;

  int get _totalAmount {
    final st = _isRecurring ? _recurringStartTime : _startTime;
    final et = _isRecurring ? _recurringEndTime : _endTime;
    if (st == null || et == null) return 0;
    final startMin = st.hour * 60 + st.minute;
    final endMin = et.hour * 60 + et.minute;
    final durationHours = (endMin - startMin) / 60;
    if (durationHours <= 0) return 0;
    return (_effectiveRate * durationHours).round();
  }

  double get _durationHours {
    final st = _isRecurring ? _recurringStartTime : _startTime;
    final et = _isRecurring ? _recurringEndTime : _endTime;
    if (st == null || et == null) return 0;
    final startMin = st.hour * 60 + st.minute;
    final endMin = et.hour * 60 + et.minute;
    return (endMin - startMin) / 60;
  }

  int get _weeklyEstimate {
    if (_selectedDays.isEmpty || _durationHours <= 0) return 0;
    return (_effectiveRate * _durationHours * _selectedDays.length).round();
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

  Future<void> _proceedRecurring() async {
    if (_selectedDays.isEmpty || _recurringStartTime == null || _recurringEndTime == null || _recurringStartDate == null) {
      setState(() => _error = 'Please select days, time, and start date');
      return;
    }
    if (_cityCtrl.text.trim().isEmpty) {
      setState(() => _error = 'City is required');
      return;
    }

    final startMin = _recurringStartTime!.hour * 60 + _recurringStartTime!.minute;
    final endMin = _recurringEndTime!.hour * 60 + _recurringEndTime!.minute;
    if (endMin <= startMin) {
      setState(() => _error = 'End time must be after start time');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final startTimeStr = '${_recurringStartTime!.hour.toString().padLeft(2, '0')}:${_recurringStartTime!.minute.toString().padLeft(2, '0')}';
      final endTimeStr = '${_recurringEndTime!.hour.toString().padLeft(2, '0')}:${_recurringEndTime!.minute.toString().padLeft(2, '0')}';

      await apiClient.dio.post('/recurring-bookings', data: {
        'nannyUserId': _nannyUserId ?? widget.nannyId,
        'daysOfWeek': _selectedDays.toList()..sort(),
        'startTime': startTimeStr,
        'endTime': endTimeStr,
        'startDate': _recurringStartDate!.toUtc().toIso8601String(),
        if (_recurringEndDate != null) 'endDate': _recurringEndDate!.toUtc().toIso8601String(),
        'childrenCount': _childrenCount,
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text,
        'address': _buildAddressString(),
        'bookingCity': _cityCtrl.text.trim(),
        'bookingStreet': _streetCtrl.text.trim(),
        'bookingHouseNum': _houseNumCtrl.text.trim(),
        'bookingPostalCode': _postalCodeCtrl.text.trim(),
        'locationType': _locationType,
      });

      if (mounted) {
        context.go('/home/nanny/${widget.nannyId}/book/success', extra: {'isRecurring': true});
      }
    } catch (e) {
      setState(() {
        _error = (e as dynamic).response?.data?['message'] as String? ?? 'Booking failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _proceed() async {
    if (_startDate == null || _startTime == null || _endTime == null) {
      setState(() => _error = 'Please select date and time');
      return;
    }
    if (_cityCtrl.text.trim().isEmpty) {
      setState(() => _error = 'City is required');
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
        'address': _buildAddressString(),
        'bookingCity': _cityCtrl.text.trim(),
        'bookingStreet': _streetCtrl.text.trim(),
        'bookingHouseNum': _houseNumCtrl.text.trim(),
        'bookingPostalCode': _postalCodeCtrl.text.trim(),
        'locationType': _locationType,
      });

      final booking = resp.data['data'] as Map<String, dynamic>;

      // Schedule reminders in a separate try-catch — notification permission
      // failures must NOT block navigation to the success screen.
      try {
        await BookingReminderService.instance.scheduleReminders(
          bookingId: booking['id'] as String,
          nannyName: _nannyName ?? 'your nanny',
          startTime: startDt,
        );
      } catch (_) {}

      if (mounted) {
        context.go('/home/nanny/${widget.nannyId}/book/success', extra: {'bookingId': booking['id']});
      }
    } catch (e) {
      if (!mounted) return;
      String message = 'Booking failed';
      try {
        message = (e as dynamic).response?.data?['message'] as String? ?? message;
      } catch (_) {}
      setState(() {
        _error = message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Book ${_nannyName ?? 'Nanny'}'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Visual Stepper ──────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  _StepDot(index: 0, label: 'When', current: _currentStep),
                  _StepLine(done: _currentStep > 0),
                  _StepDot(index: 1, label: 'Details', current: _currentStep),
                  _StepLine(done: _currentStep > 1),
                  _StepDot(index: 2, label: 'Confirm', current: _currentStep),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Booking Type Toggle ──────────────────
                    if (_recurringHourlyRate != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _isRecurring = false);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isRecurring ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: !_isRecurring ? AppShadows.sm : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_rounded, size: 18, color: !_isRecurring ? AppColors.primary : AppColors.textHint),
                                      const SizedBox(width: 6),
                                      Text(
                                        'One-time',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: !_isRecurring ? AppColors.primary : AppColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _isRecurring = true);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isRecurring ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _isRecurring ? AppShadows.sm : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.repeat_rounded, size: 18, color: _isRecurring ? AppColors.accent : AppColors.textHint),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Recurring',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: _isRecurring ? AppColors.accent : AppColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Rate info banner ──────────────────
                    if (_effectiveRate > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isRecurring
                                ? [AppColors.accent, AppColors.accent.withValues(alpha: 0.8)]
                                : AppColors.gradientPrimary,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.primaryGlow(0.15),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isRecurring ? Icons.repeat_rounded : Icons.attach_money_rounded,
                                color: Colors.white, size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\u20AA$_effectiveRate/hour${_isRecurring ? ' (recurring)' : ''}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
                                  ),
                                  if (!_isRecurring && _totalAmount > 0)
                                    Text(
                                      '~${_durationHours.toStringAsFixed(1)}h ≈ \u20AA$_totalAmount estimated',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                                    ),
                                  if (_isRecurring && _weeklyEstimate > 0)
                                    Text(
                                      '~\u20AA$_weeklyEstimate/week estimated (${_selectedDays.length} days \u00D7 ${_durationHours.toStringAsFixed(1)}h)',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Final price based on actual session time',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // ── RECURRING: Day picker + time ──────────────────
                    if (_isRecurring) ...[
                      _FormSection(
                        icon: Icons.calendar_view_week_rounded,
                        title: 'Weekly Days',
                        child: _DayOfWeekPicker(
                          selectedDays: _selectedDays,
                          onToggle: (day) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedDays.contains(day)
                                  ? _selectedDays.remove(day)
                                  : _selectedDays.add(day);
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _FormSection(
                        icon: Icons.schedule_rounded,
                        title: 'Daily Hours',
                        child: Row(
                          children: [
                            Expanded(
                              child: _PremiumDateTimeTile(
                                icon: Icons.play_circle_outline_rounded,
                                label: _recurringStartTime != null ? _recurringStartTime!.format(context) : 'Start',
                                isSelected: _recurringStartTime != null,
                                onTap: () async {
                                  final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                                  if (t != null) setState(() => _recurringStartTime = t);
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 20),
                            ),
                            Expanded(
                              child: _PremiumDateTimeTile(
                                icon: Icons.stop_circle_outlined,
                                label: _recurringEndTime != null ? _recurringEndTime!.format(context) : 'End',
                                isSelected: _recurringEndTime != null,
                                onTap: () async {
                                  final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 17, minute: 0));
                                  if (t != null) setState(() => _recurringEndTime = t);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _FormSection(
                        icon: Icons.date_range_rounded,
                        title: 'Date Range',
                        child: Row(
                          children: [
                            Expanded(
                              child: _PremiumDateTimeTile(
                                icon: Icons.flag_outlined,
                                label: _recurringStartDate != null ? DateFormat('MMM d, yyyy').format(_recurringStartDate!) : 'Start date',
                                isSelected: _recurringStartDate != null,
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (d != null) setState(() => _recurringStartDate = d);
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 20),
                            ),
                            Expanded(
                              child: _PremiumDateTimeTile(
                                icon: Icons.flag_rounded,
                                label: _recurringEndDate != null ? DateFormat('MMM d, yyyy').format(_recurringEndDate!) : 'No end date',
                                isSelected: _recurringEndDate != null,
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _recurringStartDate ?? DateTime.now().add(const Duration(days: 30)),
                                    firstDate: _recurringStartDate ?? DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 730)),
                                  );
                                  if (d != null) setState(() => _recurringEndDate = d);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── ONE-TIME: Availability + Date ──────────────────
                    if (!_isRecurring) ...[
                    // Availability calendar
                    _FormSection(
                      icon: Icons.event_available_rounded,
                      title: 'Nanny Availability',
                      child: AvailabilityCalendar(
                        nannyProfileId: widget.nannyId,
                        compact: true,
                        onDateSelected: (date) {
                          setState(() => _startDate = date);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Selected date display
                    _FormSection(
                      icon: Icons.calendar_month_rounded,
                      title: 'Selected Date',
                      child: _PremiumDateTimeTile(
                        icon: Icons.calendar_month_rounded,
                        label: _startDate != null ? fmt.format(_startDate!) : 'Tap a date above or select manually',
                        isSelected: _startDate != null,
                        onTap: () {
                          _pickDate();
                          setState(() => _currentStep = 0);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Time section ──────────────────
                    _FormSection(
                      icon: Icons.schedule_rounded,
                      title: 'Time',
                      child: Row(
                        children: [
                          Expanded(
                            child: _PremiumDateTimeTile(
                              icon: Icons.play_circle_outline_rounded,
                              label: _startTime != null ? _startTime!.format(context) : 'Start',
                              isSelected: _startTime != null,
                              onTap: () {
                                _pickStartTime();
                                setState(() => _currentStep = 0);
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 20),
                          ),
                          Expanded(
                            child: _PremiumDateTimeTile(
                              icon: Icons.stop_circle_outlined,
                              label: _endTime != null ? _endTime!.format(context) : 'End',
                              isSelected: _endTime != null,
                              onTap: () {
                                _pickEndTime();
                                setState(() => _currentStep = 0);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ], // close if (!_isRecurring)

                    // ── Children counter ──────────────────
                    _FormSection(
                      icon: Icons.child_care_rounded,
                      title: 'Number of children',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _CounterButton(
                              icon: Icons.remove_rounded,
                              enabled: _childrenCount > 1,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() { _childrenCount--; _currentStep = 1; });
                              },
                            ),
                            SizedBox(
                              width: 80,
                              child: Center(
                                child: Text(
                                  '$_childrenCount',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                              ),
                            ),
                            _CounterButton(
                              icon: Icons.add_rounded,
                              enabled: _childrenCount < 6,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() { _childrenCount++; _currentStep = 1; });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Location type (if nanny allows home) ──────────────
                    if (_nannyAllowsHome)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _FormSection(
                          icon: Icons.home_work_rounded,
                          title: 'Meeting Location',
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _locationType = 'parent_home'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _locationType == 'parent_home' ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _locationType == 'parent_home' ? AppColors.primary : AppColors.border),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.home_rounded, color: _locationType == 'parent_home' ? AppColors.primary : AppColors.textHint, size: 22),
                                        const SizedBox(height: 4),
                                        Text('At my home', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _locationType == 'parent_home' ? AppColors.primary : AppColors.textHint)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _locationType = 'nanny_home'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _locationType == 'nanny_home' ? AppColors.accent.withValues(alpha: 0.1) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _locationType == 'nanny_home' ? AppColors.accent : AppColors.border),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.child_friendly_rounded, color: _locationType == 'nanny_home' ? AppColors.accent : AppColors.textHint, size: 22),
                                        const SizedBox(height: 4),
                                        Text("At nanny's home", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _locationType == 'nanny_home' ? AppColors.accent : AppColors.textHint)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Address section ──────────────────
                    _FormSection(
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Address source selector
                          Row(
                            children: [
                              _AddressSourceChip(
                                label: 'My Address',
                                icon: Icons.home_outlined,
                                isSelected: _addressSource == 'registered',
                                onTap: () {
                                  setState(() => _addressSource = 'registered');
                                  _loadUserAddress();
                                },
                              ),
                              const SizedBox(width: 8),
                              _AddressSourceChip(
                                label: 'Current Location',
                                icon: Icons.my_location_rounded,
                                isSelected: _addressSource == 'current',
                                isLoading: _loadingLocation,
                                onTap: () {
                                  setState(() => _addressSource = 'current');
                                  _useCurrentLocation();
                                },
                              ),
                              const SizedBox(width: 8),
                              _AddressSourceChip(
                                label: 'Manual',
                                icon: Icons.edit_location_alt_outlined,
                                isSelected: _addressSource == 'manual',
                                onTap: () {
                                  setState(() {
                                    _addressSource = 'manual';
                                    _cityCtrl.clear();
                                    _streetCtrl.clear();
                                    _houseNumCtrl.clear();
                                    _postalCodeCtrl.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // City with autocomplete
                          AppTextField(
                            label: 'City',
                            hint: 'Start typing a city...',
                            controller: _cityCtrl,
                            prefixIcon: const Icon(Icons.location_city_rounded, size: 20, color: AppColors.textHint),
                            onChanged: (_) => setState(() => _showCitySuggestions = true),
                          ),
                          if (_showCitySuggestions && _cityCtrl.text.isNotEmpty && IsraeliCities.search(_cityCtrl.text).isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              constraints: const BoxConstraints(maxHeight: 120),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppShadows.sm,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                children: IsraeliCities.search(_cityCtrl.text).take(5).map((city) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.location_city_rounded, size: 18, color: AppColors.primary),
                                  title: Text(city, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  onTap: () {
                                    _cityCtrl.text = city;
                                    _showCitySuggestions = false;
                                    setState(() => _currentStep = 1);
                                    FocusScope.of(context).unfocus();
                                  },
                                )).toList(),
                              ),
                            ),
                          const SizedBox(height: 10),

                          // Street + House Number row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: AppTextField(
                                  label: 'Street',
                                  hint: 'Street name',
                                  controller: _streetCtrl,
                                  prefixIcon: const Icon(Icons.signpost_rounded, size: 20, color: AppColors.textHint),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  label: 'House #',
                                  hint: 'Number',
                                  controller: _houseNumCtrl,
                                  prefixIcon: const Icon(Icons.tag_rounded, size: 20, color: AppColors.textHint),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Postal code
                          SizedBox(
                            width: 160,
                            child: AppTextField(
                              label: 'Postal Code',
                              hint: '0000000',
                              controller: _postalCodeCtrl,
                              prefixIcon: const Icon(Icons.markunread_mailbox_outlined, size: 20, color: AppColors.textHint),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Notes ──────────────────
                    GestureDetector(
                      onTap: () => setState(() => _currentStep = 1),
                      child: AppTextField(
                        label: 'Notes for the nanny (optional)',
                        hint: "Child's routine, allergies, special instructions...",
                        controller: _notesCtrl,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
                    AppButton(
                      label: _isRecurring ? 'Request Recurring Booking' : 'Request Booking',
                      variant: AppButtonVariant.gradient,
                      onTap: () {
                        setState(() => _currentStep = 2);
                        _isRecurring ? _proceedRecurring() : _proceed();
                      },
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step Dot ──────────────────
class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final int current;
  const _StepDot({required this.index, required this.label, required this.current});

  @override
  Widget build(BuildContext context) {
    final isDone = index < current;
    final isActive = index == current;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 32 : 24,
          height: isActive ? 32 : 24,
          decoration: BoxDecoration(
            color: isDone ? AppColors.success : (isActive ? AppColors.primary : AppColors.bg),
            shape: BoxShape.circle,
            border: (!isDone && !isActive) ? Border.all(color: AppColors.divider, width: 2) : null,
            boxShadow: isActive ? AppShadows.primaryGlow(0.2) : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.textHint,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

// ── Step Line ──────────────────
class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: done ? AppColors.success : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
}

// ── Form Section ──────────────────
class _FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _FormSection({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      );
}

// ── Premium Date/Time Tile ──────────────────
class _PremiumDateTimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PremiumDateTimeTile({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppShadows.sm,
            border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textHint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Counter Button ──────────────────
class _CounterButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _CounterButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: enabled ? AppColors.primary : AppColors.bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: enabled ? Colors.white : AppColors.textHint, size: 22),
        ),
      );
}

// ── Address Source Chip ──────────────────
class _AddressSourceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;
  const _AddressSourceChip({required this.label, required this.icon, required this.isSelected, this.isLoading = false, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            ),
            child: Column(
              children: [
                if (isLoading)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textHint),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textHint), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}

// ── Day of Week Picker ──────────────────
class _DayOfWeekPicker extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;
  const _DayOfWeekPicker({required this.selectedDays, required this.onToggle});

  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _dayLabelsHe = ['\u05D0\'', '\u05D1\'', '\u05D2\'', '\u05D3\'', '\u05D4\'', '\u05D5\'', '\u05E9\''];

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(7, (i) {
          final selected = selectedDays.contains(i);
          return Expanded(
            child: GestureDetector(
              onTap: () => onToggle(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Column(
                  children: [
                    Text(
                      _dayLabelsHe[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dayLabels[i],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white70 : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
}
