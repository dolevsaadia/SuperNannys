import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';

class BookingSuccessScreen extends StatefulWidget {
  final String bookingId;
  const BookingSuccessScreen({super.key, required this.bookingId});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeCtrl.forward();
      HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Animated check icon ──────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientSuccess,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 60, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),

              // ── Title ──────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text(
                      'Booking Requested!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your booking request has been sent to the nanny.\nYou\'ll receive a notification when they respond.',
                      style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── Info pills ──────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.sm,
                      ),
                      child: Row(
                        children: [
                          _InfoPill(
                            icon: Icons.notifications_active_rounded,
                            label: 'Push notification',
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          _InfoPill(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Chat available',
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // ── Buttons ──────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    AppButton(
                      label: 'View Booking',
                      variant: AppButtonVariant.gradient,
                      onTap: () => context.go('/bookings/${widget.bookingId}'),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Back to Home',
                      variant: AppButtonVariant.outline,
                      onTap: () => context.go('/home'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
}
