import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
  };

  @override
  Widget build(BuildContext context) {
    final info = _badges[badge];
    if (info == null) return const SizedBox.shrink();

    final (label, icon, color) = info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
