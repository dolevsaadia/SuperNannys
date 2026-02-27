import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
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
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${user?.fullName.split(' ').first ?? ''}!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text('Here\'s your nanny dashboard', style: TextStyle(color: AppColors.textSecondary)),
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats cards
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Earned',
                                value: '₪${earnings['totalEarned'] ?? 0}',
                                icon: Icons.account_balance_wallet_rounded,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Total Jobs',
                                value: '${earnings['totalJobs'] ?? 0}',
                                icon: Icons.work_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _StatCard(
                          title: 'Pending Payout',
                          value: '₪${earnings['totalPending'] ?? 0}',
                          icon: Icons.pending_rounded,
                          color: AppColors.warning,
                          wide: true,
                        ),

                        const SizedBox(height: 24),

                        // Quick actions
                        const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.schedule_rounded,
                                label: 'Availability',
                                onTap: () => context.go('/dashboard/availability'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Earnings',
                                onTap: () => context.go('/dashboard/earnings'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.person_outline_rounded,
                                label: 'Profile',
                                onTap: () => context.go('/profile'),
                              ),
                            ),
                          ],
                        ),

                        if (pending.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pending Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              TextButton(
                                onPressed: () => context.go('/bookings'),
                                child: const Text('See all'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...pending.take(3).map((b) => _PendingBookingCard(booking: b)),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, this.wide = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

class _PendingBookingCard extends StatelessWidget {
  final BookingModel booking;
  const _PendingBookingCard({required this.booking});

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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warningLight),
        ),
        child: Row(
          children: [
            AvatarWidget(imageUrl: booking.parent?.avatarUrl, name: booking.parent?.fullName, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.parent?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(fmt.format(booking.startTime), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₪${booking.totalAmountNis}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                Text('${booking.durationHours.toStringAsFixed(1)}h', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
