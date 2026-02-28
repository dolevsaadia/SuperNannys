import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: async.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final summary = data['summary'] as Map<String, dynamic>;
          final earnings = data['earnings'] as List<dynamic>;

          return CustomScrollView(
            slivers: [
              // ── Gradient earnings header ──────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientPrimary,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppShadows.primaryGlow(0.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '\u20AA${summary['totalEarned'] ?? 0}',
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _EarningStat('Pending', '\u20AA${summary['totalPending'] ?? 0}', Icons.pending_rounded),
                          const SizedBox(width: 12),
                          _EarningStat('Jobs', '${summary['totalJobs'] ?? 0}', Icons.work_outline_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section Header ──────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      const Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),

              if (earnings.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet_outlined, size: 28, color: AppColors.primary),
                        ),
                        const SizedBox(height: 12),
                        const Text('No earnings yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Complete bookings to see earnings', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
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
                      final isPaid = e['isPaid'] as bool? ?? false;

                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isPaid ? AppColors.gradientSuccess : AppColors.gradientWarm,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    parent?['fullName'] as String? ?? 'Family',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  if (startTime != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(startTime),
                                      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\u20AA${e['netAmountNis']}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPaid ? 'Paid' : 'Pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isPaid ? AppColors.success : AppColors.warning,
                                    ),
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
  final IconData icon;
  const _EarningStat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ],
          ),
        ),
      );
}
