import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/async_value_ui.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';

final _adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final resp = await apiClient.dio.get('/admin/stats');
  return resp.data['data'] as Map<String, dynamic>;
});

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.signOut, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.signOutConfirmation, style: const TextStyle(color: AppColors.textSecondary)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dc);
              await Future.delayed(const Duration(milliseconds: 150));
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/onboarding');
            },
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_adminStatsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.adminDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_adminStatsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.signOut,
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: async.authAwareWhen(
        ref,
        errorTitle: l10n.couldNotLoadAdminData,
        onRetry: () => ref.invalidate(_adminStatsProvider),
        data: (stats) {
          final users = stats['users'] as Map<String, dynamic>;
          final bookings = stats['bookings'] as Map<String, dynamic>;
          final revenue = stats['revenue'] as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.platformOverview, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),

                // Users
                _SectionHeader(l10n.users),
                Row(
                  children: [
                    Expanded(child: _StatCard(l10n.total, '${users['total']}', AppColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(l10n.parents, '${users['parents']}', AppColors.accent)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(l10n.nannies, '${users['nannies']}', AppColors.success)),
                  ],
                ),
                const SizedBox(height: 16),

                // Bookings
                _SectionHeader(l10n.bookings),
                Row(
                  children: [
                    Expanded(child: _StatCard(l10n.total, '${bookings['total']}', AppColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(l10n.pendingRequests, '${bookings['pending']}', AppColors.warning)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(l10n.completed, '${bookings['completed']}', AppColors.success)),
                  ],
                ),
                const SizedBox(height: 16),

                // Revenue
                _SectionHeader(l10n.revenue),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(l10n.platformFees, '₪${revenue['platformFees']}', AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(l10n.grossVolume, '₪${revenue['grossVolume']}', AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick links
                _SectionHeader(l10n.management),
                const SizedBox(height: 8),
                _MenuTile(
                  icon: Icons.people_rounded,
                  title: l10n.manageUsers,
                  subtitle: l10n.viewActivateDeactivate,
                  onTap: () => context.push('/admin/users'),
                ),
                _MenuTile(
                  icon: Icons.calendar_today_rounded,
                  title: l10n.reviewBookings,
                  subtitle: l10n.monitorManageBookings,
                  onTap: () => context.push('/admin/bookings'),
                ),
                _MenuTile(
                  icon: Icons.verified_user_rounded,
                  title: l10n.verifyNannies,
                  subtitle: l10n.reviewApproveNannies,
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
