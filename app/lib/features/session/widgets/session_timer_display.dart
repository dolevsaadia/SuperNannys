import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/session_provider.dart';

/// Full-width timer card that replaces the old 220px circle.
/// Shows elapsed time, current cost, progress bar, and info pills.
class SessionTimerDisplay extends StatelessWidget {
  final SessionState session;
  const SessionTimerDisplay({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final progress = session.bookedDurationMin > 0
        ? (session.elapsedSeconds / (session.bookedDurationMin * 60)).clamp(0.0, 2.0)
        : 0.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: session.isOvertime
              ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
              : AppColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (session.isOvertime ? AppColors.warning : AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Overtime badge
          if (session.isOvertime)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'OVERTIME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          // Timer
          Text(
            session.formattedTime,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),

          // Current amount
          Text(
            '\u20AA${session.currentAmountNis}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  session.isOvertime
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info pills
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  icon: Icons.schedule_rounded,
                  label: 'Booked: ${session.bookedDurationMin} min',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoPill(
                  icon: Icons.attach_money_rounded,
                  label: 'Rate: \u20AA${session.hourlyRateNis}/hr',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
