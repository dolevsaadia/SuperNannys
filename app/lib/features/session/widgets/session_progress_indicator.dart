import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/session_provider.dart';

/// Horizontal 3-step indicator: Start → Active → Complete
class SessionProgressIndicator extends StatelessWidget {
  final SessionPhase phase;
  const SessionProgressIndicator({super.key, required this.phase});

  int get _currentStep {
    switch (phase) {
      case SessionPhase.idle:
      case SessionPhase.promptStart:
      case SessionPhase.waitingStartConfirmation:
        return 0;
      case SessionPhase.active:
      case SessionPhase.waitingEndConfirmation:
        return 1;
      case SessionPhase.ended:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          _StepDot(
            label: 'Start',
            index: 0,
            currentStep: _currentStep,
            icon: Icons.play_arrow_rounded,
          ),
          Expanded(child: _StepLine(completed: _currentStep > 0)),
          _StepDot(
            label: 'Active',
            index: 1,
            currentStep: _currentStep,
            icon: Icons.timer_rounded,
          ),
          Expanded(child: _StepLine(completed: _currentStep > 1)),
          _StepDot(
            label: 'Complete',
            index: 2,
            currentStep: _currentStep,
            icon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final int index;
  final int currentStep;
  final IconData icon;

  const _StepDot({
    required this.label,
    required this.index,
    required this.currentStep,
    required this.icon,
  });

  bool get _isCompleted => index < currentStep;
  bool get _isCurrent => index == currentStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isCurrent ? 44 : 36,
          height: _isCurrent ? 44 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isCompleted
                ? AppColors.success
                : _isCurrent
                    ? AppColors.primary
                    : AppColors.divider,
            boxShadow: _isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            _isCompleted ? Icons.check_rounded : icon,
            size: _isCurrent ? 22 : 18,
            color: (_isCompleted || _isCurrent) ? Colors.white : AppColors.textHint,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: _isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: _isCurrent
                ? AppColors.primary
                : _isCompleted
                    ? AppColors.success
                    : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool completed;
  const _StepLine({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.only(bottom: 20), // offset for label below dots
      decoration: BoxDecoration(
        color: completed ? AppColors.success : AppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
