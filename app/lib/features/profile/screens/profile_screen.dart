import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/profile_image_picker.dart';
import '../../../core/providers/data_refresh_provider.dart';

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
          // ── Gradient Hero ──────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.gradientPrimary, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      ProfileImagePicker(
                        currentImageUrl: user.avatarUrl,
                        name: user.fullName,
                        size: 90,
                        onUploaded: (_) async {
                          await ref.read(authProvider.notifier).refreshMe();
                          triggerDataRefresh(ref);
                        },
                      ),
                      if (user.isVerified)
                        Positioned(
                          bottom: 0, left: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(user.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(user.email, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(user.role, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  if (user.isNanny && user.nannyProfile != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatPill('${user.nannyProfile!.rating}', 'Rating'),
                        _StatPill('${user.nannyProfile!.reviewsCount}', 'Reviews'),
                        _StatPill('${user.nannyProfile!.completedJobs}', 'Jobs'),
                        _StatPill('\u20AA${user.nannyProfile!.hourlyRateNis}', '/hour'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/profile/edit'),
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                      label: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Menu sections ──────────────────
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
                    _MenuItem(Icons.repeat_rounded, 'Recurring Bookings', () => context.go('/recurring-bookings')),
                    _MenuItem(Icons.favorite_rounded, 'Saved Nannies', () => context.go('/favorites')),
                    if (user.isNanny) ...[
                      _MenuItem(Icons.dashboard_rounded, 'Dashboard', () => context.go('/dashboard')),
                      _MenuItem(Icons.schedule_rounded, 'Manage Availability', () => context.go('/dashboard/availability')),
                      _MenuItem(Icons.account_balance_wallet_rounded, 'Earnings', () => context.go('/dashboard/earnings')),
                      if (!user.isVerified)
                        _MenuItem(Icons.verified_user_rounded, 'Get Verified', () => context.go('/dashboard/verification')),
                      _MenuItem(Icons.description_rounded, 'Documents', () => context.go('/dashboard/documents')),
                    ],
                  ]),
                  const SizedBox(height: 16),
                  const Text('Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                  const SizedBox(height: 8),
                  _MenuGroup(items: [
                    _MenuItem(Icons.notifications_outlined, 'Notifications', () => context.go('/profile/notifications')),
                    _MenuItem(Icons.language_rounded, 'Language', () => context.go('/profile/language')),
                    _MenuItem(Icons.fingerprint_rounded, Platform.isIOS ? 'Face ID / Touch ID' : 'Fingerprint Login', () => _toggleBiometric(context, ref)),
                    _MenuItem(Icons.lock_outline_rounded, 'Privacy & Security', () => context.go('/profile/privacy')),
                    _MenuItem(Icons.help_outline_rounded, 'Help & Support', () => context.go('/profile/help')),
                    _MenuItem(Icons.info_outline_rounded, 'About SuperNanny', () => context.go('/profile/about')),
                  ]),
                  const SizedBox(height: 16),
                  _MenuGroup(items: [
                    _MenuItem(Icons.logout_rounded, 'Sign Out', () => _logout(context, ref), isDestructive: true),
                  ]),
                  const SizedBox(height: 12),
                  _MenuGroup(items: [
                    _MenuItem(Icons.delete_forever_rounded, 'Delete Account', () => _deleteAccount(context, ref), isDestructive: true),
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

  Future<void> _toggleBiometric(BuildContext context, WidgetRef ref) async {
    final biometric = BiometricService();
    final isSupported = await biometric.isDeviceSupported;
    if (!isSupported) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication is not available on this device'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    final isEnabled = await biometric.isEnabled;
    if (isEnabled) {
      // Disable biometric
      await biometric.disable();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric login disabled'), backgroundColor: AppColors.textSecondary),
        );
      }
    } else {
      // Enable biometric — authenticate first, then save token
      final result = await biometric.authenticate(
        reason: 'Verify your identity to enable biometric login',
      );

      switch (result) {
        case BiometricResult.success:
          // Continue to enable
          break;
        case BiometricResult.cancelledByUser:
        case BiometricResult.timeout:
          // User cancelled — do nothing, no error
          return;
        case BiometricResult.unavailable:
        case BiometricResult.lockedOut:
        case BiometricResult.error:
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(biometric.lastError ?? 'Biometric error occurred'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
      }

      final token = await ref.read(authProvider.notifier).getStoredToken();
      if (token != null) {
        await biometric.enable(token);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${Platform.isIOS ? "Face ID / Touch ID" : "Fingerprint"} login enabled!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in again to enable biometric login'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _deleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete Account', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to permanently delete your account?\n\n'
          'This action cannot be undone. All your data will be removed, '
          'and any upcoming bookings will be cancelled.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
            ),
            onPressed: () {
              Navigator.pop(dc);
              _confirmDeleteAccount(context, ref);
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    // Second confirmation
    showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Final Confirmation', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
        content: const Text(
          'This is your last chance. Once deleted, your account and all associated data will be permanently removed.\n\n'
          'Type "DELETE" below is not required — just tap the button to confirm.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text('Keep My Account', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
            ),
            onPressed: () async {
              Navigator.pop(dc);
              await Future.delayed(const Duration(milliseconds: 150));
              final success = await ref.read(authProvider.notifier).deleteAccount();
              if (context.mounted) {
                if (success) {
                  context.go('/onboarding');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Your account has been deleted'), backgroundColor: AppColors.textSecondary),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete account. Please try again.'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Yes, Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Sign Out', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: AppColors.textSecondary)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
            ),
            onPressed: () async {
              Navigator.pop(dc);
              await Future.delayed(const Duration(milliseconds: 150));
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/onboarding');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill(this.value, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
          ],
        ),
      );
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.borderCard, boxShadow: AppShadows.sm),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(children: [
              ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: e.value.isDestructive ? AppColors.errorLight : AppColors.bg,
                    borderRadius: AppRadius.borderLg,
                  ),
                  child: Icon(e.value.icon, size: 18, color: e.value.isDestructive ? AppColors.error : AppColors.textPrimary),
                ),
                title: Text(e.value.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: e.value.isDestructive ? AppColors.error : AppColors.textPrimary)),
                trailing: e.value.isDestructive ? null : const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
                onTap: e.value.onTap,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              ),
              if (!isLast) const Divider(indent: 64, height: 1),
            ]);
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
