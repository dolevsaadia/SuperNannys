import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../l10n/app_localizations.dart';

class BookingSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  const BookingSummaryScreen({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nannyName = bookingData['nannyName'] as String? ?? l.nanny;
    final isRecurring = bookingData['isRecurring'] as bool? ?? false;
    final hourlyRate = bookingData['hourlyRate'] as int? ?? 0;
    final totalAmount = bookingData['totalAmount'] as int? ?? 0;
    final durationHours = bookingData['durationHours'] as double? ?? 0;
    final childrenCount = bookingData['childrenCount'] as int? ?? 1;
    final address = bookingData['address'] as String? ?? '';
    final notes = bookingData['notes'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l.bookingSummary),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nanny info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nannyName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                Text(
                                  isRecurring ? l.recurringBookingLabel : l.oneTimeBookingLabel,
                                  style: TextStyle(fontSize: 13, color: isRecurring ? AppColors.accent : AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.sm,
                      ),
                      child: Column(
                        children: [
                          _DetailRow(icon: Icons.schedule_rounded, label: l.duration, value: l.hoursLabel(durationHours.toStringAsFixed(1))),
                          const Divider(height: 20),
                          _DetailRow(icon: Icons.child_care_rounded, label: l.children, value: '$childrenCount'),
                          if (address.isNotEmpty) ...[
                            const Divider(height: 20),
                            _DetailRow(icon: Icons.location_on_outlined, label: l.address, value: address),
                          ],
                          if (notes.isNotEmpty) ...[
                            const Divider(height: 20),
                            _DetailRow(icon: Icons.note_outlined, label: l.notes, value: notes),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pricing
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l.hourlyRate, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                              Text('\u20AA$hourlyRate/hr', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l.estimatedTotal, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                              Text('~\u20AA$totalAmount', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payment note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.paymentChargedAfterSession,
                              style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
        ],
      );
}
