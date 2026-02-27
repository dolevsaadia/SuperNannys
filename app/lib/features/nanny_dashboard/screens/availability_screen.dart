import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/nanny_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Availability')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (_, day) {
                final slot = _slots[day];
                final isAvailable = slot['isAvailable'] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isAvailable ? AppColors.primary.withOpacity(0.3) : AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: isAvailable ? AppColors.primaryLight : AppColors.bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(_days[day], style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isAvailable ? AppColors.primary : AppColors.textHint,
                              )),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_days[day] + (day == 6 ? ' (Sat)' : ''), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          ),
                          Switch(
                            value: isAvailable,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _slots[day]['isAvailable'] = v),
                          ),
                        ],
                      ),
                      if (isAvailable) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textHint),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _pickTime(day, 'fromTime'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.bg, borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(slot['fromTime'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('to', style: TextStyle(color: AppColors.textHint)),
                            ),
                            GestureDetector(
                              onTap: () => _pickTime(day, 'toTime'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.bg, borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(slot['toTime'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(label: 'Save Availability', onTap: _save, isLoading: _isSaving),
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
