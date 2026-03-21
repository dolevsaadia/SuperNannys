import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../providers/session_provider.dart';
import '../widgets/session_progress_indicator.dart';
import '../widgets/connected_avatars.dart';
import '../widgets/session_timer_display.dart';
import '../widgets/session_summary_card.dart';

class LiveSessionScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool isParent;

  const LiveSessionScreen({
    super.key,
    required this.bookingId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.isParent,
  });

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Review state
  int _reviewRating = 0;
  final _reviewController = TextEditingController();
  bool _reviewSubmitted = false;
  bool _reviewSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Connect to session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionProvider.notifier).connect(widget.bookingId);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    // Show error snackbar
    ref.listen<SessionState>(sessionProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
        ref.read(sessionProvider.notifier).clearError();
      }
    });

    return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar (always allow back — session continues in background) ──
              _TopBar(
                canPop: true,
                phase: session.phase,
              ),

              // ── Connection lost indicator ────────
              if (!session.socketConnected && session.phase == SessionPhase.active)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: AppColors.warning.withValues(alpha: 0.15),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.warning),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reconnecting to session...',
                        style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

              // ── Progress indicator ───────────────
              SessionProgressIndicator(phase: session.phase),

              // ── Main content ─────────────────────
              Expanded(
                child: _buildPhaseContent(session),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildPhaseContent(SessionState session) {
    final phase = session.phase;

    if (phase == SessionPhase.idle ||
        phase == SessionPhase.promptStart ||
        phase == SessionPhase.waitingStartConfirmation) {
      return _buildStartPhase(session);
    }

    if (phase == SessionPhase.active ||
        phase == SessionPhase.waitingEndConfirmation) {
      return _buildActivePhase(session);
    }

    // ended
    return _buildEndedPhase(session);
  }

  // ═══════════════════════════════════════════════════════
  // ── START PHASE (prompt + waiting merged)
  // ═══════════════════════════════════════════════════════
  Widget _buildStartPhase(SessionState session) {
    final myConfirmed = widget.isParent
        ? session.parentConfirmedStart
        : session.nannyConfirmedStart;
    final otherConfirmed = widget.isParent
        ? session.nannyConfirmedStart
        : session.parentConfirmedStart;
    final isWaiting = session.phase == SessionPhase.waitingStartConfirmation;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Connected avatars
          if (isWaiting)
            ConnectedAvatars(
              userName: 'You',
              userAvatar: null,
              userConfirmed: myConfirmed,
              otherUserName: widget.otherUserName,
              otherUserAvatar: widget.otherUserAvatar,
              otherConfirmed: otherConfirmed,
            )
          else
            // Just the other user's avatar
            Column(
              children: [
                AvatarWidget(
                  imageUrl: widget.otherUserAvatar,
                  name: widget.otherUserName,
                  size: 80,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Context message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isWaiting
                        ? myConfirmed
                            ? 'Waiting for ${widget.otherUserName} to confirm...'
                            : 'Both parties need to confirm to start the session'
                        : widget.isParent
                            ? 'Confirm that the nanny has arrived and the session can begin'
                            : 'Confirm that you have arrived and the session can begin',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Start button or waiting
          if (!myConfirmed)
            ScaleTransition(
              scale: _pulseAnim,
              child: _CircleActionButton(
                icon: Icons.play_arrow_rounded,
                label: 'Start Session',
                color: AppColors.success,
                isLoading: session.isLoading,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  ref.read(sessionProvider.notifier).confirmStart();
                },
              ),
            )
          else
            Column(
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Waiting for confirmation...',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                // Cancel button while waiting
                TextButton.icon(
                  onPressed: session.isLoading ? null : () => _showCancelDialog(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),

          // Cancel button in start phase when user hasn't confirmed yet
          if (!myConfirmed && isWaiting)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: session.isLoading ? null : () => _showCancelDialog(),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ── ACTIVE PHASE (active + waiting end merged)
  // ═══════════════════════════════════════════════════════
  Widget _buildActivePhase(SessionState session) {
    final isEndingFlow = session.phase == SessionPhase.waitingEndConfirmation;
    final myConfirmedEnd = widget.isParent
        ? session.parentConfirmedEnd
        : session.nannyConfirmedEnd;
    final otherConfirmedEnd = widget.isParent
        ? session.nannyConfirmedEnd
        : session.parentConfirmedEnd;

    return Column(
      children: [
        const SizedBox(height: 12),

        // Timer display
        SessionTimerDisplay(session: session),

        const SizedBox(height: 24),

        // If ending flow — show connected avatars
        if (isEndingFlow) ...[
          ConnectedAvatars(
            userName: 'You',
            userAvatar: null,
            userConfirmed: myConfirmedEnd,
            otherUserName: widget.otherUserName,
            otherUserAvatar: widget.otherUserAvatar,
            otherConfirmed: otherConfirmedEnd,
          ),
          const SizedBox(height: 8),
          const Text(
            'Session auto-ends in 10 min if unconfirmed',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ],

        const Spacer(),

        // Bottom action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              if (isEndingFlow && !myConfirmedEnd)
                AppButton(
                  label: 'Confirm End',
                  variant: AppButtonVariant.gradient,
                  isLoading: session.isLoading,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    ref.read(sessionProvider.notifier).confirmEnd();
                  },
                )
              else if (isEndingFlow)
                Column(
                  children: [
                    const Text(
                      'Waiting for the other party to confirm...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: session.isLoading ? null : () => _showCancelDialog(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Cancel Session Instead'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    ),
                  ],
                )
              else
                AppButton(
                  label: 'End Session',
                  variant: AppButtonVariant.danger,
                  isLoading: session.isLoading,
                  onTap: _showEndConfirmDialog,
                ),
              if (!isEndingFlow) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: session.isLoading ? null : () => _showCancelDialog(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Cancel Session'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textHint),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // ── ENDED PHASE
  // ═══════════════════════════════════════════════════════
  Widget _buildEndedPhase(SessionState session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.gradientSuccess,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Session Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Great job! Here\'s your session summary.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // Summary card
          SessionSummaryCard(
            session: session,
            isParent: widget.isParent,
          ),
          const SizedBox(height: 32),

          // ── Review section (parents only) ──────────────────
          if (widget.isParent && !_reviewSubmitted) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Rate Your Experience',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starIndex = i + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _reviewRating = starIndex),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              starIndex <= _reviewRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 36,
                              color: starIndex <= _reviewRating
                                  ? AppColors.warning
                                  : AppColors.textHint,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reviewController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Add a comment (optional)',
                        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: _reviewSubmitting ? 'Submitting...' : 'Submit Review',
                      variant: AppButtonVariant.gradient,
                      onTap: _reviewRating == 0 || _reviewSubmitting
                          ? null
                          : () => _submitReview(session),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_reviewSubmitted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text('Thank you for your review!',
                        style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                AppButton(
                  label: 'Back to Booking',
                  variant: AppButtonVariant.gradient,
                  onTap: () => context.pop(),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Go Home',
                  variant: AppButtonVariant.outline,
                  onTap: () => context.go('/home'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Submit Review ────────────────────────────────────
  Future<void> _submitReview(SessionState session) async {
    setState(() => _reviewSubmitting = true);
    try {
      await apiClient.dio.post('/reviews', data: {
        'bookingId': widget.bookingId,
        'rating': _reviewRating,
        'comment': _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
      });
      triggerDataRefresh(ref);
      setState(() {
        _reviewSubmitted = true;
        _reviewSubmitting = false;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _reviewSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit review. Please try again.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Cancel Confirmation Dialog ────────────────────────────
  void _showCancelDialog() {
    final session = ref.read(sessionProvider);
    final isActive = session.phase == SessionPhase.active ||
        session.phase == SessionPhase.waitingEndConfirmation;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isActive ? 'Cancel Active Session?' : 'Cancel Session Start?',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          isActive
              ? 'This will cancel the active session. No charges will be applied. Both parties will need to confirm again to restart.'
              : 'This will cancel the confirmation. You can restart the session later — both parties will need to confirm again.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Going'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
              ref.read(sessionProvider.notifier).cancelSession();
            },
            child: const Text('Cancel Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── End Confirmation Dialog ────────────────────────────
  void _showEndConfirmDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Session?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Both parties need to confirm. The other party will be notified.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
              ref.read(sessionProvider.notifier).requestEnd();
            },
            child: const Text('End Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ──────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool canPop;
  final SessionPhase phase;

  const _TopBar({required this.canPop, required this.phase});

  String get _title => switch (phase) {
        SessionPhase.idle || SessionPhase.promptStart => 'Start Session',
        SessionPhase.waitingStartConfirmation => 'Confirming...',
        SessionPhase.active => 'Live Session',
        SessionPhase.waitingEndConfirmation => 'Ending...',
        SessionPhase.ended => 'Session Complete',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  // Fallback: go to dashboard/home if no route to pop to
                  context.go('/home');
                }
              },
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              _title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ── Circle Action Button ─────────────────────────────────
class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _CircleActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Icon(icon, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
