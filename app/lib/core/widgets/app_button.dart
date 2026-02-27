import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null || isLoading;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_getFgColor()),
            ),
          )
        else ...[
          if (prefixIcon != null) ...[prefixIcon!, const SizedBox(width: 8)],
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _getFgColor())),
          if (suffixIcon != null) ...[const SizedBox(width: 8), suffixIcon!],
        ],
      ],
    );

    final button = AnimatedOpacity(
      opacity: isDisabled ? 0.6 : 1,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: _getBgColor(),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: height ?? 50,
            decoration: variant == AppButtonVariant.outline
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color _getBgColor() => switch (variant) {
        AppButtonVariant.primary => AppColors.primary,
        AppButtonVariant.secondary => AppColors.accent,
        AppButtonVariant.outline => Colors.transparent,
        AppButtonVariant.ghost => Colors.transparent,
        AppButtonVariant.danger => AppColors.error,
      };

  Color _getFgColor() => switch (variant) {
        AppButtonVariant.primary => Colors.white,
        AppButtonVariant.secondary => Colors.white,
        AppButtonVariant.outline => AppColors.primary,
        AppButtonVariant.ghost => AppColors.primary,
        AppButtonVariant.danger => Colors.white,
      };
}
