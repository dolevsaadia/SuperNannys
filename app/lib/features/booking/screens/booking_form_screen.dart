import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/booking_reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
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

  // Visual stepper
  int _currentStep = 0; // 0=When, 1=Details, 2=Confirm

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

  double get _durationHours {
    if (_startTime == null || _endTime == null) return 0;
    final startMin = _startTime!.hour * 60 + _startTime!.minute;
    final endMin = _endTime!.hour * 60 + _endTime!.minute;
    return (endMin - startMin) / 60;
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
                    // ── Rate info banner ──────────────────
                    if (_hourlyRate > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradientPrimary,
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
                              child: const Icon(Icons.attach_money_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\u20AA$_hourlyRate/hour',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
                                ),
                                if (_totalAmount > 0)
                                  Text(
                                    '${_durationHours.toStringAsFixed(1)}h = \u20AA$_totalAmount total',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // ── Date section ──────────────────
                    _FormSection(
                      icon: Icons.calendar_month_rounded,
                      title: 'Date',
                      child: _PremiumDateTimeTile(
                        icon: Icons.calendar_month_rounded,
                        label: _startDate != null ? fmt.format(_startDate!) : 'Select date',
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

                    // ── Address ──────────────────
                    GestureDetector(
                      onTap: () => setState(() => _currentStep = 1),
                      child: AppTextField(
                        label: 'Address (optional)',
                        hint: 'Where will the care take place?',
                        controller: _addressCtrl,
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textHint),
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
                      label: 'Request Booking',
                      variant: AppButtonVariant.gradient,
                      onTap: () {
                        setState(() => _currentStep = 2);
                        _proceed();
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
