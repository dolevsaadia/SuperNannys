import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger, gradient }

class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null || widget.isLoading;
    final isGradient = widget.variant == AppButtonVariant.gradient;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_getFgColor()),
            ),
          )
        else ...[
          if (widget.prefixIcon != null) ...[widget.prefixIcon!, const SizedBox(width: 8)],
          Text(
            widget.label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _getFgColor()),
          ),
          if (widget.suffixIcon != null) ...[const SizedBox(width: 8), widget.suffixIcon!],
        ],
      ],
    );

    final button = AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.55 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: widget.height ?? 52,
          decoration: BoxDecoration(
            color: isGradient ? null : _getBgColor(),
            gradient: isGradient
                ? const LinearGradient(colors: AppColors.gradientPrimary, begin: Alignment.topLeft, end: Alignment.bottomRight)
                : (widget.variant == AppButtonVariant.primary
                    ? LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.9)])
                    : null),
            borderRadius: BorderRadius.circular(14),
            border: widget.variant == AppButtonVariant.outline
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
            boxShadow: (widget.variant == AppButtonVariant.primary || isGradient) && !isDisabled
                ? AppShadows.primaryGlow(0.2)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    final wrapped = GestureDetector(
      onTapDown: isDisabled ? null : (_) {
        _scaleCtrl.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: isDisabled ? null : (_) {
        _scaleCtrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: isDisabled ? null : () => _scaleCtrl.reverse(),
      child: button,
    );

    return widget.fullWidth ? SizedBox(width: double.infinity, child: wrapped) : wrapped;
  }

  Color _getBgColor() => switch (widget.variant) {
        AppButtonVariant.primary => AppColors.primary,
        AppButtonVariant.secondary => AppColors.accent,
        AppButtonVariant.outline => Colors.transparent,
        AppButtonVariant.ghost => Colors.transparent,
        AppButtonVariant.danger => AppColors.error,
        AppButtonVariant.gradient => Colors.transparent,
      };

  Color _getFgColor() => switch (widget.variant) {
        AppButtonVariant.primary => Colors.white,
        AppButtonVariant.secondary => Colors.white,
        AppButtonVariant.outline => AppColors.primary,
        AppButtonVariant.ghost => AppColors.primary,
        AppButtonVariant.danger => Colors.white,
        AppButtonVariant.gradient => Colors.white,
      };
}
