import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_indicator.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const FullScreenLoader();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Profile hero
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      AvatarWidget(imageUrl: user.avatarUrl, name: user.fullName, size: 90, showBorder: true),
                      if (user.isVerified)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(user.email, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  if (user.isNanny && user.nannyProfile != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ProfileStat('${user.nannyProfile!.rating}', 'Rating'),
                        _ProfileStat('${user.nannyProfile!.reviewsCount}', 'Reviews'),
                        _ProfileStat('${user.nannyProfile!.completedJobs}', 'Jobs'),
                        _ProfileStat('₪${user.nannyProfile!.hourlyRateNis}', '/hour'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/profile/edit'),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                  const SizedBox(height: 8),
                  _MenuGroup(items: [
                    _MenuItem(Icons.calendar_today_rounded, 'My Bookings', () => context.go('/bookings')),
                    if (user.isNanny) ...[
                      _MenuItem(Icons.dashboard_rounded, 'Dashboard', () => context.go('/dashboard')),
                      _MenuItem(Icons.schedule_rounded, 'Manage Availability', () => context.go('/dashboard/availability')),
                      _MenuItem(Icons.account_balance_wallet_rounded, 'Earnings', () => context.go('/dashboard/earnings')),
                    ],
                  ]),
                  const SizedBox(height: 16),
                  const Text('Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                  const SizedBox(height: 8),
                  _MenuGroup(items: [
                    _MenuItem(Icons.notifications_outlined, 'Notifications', () {}),
                    _MenuItem(Icons.lock_outline_rounded, 'Privacy & Security', () {}),
                    _MenuItem(Icons.help_outline_rounded, 'Help & Support', () {}),
                    _MenuItem(Icons.info_outline_rounded, 'About SuperNanny', () {}),
                  ]),
                  const SizedBox(height: 16),
                  _MenuGroup(items: [
                    _MenuItem(Icons.logout_rounded, 'Sign Out', () => _logout(context, ref), isDestructive: true),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Small delay to let dialog animation complete
              await Future.delayed(const Duration(milliseconds: 150));
              await ref.read(authProvider.notifier).logout();
              // GoRouter redirect should handle navigation,
              // but force it as fallback
              if (context.mounted) {
                context.go('/onboarding');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ],
      );
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                ListTile(
                  leading: Icon(e.value.icon, size: 20, color: e.value.isDestructive ? AppColors.error : AppColors.textPrimary),
                  title: Text(
                    e.value.label,
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: e.value.isDestructive ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                  trailing: e.value.isDestructive ? null : const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
                  onTap: e.value.onTap,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                if (!isLast) const Divider(indent: 52, height: 1),
              ],
            );
          }).toList(),
        ),
      );
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem(this.icon, this.label, this.onTap, {this.isDestructive = false});
}
