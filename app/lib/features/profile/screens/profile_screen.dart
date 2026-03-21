import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/profile_image_picker.dart';
import '../../../core/providers/data_refresh_provider.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const FullScreenLoader();
    final l10n = AppLocalizations.of(context);

    final hasImage = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── Profile Hero — image as full background ──────────────
          SliverToBoxAdapter(
            child: _ProfileHero(
              user: user,
              hasImage: hasImage,
              topPadding: topPadding,
              ref: ref,
              onEdit: () => context.go('/profile/edit'),
            ),
          ),

          // ── Nanny stats bar (below hero) ──
          if (user.isNanny && user.nannyProfile != null)
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatPill(Icons.star_rounded, '${user.nannyProfile!.rating}', 'Rating', AppColors.star),
                        _StatPill(Icons.rate_review_rounded, '${user.nannyProfile!.reviewsCount}', 'Reviews', AppColors.primary),
                        _StatPill(Icons.work_rounded, '${user.nannyProfile!.completedJobs}', 'Jobs', AppColors.success),
                        _StatPill(Icons.payments_rounded, '\u20AA${user.nannyProfile!.hourlyRateNis}', '/hour', AppColors.accent),
                      ],
                    ),
                    if (user.nannyProfile!.recurringHourlyRateNis != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.repeat_rounded, size: 16, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text(
                              'Recurring: \u20AA${user.nannyProfile!.recurringHourlyRateNis}/hr',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  Text(l10n.account, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                  const SizedBox(height: 8),
                  _MenuGroup(items: [
                    _MenuItem(Icons.calendar_today_rounded, l10n.myBookings, () => context.go('/bookings')),
                    _MenuItem(Icons.repeat_rounded, l10n.recurringBookings, () => context.go('/recurring-bookings')),
                    _MenuItem(Icons.favorite_rounded, l10n.savedNannies, () => context.go('/favorites')),
                    if (user.isNanny) ...[
                      _MenuItem(Icons.dashboard_rounded, l10n.dashboard, () => context.go('/dashboard')),
                      _MenuItem(Icons.schedule_rounded, l10n.manageAvailability, () => context.go('/dashboard/availability')),
                      _MenuItem(Icons.account_balance_wallet_rounded, l10n.earnings, () => context.go('/dashboard/earnings')),
                      if (!user.isVerified)
                        _MenuItem(Icons.verified_user_rounded, l10n.getVerified, () => context.go('/dashboard/verification')),
                      _MenuItem(Icons.description_rounded, l10n.documents, () => context.go('/dashboard/documents')),
                    ],
                  ]),
                  const SizedBox(height: 16),
                  Text(l10n.settings, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                  const SizedBox(height: 8),
                  _MenuGroup(items: [
                    _MenuItem(Icons.notifications_outlined, l10n.notificationsSettings, () => context.go('/profile/notifications')),
                    _MenuItem(Icons.language_rounded, l10n.language, () => context.go('/profile/language')),
                    _MenuItem(Icons.fingerprint_rounded, Platform.isIOS ? l10n.faceIdTouchId : l10n.fingerprintLogin, () => _toggleBiometric(context, ref)),
                    _MenuItem(Icons.lock_outline_rounded, l10n.privacySettings, () => context.go('/profile/privacy')),
                    _MenuItem(Icons.help_outline_rounded, l10n.helpAndSupport, () => context.go('/profile/help')),
                    _MenuItem(Icons.info_outline_rounded, l10n.aboutSuperNanny, () => context.go('/profile/about')),
                  ]),
                  const SizedBox(height: 16),
                  _MenuGroup(items: [
                    _MenuItem(Icons.logout_rounded, l10n.signOut, () => _logout(context, ref), isDestructive: true),
                  ]),
                  const SizedBox(height: 12),
                  _MenuGroup(items: [
                    _MenuItem(Icons.delete_forever_rounded, l10n.deleteAccount, () => _deleteAccount(context, ref), isDestructive: true),
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
    final l10n = AppLocalizations.of(context);
    final biometric = BiometricService();
    final biometricLabel = l10n.biometric;
    final isSupported = await biometric.isDeviceSupported;
    if (!isSupported) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.biometricNotAvailable), backgroundColor: AppColors.error),
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
          SnackBar(content: Text(l10n.biometricLoginDisabled), backgroundColor: AppColors.textSecondary),
        );
      }
    } else {
      // Enable biometric — authenticate first, then save token
      final result = await biometric.authenticate(
        reason: l10n.verifyIdentityBiometric,
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
              content: Text(l10n.biometricLoginEnabled(biometricLabel)),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.signInAgainBiometric), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _deleteAccount(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.deleteAccount, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.deleteAccountWarning,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.textSecondary)),
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
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Second confirmation
    showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.finalConfirmation, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.finalDeleteWarning,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text(l10n.keepMyAccount, style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
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
                    SnackBar(content: Text(l10n.accountDeleted), backgroundColor: AppColors.textSecondary),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToDeleteAccount), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(l10n.yesDeleteForever),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.signOut, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.signOutConfirmation, style: const TextStyle(color: AppColors.textSecondary)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.textSecondary)),
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
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}

/// Full-width profile hero with image background or purple gradient fallback.
class _ProfileHero extends StatelessWidget {
  final dynamic user;
  final bool hasImage;
  final double topPadding;
  final WidgetRef ref;
  final VoidCallback onEdit;

  const _ProfileHero({
    required this.user,
    required this.hasImage,
    required this.topPadding,
    required this.ref,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background: image or gradient ──
          if (hasImage)
            CachedNetworkImage(
              imageUrl: user.avatarUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _gradientFallback(),
              errorWidget: (_, __, ___) => _gradientFallback(),
            )
          else
            _gradientFallback(),

          // ── Dark gradient overlay for text readability ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),

          // ── Content on top ──
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    user.role,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                // Name
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_rounded, size: 22, color: AppColors.badgeVerified),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  user.email,
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 14),
                // Edit Profile button — glass style
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                    label: Text(AppLocalizations.of(context).editProfile, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Camera edit icon (top-right) ──
          Positioned(
            top: topPadding + 12,
            right: 16,
            child: ProfileImagePicker(
              currentImageUrl: user.avatarUrl,
              name: user.fullName,
              size: 40,
              showImagePreview: false,
              onUploaded: (_) async {
                await ref.read(authProvider.notifier).refreshMe();
                triggerDataRefresh(ref);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.gradientPrimary,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatPill(this.icon, this.value, this.label, this.color);

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
