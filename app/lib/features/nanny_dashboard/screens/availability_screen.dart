import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
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
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;
  bool _isSaving = false;

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
      setState(() {
        _slots = List.generate(7, (day) {
          final existing = avail.firstWhere(
            (a) => (a as Map<String, dynamic>)['dayOfWeek'] == day,
            orElse: () => {'dayOfWeek': day, 'fromTime': '09:00', 'toTime': '18:00', 'isAvailable': false},
          ) as Map<String, dynamic>;
          return Map<String, dynamic>.from(existing);
        });
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await apiClient.dio.put('/nannies/me', data: {'availability': _slots});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability saved'), backgroundColor: AppColors.success),
        );
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: LoadingIndicator()));

    final availableCount = _slots.where((s) => s['isAvailable'] as bool).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Manage Availability'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // ── Summary header ──────────────────
          Container(
            margin: const EdgeInsets.all(16),
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
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: 7,
              itemBuilder: (_, day) {
                final slot = _slots[day];
                final isAvailable = slot['isAvailable'] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isAvailable ? AppShadows.md : AppShadows.sm,
                    border: isAvailable ? Border.all(color: AppColors.primary.withValues(alpha: 0.2)) : null,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isAvailable ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  _days[day],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isAvailable ? AppColors.primary : AppColors.textHint,
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
                                  if (isAvailable)
                                    Text(
                                      '${slot['fromTime']} - ${slot['toTime']}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                                    ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isAvailable,
                              activeColor: AppColors.primary,
                              onChanged: (v) {
                                HapticFeedback.lightImpact();
                                setState(() => _slots[day]['isAvailable'] = v);
                              },
                            ),
                          ],
                        ),
                      ),
                      if (isAvailable) ...[
                        Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textHint),
                              const SizedBox(width: 8),
                              _TimePill(
                                label: slot['fromTime'] as String,
                                onTap: () => _pickTime(day, 'fromTime'),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textHint.withValues(alpha: 0.5)),
                              ),
                              _TimePill(
                                label: slot['toTime'] as String,
                                onTap: () => _pickTime(day, 'toTime'),
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

  Future<void> _pickTime(int day, String key) async {
    final parts = (_slots[day][key] as String).split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => _slots[day][key] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
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
