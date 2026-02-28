import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';

final _adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final resp = await apiClient.dio.get('/admin/stats');
  return resp.data['data'] as Map<String, dynamic>;
});

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_adminStatsProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (stats) {
          final users = stats['users'] as Map<String, dynamic>;
          final bookings = stats['bookings'] as Map<String, dynamic>;
          final revenue = stats['revenue'] as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Platform Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),

                // Users
                _SectionHeader('Users'),
                Row(
                  children: [
                    Expanded(child: _StatCard('Total', '${users['total']}', AppColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard('Parents', '${users['parents']}', AppColors.accent)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard('Nannies', '${users['nannies']}', AppColors.success)),
                  ],
                ),
                const SizedBox(height: 16),

                // Bookings
                _SectionHeader('Bookings'),
                Row(
                  children: [
                    Expanded(child: _StatCard('Total', '${bookings['total']}', AppColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard('Pending', '${bookings['pending']}', AppColors.warning)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard('Completed', '${bookings['completed']}', AppColors.success)),
                  ],
                ),
                const SizedBox(height: 16),

                // Revenue
                _SectionHeader('Revenue'),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard('Platform Fees', '₪${revenue['platformFees']}', AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard('Gross Volume', '₪${revenue['grossVolume']}', AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick links
                _SectionHeader('Management'),
                const SizedBox(height: 8),
                _MenuTile(
                  icon: Icons.people_rounded,
                  title: 'Manage Users',
                  subtitle: 'View, activate, or deactivate accounts',
                  onTap: () => context.push('/admin/users'),
                ),
                _MenuTile(
                  icon: Icons.calendar_today_rounded,
                  title: 'Review Bookings',
                  subtitle: 'Monitor and manage all bookings',
                  onTap: () => context.push('/admin/bookings'),
                ),
                _MenuTile(
                  icon: Icons.verified_user_rounded,
                  title: 'Verify Nannies',
                  subtitle: 'Review and approve nanny applications',
                  onTap: () => context.push('/admin/verify-nannies'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          onTap: onTap,
        ),
      );
}
