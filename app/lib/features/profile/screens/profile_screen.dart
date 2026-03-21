import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
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
          // ── Premium Profile Hero Card ──────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.gradientPrimary, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // ── Card-style profile image block ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.borderCardLg,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Image board area ──
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.cardLg),
                                ),
                                child: ProfileImageBoard(
                                  currentImageUrl: user.avatarUrl,
                                  name: user.fullName,
                                  height: 200,
                                  onUploaded: (_) async {
                                    await ref.read(authProvider.notifier).refreshMe();
                                    triggerDataRefresh(ref);
                                  },
                                ),
                              ),
                              // Verified badge
                              if (user.isVerified)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: AppShadows.sm,
                                    ),
                                    child: const Icon(Icons.verified_rounded, size: 20, color: AppColors.badgeVerified),
                                  ),
                                ),
                              // Role badge
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: AppRadius.borderMd,
                                  ),
                                  child: Text(
                                    user.role,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // ── Info section ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              children: [
                                Text(
                                  user.fullName,
                                  style: AppTextStyles.heading2.copyWith(fontSize: 22),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: AppTextStyles.bodySmall,
                                ),
                                if (user.isNanny && user.nannyProfile != null) ...[
                                  const SizedBox(height: 14),
                                  // Stats row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _CardStat(Icons.star_rounded, '${user.nannyProfile!.rating}', 'Rating', AppColors.star),
                                      _CardStat(Icons.rate_review_rounded, '${user.nannyProfile!.reviewsCount}', 'Reviews', AppColors.primary),
                                      _CardStat(Icons.work_rounded, '${user.nannyProfile!.completedJobs}', 'Jobs', AppColors.success),
                                      _CardStat(Icons.payments_rounded, '\u20AA${user.nannyProfile!.hourlyRateNis}', '/hour', AppColors.accent),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── Edit Profile button ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
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
                  ),
                  const SizedBox(height: 20),
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

class _CardStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _CardStat(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderLg,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.heading3.copyWith(fontSize: 15)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
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
