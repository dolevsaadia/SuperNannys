import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../providers/session_provider.dart';

/// Premium summary card shown after session ends.
/// Displays total amount as hero number + breakdown rows.
class SessionSummaryCard extends StatelessWidget {
  final SessionState session;
  final bool isParent;

  const SessionSummaryCard({
    super.key,
    required this.session,
    required this.isParent,
  });

  @override
  Widget build(BuildContext context) {
    final total = session.finalAmountNis ?? 0;
    final hasOvertime = (session.overtimeAmountNis ?? 0) > 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          // Hero amount section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Text(
                  isParent ? 'Total Cost' : 'Total Earned',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\u20AA$total',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),

          // Breakdown rows
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _BreakdownRow(
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.primary,
                  label: 'Duration',
                  value: '${session.actualDurationMin ?? 0} min',
                ),
                _divider(),

                if (hasOvertime) ...[
                  _BreakdownRow(
                    icon: Icons.add_alarm_rounded,
                    iconColor: AppColors.warning,
                    label: 'Overtime',
                    value: '+\u20AA${session.overtimeAmountNis}',
                    valueColor: AppColors.warning,
                  ),
                  _divider(),
                ],

                if (session.platformFee != null) ...[
                  _BreakdownRow(
                    icon: Icons.account_balance_rounded,
                    iconColor: AppColors.textHint,
                    label: 'Platform fee (15%)',
                    value: '-\u20AA${session.platformFee}',
                    valueColor: AppColors.textHint,
                  ),
                  _divider(),
                ],

                if (session.netAmountNis != null)
                  _BreakdownRow(
                    icon: isParent
                        ? Icons.payment_rounded
                        : Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.success,
                    label: isParent ? 'You pay' : 'You earn',
                    value: '\u20AA${isParent ? session.finalAmountNis : session.netAmountNis}',
                    valueColor: AppColors.success,
                    isBold: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
      );
}

class _BreakdownRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _BreakdownRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
