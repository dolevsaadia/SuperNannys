import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../l10n/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      q: 'How do I book a nanny?',
      a: 'Browse nannies, select one, choose date/time and confirm.',
    ),
    (
      q: 'How does the timer work?',
      a: 'Both parties confirm start. Timer tracks actual time. Minimum charge is booked duration.',
    ),
    (
      q: 'How are payments calculated?',
      a: 'Based on actual session time. Overtime is charged in 15-minute blocks.',
    ),
    (
      q: 'What are recurring bookings?',
      a: 'Set a fixed weekly schedule with a nanny at a discounted rate.',
    ),
    (
      q: 'How do I cancel a booking?',
      a: 'Open the booking details and tap Cancel. Note cancellation policies may apply.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.helpAndSupport),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── FAQ Section ──────────────────────
          Text(l10n.faq, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.sm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _faqs.asMap().entries.map((e) {
                final isLast = e.key == _faqs.length - 1;
                return Column(
                  children: [
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.primary),
                      ),
                      title: Text(e.value.q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      children: [
                        Text(e.value.a, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                      ],
                    ),
                    if (!isLast) const Divider(indent: 64, height: 1),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ── Contact Section ──────────────────
          Text(l10n.contactUs, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.sm,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.email_outlined, size: 18, color: AppColors.primary),
              ),
              title: const Text('Email Support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              subtitle: const Text('support@supernanny.net', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
            ),
          ),

          const SizedBox(height: 32),

          // ── App Version ──────────────────────
          const Center(
            child: Text('SuperNanny v1.3.0', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          ),
        ],
      ),
    );
  }
}
