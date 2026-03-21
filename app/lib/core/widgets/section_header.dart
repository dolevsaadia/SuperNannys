import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Wolt-style section header with bold title and "More" pill button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  final VoidCallback? onMore;

  const SectionHeader({
    super.key,
    required this.title,
    this.emoji,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.sectionHeaderPadding,
      child: Row(
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
          ),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.borderPill,
                ),
                child: Text(
                  'More',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
