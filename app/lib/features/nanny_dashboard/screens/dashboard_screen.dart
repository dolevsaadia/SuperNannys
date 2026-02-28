import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_indicator.dart';

final _dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final [bookingsResp, earningsResp] = await Future.wait([
    apiClient.dio.get('/bookings', queryParameters: {'limit': '10', 'status': 'REQUESTED'}),
    apiClient.dio.get('/users/me/earnings'),
  ]);
  return {
    'pendingBookings': (bookingsResp.data['data']['bookings'] as List<dynamic>)
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    'earnings': earningsResp.data['data']['summary'] as Map<String, dynamic>,
  };
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final async = ref.watch(_dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Gradient Header ──────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.gradientPrimary,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                              ),
                              Text(
                                '${user?.fullName.split(' ').first ?? ''}!',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: LoadingIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error: $e'),
                ),
                data: (data) {
                  final earnings = data['earnings'] as Map<String, dynamic>;
                  final pending = data['pendingBookings'] as List<BookingModel>;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Floating Stats Cards ──────────────────
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _GradientStatCard(
                                  title: 'Total Earned',
                                  value: '\u20AA${earnings['totalEarned'] ?? 0}',
                                  icon: Icons.account_balance_wallet_rounded,
                                  gradient: AppColors.gradientSuccess,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _GradientStatCard(
                                  title: 'Total Jobs',
                                  value: '${earnings['totalJobs'] ?? 0}',
                                  icon: Icons.work_rounded,
                                  gradient: AppColors.gradientAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -8),
                          child: _PendingPayoutCard(amount: earnings['totalPending'] ?? 0),
                        ),

                        const SizedBox(height: 16),

                        // ── Quick Actions ──────────────────
                        const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _PremiumActionCard(
                                icon: Icons.schedule_rounded,
                                label: 'Availability',
                                color: AppColors.primary,
                                onTap: () => context.go('/dashboard/availability'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PremiumActionCard(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Earnings',
                                color: AppColors.success,
                                onTap: () => context.go('/dashboard/earnings'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PremiumActionCard(
                                icon: Icons.person_outline_rounded,
                                label: 'Profile',
                                color: AppColors.accent,
                                onTap: () => context.go('/profile'),
                              ),
                            ),
                          ],
                        ),

                        if (pending.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pending Requests', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                              GestureDetector(
                                onTap: () => context.go('/bookings'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'See all',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...pending.take(3).map((b) => _PremiumPendingCard(booking: b)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient Stat Card ──────────────────
class _GradientStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  const _GradientStatCard({required this.title, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Pending Payout Card ──────────────────
class _PendingPayoutCard extends StatelessWidget {
  final dynamic amount;
  const _PendingPayoutCard({required this.amount});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pending_rounded, color: AppColors.warning, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pending Payout', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('\u20AA$amount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.warning)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
          ],
        ),
      );
}

// ── Premium Action Card ──────────────────
class _PremiumActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PremiumActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

// ── Premium Pending Booking Card ──────────────────
class _PremiumPendingCard extends StatelessWidget {
  final BookingModel booking;
  const _PremiumPendingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d • HH:mm');
    return GestureDetector(
      onTap: () => context.go('/bookings/${booking.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            AvatarWidget(imageUrl: booking.parent?.avatarUrl, name: booking.parent?.fullName, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.parent?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(fmt.format(booking.startTime), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\u20AA${booking.totalAmountNis}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${booking.durationHours.toStringAsFixed(1)}h', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
