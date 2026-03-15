import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/recurring_booking_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';

final _recurringDetailProvider =
    FutureProvider.autoDispose.family<RecurringBookingModel, String>((ref, id) async {
  final resp = await apiClient.dio.get('/recurring-bookings/$id');
  return RecurringBookingModel.fromJson(resp.data['data'] as Map<String, dynamic>);
});

class RecurringBookingDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const RecurringBookingDetailScreen({super.key, required this.id});

  @override
  ConsumerState<RecurringBookingDetailScreen> createState() => _RecurringBookingDetailScreenState();
}

class _RecurringBookingDetailScreenState extends ConsumerState<RecurringBookingDetailScreen> {
  bool _isLoading = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      await apiClient.dio.patch('/recurring-bookings/${widget.id}/status', data: {'status': status});
      ref.invalidate(_recurringDetailProvider(widget.id));
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_recurringDetailProvider(widget.id));
    final authState = ref.watch(authProvider);
    final myRole = authState.user?.role ?? 'PARENT';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Recurring Details'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: async.when(
        loading: () => const FullScreenLoader(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Could not load details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.invalidate(_recurringDetailProvider(widget.id)),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rb) => _DetailBody(
          rb: rb,
          myRole: myRole,
          isLoading: _isLoading,
          onUpdateStatus: _updateStatus,
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final RecurringBookingModel rb;
  final String myRole;
  final bool isLoading;
  final ValueChanged<String> onUpdateStatus;

  const _DetailBody({
    required this.rb,
    required this.myRole,
    required this.isLoading,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (rb.status) {
      'ACTIVE' => AppColors.success,
      'PENDING' => AppColors.warning,
      'PAUSED' => AppColors.textHint,
      _ => AppColors.error,
    };

    final fmt = DateFormat('MMM d, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status Header ──────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  rb.isActive
                      ? Icons.repeat_rounded
                      : rb.isPending
                          ? Icons.hourglass_top_rounded
                          : Icons.pause_circle_rounded,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  rb.status,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  rb.scheduleLabel,
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Schedule Card ──────────────────
          _SectionCard(
            title: 'Schedule',
            icon: Icons.calendar_view_week_rounded,
            children: [
              _DetailRow('Days', rb.daysLabel),
              _DetailRow('Hours', '${rb.startTime} \u2013 ${rb.endTime}'),
              _DetailRow('Start Date', fmt.format(rb.startDate)),
              _DetailRow('End Date', rb.endDate != null ? fmt.format(rb.endDate!) : 'No end date'),
            ],
          ),

          const SizedBox(height: 14),

          // ── Pricing Card ──────────────────
          _SectionCard(
            title: 'Pricing',
            icon: Icons.attach_money_rounded,
            children: [
              _DetailRow('Hourly Rate', '\u20AA${rb.hourlyRateNis}/hr'),
              _DetailRow('Weekly Estimate', '~\u20AA${rb.weeklyEstimatedCostNis}/week'),
              _DetailRow('Sessions Completed', '${rb.bookingsCount}'),
            ],
          ),

          const SizedBox(height: 14),

          // ── Details Card ──────────────────
          _SectionCard(
            title: 'Details',
            icon: Icons.info_outline_rounded,
            children: [
              _DetailRow('Children', '${rb.childrenCount}'),
              if (rb.address != null && rb.address!.isNotEmpty)
                _DetailRow('Address', rb.address!),
              if (rb.notes != null && rb.notes!.isNotEmpty)
                _DetailRow('Notes', rb.notes!),
            ],
          ),

          const SizedBox(height: 24),

          // ── Action Buttons ──────────────────
          if (rb.isPending && myRole == 'NANNY') ...[
            AppButton(
              label: 'Accept',
              variant: AppButtonVariant.gradient,
              isLoading: isLoading,
              onTap: () => onUpdateStatus('ACTIVE'),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Decline',
              variant: AppButtonVariant.outline,
              isLoading: isLoading,
              onTap: () => onUpdateStatus('CANCELLED'),
            ),
          ],

          if (rb.isActive) ...[
            AppButton(
              label: 'Pause',
              variant: AppButtonVariant.outline,
              prefixIcon: const Icon(Icons.pause_rounded, size: 18),
              isLoading: isLoading,
              onTap: () => onUpdateStatus('PAUSED'),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'End Recurring Booking',
              variant: AppButtonVariant.outline,
              isLoading: isLoading,
              onTap: () => _showEndConfirmation(context),
            ),
          ],

          if (rb.isPaused) ...[
            AppButton(
              label: 'Resume',
              variant: AppButtonVariant.gradient,
              prefixIcon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
              isLoading: isLoading,
              onTap: () => onUpdateStatus('ACTIVE'),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'End Recurring Booking',
              variant: AppButtonVariant.outline,
              isLoading: isLoading,
              onTap: () => _showEndConfirmation(context),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showEndConfirmation(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Recurring Booking?'),
        content: const Text(
          'This will stop generating new sessions. Existing scheduled sessions will not be cancelled.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onUpdateStatus('ENDED');
            },
            child: const Text('End', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
}
