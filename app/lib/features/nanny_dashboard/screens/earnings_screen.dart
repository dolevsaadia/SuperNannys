import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';

final _earningsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final resp = await apiClient.dio.get('/users/me/earnings');
  return resp.data['data'] as Map<String, dynamic>;
});

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_earningsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: async.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final summary = data['summary'] as Map<String, dynamic>;
          final earnings = data['earnings'] as List<dynamic>;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '₪${summary['totalEarned'] ?? 0}',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _EarningStat('Pending', '₪${summary['totalPending'] ?? 0}', AppColors.warningLight),
                          const SizedBox(width: 12),
                          _EarningStat('Jobs', '${summary['totalJobs'] ?? 0}', AppColors.primaryLight),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (earnings.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    title: 'No earnings yet',
                    subtitle: 'Complete bookings to see your earnings here',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final e = earnings[i] as Map<String, dynamic>;
                      final booking = e['booking'] as Map<String, dynamic>?;
                      final parent = booking?['parent'] as Map<String, dynamic>?;
                      final startTime = booking != null ? DateTime.parse(booking['startTime'] as String) : null;

                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: (e['isPaid'] as bool? ?? false) ? AppColors.successLight : AppColors.warningLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                (e['isPaid'] as bool? ?? false) ? Icons.check_circle_rounded : Icons.pending_rounded,
                                color: (e['isPaid'] as bool? ?? false) ? AppColors.success : AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(parent?['fullName'] as String? ?? 'Family', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  if (startTime != null)
                                    Text(DateFormat('MMM d, yyyy').format(startTime), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₪${e['netAmountNis']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
                                Text(
                                  (e['isPaid'] as bool? ?? false) ? 'Paid' : 'Pending',
                                  style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                    color: (e['isPaid'] as bool? ?? false) ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: earnings.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EarningStat extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;

  const _EarningStat(this.label, this.value, this.bg);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      );
}
