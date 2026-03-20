import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  /// Each day maps to a list of time slots: [{fromTime, toTime}]
  Map<int, List<Map<String, String>>> _daySlots = {};
  Set<int> _enabledDays = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _enableRecurring = false;
  int _recurringRate = 45;
  int _hourlyRate = 55;
  double _minimumHours = 0;
  bool _allowsBabysittingAtHome = false;

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _daysFull = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await apiClient.dio.get('/nannies/me');
      final profile = resp.data['data'] as Map<String, dynamic>;
      final avail = (profile['availability'] as List<dynamic>?) ?? [];
      final recurringRate = profile['recurringHourlyRateNis'] as int?;
      final hourlyRate = profile['hourlyRateNis'] as int? ?? 55;
      final minimumHours = (profile['minimumHoursPerBooking'] as num?)?.toDouble() ?? 0;
      final allowsHome = profile['allowsBabysittingAtHome'] as bool? ?? false;

      final daySlots = <int, List<Map<String, String>>>{};
      final enabledDays = <int>{};

      for (int day = 0; day < 7; day++) {
        daySlots[day] = [];
      }

      for (final a in avail) {
        final slot = a as Map<String, dynamic>;
        final day = slot['dayOfWeek'] as int;
        final isAvailable = slot['isAvailable'] as bool? ?? true;
        if (isAvailable) {
          enabledDays.add(day);
          daySlots[day]!.add({
            'fromTime': slot['fromTime'] as String? ?? '09:00',
            'toTime': slot['toTime'] as String? ?? '18:00',
          });
        }
      }

      // Ensure every enabled day has at least one slot
      for (final day in enabledDays) {
        if (daySlots[day]!.isEmpty) {
          daySlots[day]!.add({'fromTime': '09:00', 'toTime': '18:00'});
        }
      }

      setState(() {
        _daySlots = daySlots;
        _enabledDays = enabledDays;
        _enableRecurring = recurringRate != null;
        _recurringRate = recurringRate ?? (hourlyRate * 0.8).round();
        _hourlyRate = hourlyRate;
        _minimumHours = minimumHours;
        _allowsBabysittingAtHome = allowsHome;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _buildAvailabilityPayload() {
    // Only send enabled slots — disabled days simply have no entries.
    // The backend replaceAllAvailability deletes everything first,
    // so omitting a day means it has no availability.
    final slots = <Map<String, dynamic>>[];
    for (int day = 0; day < 7; day++) {
      if (_enabledDays.contains(day) && _daySlots[day]!.isNotEmpty) {
        for (final slot in _daySlots[day]!) {
          slots.add({
            'dayOfWeek': day,
            'fromTime': slot['fromTime']!,
            'toTime': slot['toTime']!,
            'isAvailable': true,
          });
        }
      }
    }
    return slots;
  }

  bool _hasOverlap(int day) {
    final slots = _daySlots[day]!;
    for (int i = 0; i < slots.length; i++) {
      for (int j = i + 1; j < slots.length; j++) {
        final a = slots[i];
        final b = slots[j];
        if (a['fromTime']!.compareTo(b['toTime']!) < 0 &&
            b['fromTime']!.compareTo(a['toTime']!) < 0) {
          return true;
        }
      }
    }
    return false;
  }

  bool _hasDuplicateFromTime(int day) {
    final slots = _daySlots[day]!;
    final fromTimes = <String>{};
    for (final slot in slots) {
      if (!fromTimes.add(slot['fromTime']!)) return true;
    }
    return false;
  }

  Future<void> _save() async {
    // Check for overlaps and duplicate start times
    for (int day = 0; day < 7; day++) {
      if (!_enabledDays.contains(day)) continue;
      if (_hasOverlap(day)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_daysFull[day]} has overlapping time slots. Please fix before saving.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_hasDuplicateFromTime(day)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_daysFull[day]} has slots with the same start time. Please change one.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      await apiClient.dio.put('/nannies/me', data: {
        'availability': _buildAvailabilityPayload(),
        'recurringHourlyRateNis': _enableRecurring ? _recurringRate : null,
        'minimumHoursPerBooking': _minimumHours,
        'allowsBabysittingAtHome': _allowsBabysittingAtHome,
      });
      triggerDataRefresh(ref);
      // Reload from server to confirm persistence
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability saved'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save availability. Please try again.'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSlot(int day) {
    // Pick a fromTime that doesn't conflict with existing slots on this day
    // (DB has @@unique on [nannyProfileId, dayOfWeek, fromTime])
    final existing = _daySlots[day]!;
    final usedFromTimes = existing.map((s) => s['fromTime']!).toSet();
    String fromTime = '09:00';
    String toTime = '18:00';
    // Find the next available hour that doesn't conflict
    for (int h = 9; h < 23; h++) {
      final candidate = '${h.toString().padLeft(2, '0')}:00';
      if (!usedFromTimes.contains(candidate)) {
        fromTime = candidate;
        toTime = '${(h + 2).clamp(h + 1, 23).toString().padLeft(2, '0')}:00';
        break;
      }
    }
    setState(() {
      _daySlots[day]!.add({'fromTime': fromTime, 'toTime': toTime});
    });
  }

  void _removeSlot(int day, int index) {
    setState(() {
      _daySlots[day]!.removeAt(index);
      if (_daySlots[day]!.isEmpty) {
        _enabledDays.remove(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: LoadingIndicator()));

    final availableCount = _enabledDays.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Manage Availability'),
        leading: BackButton(onPressed: () => context.pop()),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: 7 + 3, // 3 header items + 7 day cards
              itemBuilder: (_, index) {
                // ── Summary header (scrollable) ──────────────────
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.gradientPrimary,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppShadows.primaryGlow(0.15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Schedule',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              Text(
                                '$availableCount of 7 days available',
                                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ── Recurring Bookings Toggle (scrollable) ──────────────────
                if (index == 1) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.sm,
                      border: Border.all(
                        color: _enableRecurring ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _enableRecurring ? AppColors.accent.withValues(alpha: 0.1) : AppColors.bg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.repeat_rounded, size: 20,
                                color: _enableRecurring ? AppColors.accent : AppColors.textHint),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Recurring Bookings',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  Text('Allow parents to book a fixed weekly schedule',
                                    style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _enableRecurring,
                              activeTrackColor: AppColors.accent,
                              onChanged: (v) {
                                HapticFeedback.lightImpact();
                                setState(() => _enableRecurring = v);
                              },
                            ),
                          ],
                        ),
                        if (_enableRecurring) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('\u20AA$_recurringRate', style: const TextStyle(
                                      fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.accent)),
                                    const Text('/hr', style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${((((_hourlyRate - _recurringRate) / _hourlyRate) * 100)).round()}% off',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _recurringRate.toDouble(),
                                  min: 20, max: 130, divisions: 22,
                                  activeColor: AppColors.accent,
                                  onChanged: (v) => setState(() => _recurringRate = v.toInt()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // ── Booking Settings (minimum hours + babysitting at home) ──
                if (index == 2) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.settings_rounded, size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('Booking Settings',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Minimum hours per booking ──
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 18, color: AppColors.textHint),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Minimum hours per booking',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _minimumHours == 0 ? 'None' : '${_minimumHours.toStringAsFixed(_minimumHours == _minimumHours.roundToDouble() ? 0 : 1)}h',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _minimumHours,
                          min: 0, max: 8, divisions: 16,
                          activeColor: AppColors.primary,
                          label: _minimumHours == 0 ? 'None' : '${_minimumHours.toStringAsFixed(1)}h',
                          onChanged: (v) => setState(() => _minimumHours = v),
                        ),
                        if (_minimumHours > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Parents will be charged for at least ${_minimumHours.toStringAsFixed(_minimumHours == _minimumHours.roundToDouble() ? 0 : 1)} hours even if session is shorter.',
                              style: TextStyle(fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic),
                            ),
                          ),

                        Divider(height: 20, color: AppColors.divider.withValues(alpha: 0.5)),

                        // ── Allow babysitting at home ──
                        Row(
                          children: [
                            const Icon(Icons.home_rounded, size: 18, color: AppColors.textHint),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Babysitting at my home',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text('Parents can choose your home as the location',
                                    style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _allowsBabysittingAtHome,
                              activeTrackColor: AppColors.primary,
                              onChanged: (v) {
                                HapticFeedback.lightImpact();
                                setState(() => _allowsBabysittingAtHome = v);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                // ── Day cards (index 3..9 → day 0..6) ──────────────────
                final day = index - 3;
                final isEnabled = _enabledDays.contains(day);
                final slots = _daySlots[day]!;
                final hasOverlap = isEnabled && _hasOverlap(day);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isEnabled ? AppShadows.md : AppShadows.sm,
                    border: hasOverlap
                        ? Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1.5)
                        : isEnabled
                            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                            : null,
                  ),
                  child: Column(
                    children: [
                      // ── Day header with toggle ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isEnabled ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  _days[day],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isEnabled ? AppColors.primary : AppColors.textHint,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _daysFull[day],
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  if (isEnabled)
                                    Text(
                                      '${slots.length} time slot${slots.length == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: hasOverlap ? AppColors.error : AppColors.textHint,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isEnabled,
                              activeTrackColor: AppColors.primary,
                              onChanged: (v) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  if (v) {
                                    _enabledDays.add(day);
                                    if (_daySlots[day]!.isEmpty) {
                                      _daySlots[day]!.add({'fromTime': '09:00', 'toTime': '18:00'});
                                    }
                                  } else {
                                    _enabledDays.remove(day);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // ── Time slots ──
                      if (isEnabled) ...[
                        Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                          child: Column(
                            children: [
                              for (int i = 0; i < slots.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(bottom: i < slots.length - 1 ? 8 : 0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textHint),
                                      const SizedBox(width: 8),
                                      _TimePill(
                                        label: slots[i]['fromTime']!,
                                        onTap: () => _pickTime(day, i, 'fromTime'),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textHint.withValues(alpha: 0.5)),
                                      ),
                                      _TimePill(
                                        label: slots[i]['toTime']!,
                                        onTap: () => _pickTime(day, i, 'toTime'),
                                      ),
                                      const Spacer(),
                                      if (slots.length > 1)
                                        GestureDetector(
                                          onTap: () => _removeSlot(day, i),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.remove_rounded, size: 16, color: AppColors.error),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              // ── Add slot button ──
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _addSlot(day),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), style: BorderStyle.solid),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text('Add time slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.top,
            ),
            child: AppButton(
              label: 'Save Availability',
              variant: AppButtonVariant.gradient,
              onTap: _save,
              isLoading: _isSaving,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(int day, int slotIndex, String key) async {
    final parts = (_daySlots[day]![slotIndex][key]!).split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        _daySlots[day]![slotIndex][key] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }
}

class _TimePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
          ),
        ),
      );
}
