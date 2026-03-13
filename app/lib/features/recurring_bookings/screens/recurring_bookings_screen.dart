import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/recurring_booking_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/loading_indicator.dart';

final _recurringListProvider = FutureProvider.autoDispose<List<RecurringBookingModel>>((ref) async {
  final resp = await apiClient.dio.get('/recurring-bookings');
  final list = resp.data['data']['recurringBookings'] as List<dynamic>;
  return list.map((e) => RecurringBookingModel.fromJson(e as Map<String, dynamic>)).toList();
});

class RecurringBookingsScreen extends ConsumerWidget {
  const RecurringBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_recurringListProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Recurring Bookings'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: async.when(
        loading: () => const FullScreenLoader(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.repeat_rounded, size: 40, color: AppColors.accent),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No recurring bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Set up a fixed weekly schedule\nwith your nanny',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_recurringListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _RecurringCard(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  final RecurringBookingModel item;
  const _RecurringCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      'ACTIVE' => AppColors.success,
      'PENDING' => AppColors.warning,
      'PAUSED' => AppColors.textHint,
      'CANCELLED' || 'ENDED' => AppColors.error,
      _ => AppColors.textHint,
    };

    final statusIcon = switch (item.status) {
      'ACTIVE' => Icons.play_circle_rounded,
      'PENDING' => Icons.hourglass_top_rounded,
      'PAUSED' => Icons.pause_circle_rounded,
      'CANCELLED' => Icons.cancel_rounded,
      'ENDED' => Icons.stop_circle_rounded,
      _ => Icons.help_outline_rounded,
    };

    return GestureDetector(
      onTap: () => context.push('/recurring-bookings/${item.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm,
          border: Border(left: BorderSide(color: statusColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row — other user + status
            Row(
              children: [
                // Avatar placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (item.nanny?.fullName ?? item.parent?.fullName ?? '?')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nanny?.fullName ?? item.parent?.fullName ?? '',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        item.scheduleLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        item.status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),

            // Bottom row — rate + weekly estimate
            Row(
              children: [
                _InfoPill(
                  icon: Icons.attach_money_rounded,
                  label: '\u20AA${item.hourlyRateNis}/hr',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: Icons.calendar_view_week_rounded,
                  label: '~\u20AA${item.weeklyEstimatedCostNis}/week',
                  color: AppColors.accent,
                ),
                const Spacer(),
                Text(
                  '${item.bookingsCount} sessions',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      );
}
