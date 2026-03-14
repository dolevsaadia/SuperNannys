import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../providers/pending_session_provider.dart';

/// Persistent banner that appears at the top of the screen
/// when there's a booking ready to start or in progress.
class SessionBanner extends ConsumerWidget {
  const SessionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingBookings = ref.watch(pendingSessionProvider);
    final user = ref.watch(currentUserProvider);

    if (pendingBookings.isEmpty || user == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: pendingBookings.map((booking) {
        return _SessionBannerCard(
          booking: booking,
          isParent: user.isParent,
        );
      }).toList(),
    );
  }
}

class _SessionBannerCard extends StatefulWidget {
  final BookingModel booking;
  final bool isParent;

  const _SessionBannerCard({
    required this.booking,
    required this.isParent,
  });

  @override
  State<_SessionBannerCard> createState() => _SessionBannerCardState();
}

class _SessionBannerCardState extends State<_SessionBannerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInProgress = widget.booking.isInProgress;
    final accentColor = isInProgress ? AppColors.accent : AppColors.primary;
    final otherName = widget.isParent
        ? widget.booking.nanny?.fullName ?? 'Nanny'
        : widget.booking.parent?.fullName ?? 'Parent';
    final otherAvatar = widget.isParent
        ? widget.booking.nanny?.avatarUrl
        : widget.booking.parent?.avatarUrl;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/session/${widget.booking.id}', extra: {
          'otherUserName': otherName,
          'otherUserAvatar': otherAvatar,
          'isParent': widget.isParent,
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            ...AppShadows.sm,
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Pulsing dot
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(
                                alpha: 0.5 + _pulseAnim.value * 0.5),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(
                                    alpha: 0.2 + _pulseAnim.value * 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Avatar
                      AvatarWidget(
                        imageUrl: otherAvatar,
                        name: otherName,
                        size: 36,
                      ),
                      const SizedBox(width: 12),

                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isInProgress
                                  ? 'Session in progress'
                                  : 'Session ready to start',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'with $otherName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Chevron
                      Icon(
                        Icons.chevron_right_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
