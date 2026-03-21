import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class BadgeChip extends StatelessWidget {
  final String badge;

  const BadgeChip({super.key, required this.badge});

  static const _badges = {
    'VERIFIED': ('Verified', Icons.verified_rounded, AppColors.badgeVerified),
    'FIRST_AID': ('First Aid', Icons.medical_services_outlined, AppColors.badgeFirstAid),
    'TOP_RATED': ('Top Rated', Icons.star_rounded, AppColors.badgeTopRated),
    'FAST_RESPONDER': ('Fast', Icons.bolt_rounded, AppColors.badgeFastResponder),
    'BACKGROUND_CHECKED': ('Checked', Icons.security_rounded, AppColors.badgeBackground),
    'EXPERIENCE_5_PLUS': ('5+ Years', Icons.workspace_premium_rounded, AppColors.primary),
    'RECURRING': ('Recurring', Icons.repeat_rounded, AppColors.accent),
  };

  @override
  Widget build(BuildContext context) {
    final info = _badges[badge];
    if (info == null) return const SizedBox.shrink();

    final (label, icon, color) = info;
    return Container(
      padding: AppSpacing.chipPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderPill,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.captionBold.copyWith(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
