import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';

final _bookingsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String?>((ref, status) async {
  final queryParams = <String, String>{'limit': '50'};
  if (status != null && status.isNotEmpty) queryParams['status'] = status;
  final resp = await apiClient.dio.get('/admin/bookings', queryParameters: queryParams);
  return resp.data['data'] as Map<String, dynamic>;
});

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});
  @override
  ConsumerState<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  String? _statusFilter;

  Color _statusColor(String status) {
    switch (status) {
      case 'REQUESTED': return AppColors.warning;
      case 'ACCEPTED': return AppColors.info;
      case 'IN_PROGRESS': return AppColors.accent;
      case 'COMPLETED': return AppColors.success;
      case 'CANCELLED': return AppColors.error;
      case 'DECLINED': return AppColors.textHint;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_bookingsProvider(_statusFilter));
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Review Bookings')),
      body: Column(
        children: [
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: _statusFilter == null, onTap: () => setState(() => _statusFilter = null)),
                for (final s in ['REQUESTED', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'DECLINED'])
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _FilterChip(
                      label: s[0] + s.substring(1).toLowerCase().replaceAll('_', ' '),
                      selected: _statusFilter == s,
                      color: _statusColor(s),
                      onTap: () => setState(() => _statusFilter = s),
                    ),
                  ),
              ],
            ),
          ),

          // Bookings list
          Expanded(
            child: async.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (data) {
                final bookings = (data['bookings'] as List?) ?? [];
                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.textHint),
                        const SizedBox(height: 8),
                        const Text('No bookings found', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(_bookingsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: bookings.length,
                    itemBuilder: (_, i) {
                      final b = bookings[i] as Map<String, dynamic>;
                      final status = b['status'] as String? ?? 'REQUESTED';
                      final parent = b['parent'] as Map<String, dynamic>? ?? {};
                      final nanny = b['nanny'] as Map<String, dynamic>? ?? {};
                      final start = DateTime.tryParse(b['startTime'] as String? ?? '') ?? DateTime.now();
                      final end = DateTime.tryParse(b['endTime'] as String? ?? '') ?? DateTime.now();
                      final amount = b['totalAmountNis'] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status + amount row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status.replaceAll('_', ' '),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status)),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text('₪$amount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Parent → Nanny
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text(parent['fullName'] as String? ?? '?', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textHint),
                                  ),
                                  const Icon(Icons.child_care_rounded, size: 16, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text(nanny['fullName'] as String? ?? '?', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Time
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textHint),
                                  const SizedBox(width: 4),
                                  Text('${df.format(start.toLocal())} – ${DateFormat('HH:mm').format(end.toLocal())}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? (color ?? AppColors.primary) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? (color ?? AppColors.primary) : AppColors.divider),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}
