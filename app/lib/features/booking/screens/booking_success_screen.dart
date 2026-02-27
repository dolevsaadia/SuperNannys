import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String bookingId;
  const BookingSuccessScreen({super.key, required this.bookingId});

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
              Container(
                width: 120, height: 120,
                decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success),
              ),
              const SizedBox(height: 32),
              const Text(
                'Booking Requested!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your booking request has been sent to the nanny. You\'ll receive a notification when they respond.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AppButton(
                label: 'View Booking',
                onTap: () => context.go('/bookings/$bookingId'),
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
      ),
    );
  }
}
