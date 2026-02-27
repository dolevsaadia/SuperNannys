import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_indicator.dart';

final _bookingDetailProvider = FutureProvider.autoDispose.family<BookingModel, String>((ref, id) async {
  final resp = await apiClient.dio.get('/bookings/$id');
  return BookingModel.fromJson(resp.data['data'] as Map<String, dynamic>);
});

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (booking) => _BookingDetailBody(booking: booking),
      ),
    );
  }
}

class _BookingDetailBody extends ConsumerWidget {
  final BookingModel booking;
  const _BookingDetailBody({required this.booking});

  Color _statusColor(String status) => switch (status) {
        'REQUESTED' => AppColors.warning,
        'ACCEPTED' => AppColors.success,
        'COMPLETED' => AppColors.primary,
        'DECLINED' || 'CANCELLED' => AppColors.error,
        _ => AppColors.textHint,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isParent = user?.isParent == true;
    final isNanny = user?.isNanny == true;
    final fmt = DateFormat('EEE, MMM d • HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusColor(booking.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _statusColor(booking.status).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  booking.isCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  color: _statusColor(booking.status),
                ),
                const SizedBox(width: 10),
                Text(
                  booking.status,
                  style: TextStyle(fontWeight: FontWeight.w700, color: _statusColor(booking.status)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Person card
          _InfoCard(
            title: isParent ? 'Your Nanny' : 'Parent',
            child: Row(
              children: [
                AvatarWidget(
                  imageUrl: isParent ? booking.nanny?.avatarUrl : booking.parent?.avatarUrl,
                  name: isParent ? booking.nanny?.fullName : booking.parent?.fullName,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isParent ? booking.nanny?.fullName ?? '' : booking.parent?.fullName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                  onPressed: () => context.go('/chat/${booking.id}', extra: {
                    'otherUserName': isParent ? booking.nanny?.fullName : booking.parent?.fullName,
                    'otherUserAvatar': isParent ? booking.nanny?.avatarUrl : booking.parent?.avatarUrl,
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Time card
          _InfoCard(
            title: 'Schedule',
            child: Column(
              children: [
                _Row(icon: Icons.event_rounded, label: 'Start', value: fmt.format(booking.startTime)),
                const SizedBox(height: 8),
                _Row(icon: Icons.event_rounded, label: 'End', value: fmt.format(booking.endTime)),
                const SizedBox(height: 8),
                _Row(icon: Icons.timer_rounded, label: 'Duration', value: '${booking.durationHours.toStringAsFixed(1)} hours'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Price
          _InfoCard(
            title: 'Payment',
            child: Column(
              children: [
                _Row(icon: Icons.attach_money_rounded, label: 'Rate', value: '₪${booking.hourlyRateNis}/hr'),
                const SizedBox(height: 8),
                _Row(icon: Icons.receipt_rounded, label: 'Total', value: '₪${booking.totalAmountNis}'),
                const SizedBox(height: 8),
                _Row(
                  icon: booking.isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                  label: 'Status',
                  value: booking.isPaid ? 'Paid' : 'Pending',
                  valueColor: booking.isPaid ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Notes',
              child: Text(booking.notes!, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
            ),
          ],

          const SizedBox(height: 24),

          // Actions
          if (isNanny && booking.isRequested) ...[
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Decline',
                    variant: AppButtonVariant.outline,
                    onTap: () => _updateStatus(context, 'DECLINED'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(label: 'Accept', onTap: () => _updateStatus(context, 'ACCEPTED')),
                ),
              ],
            ),
          ],
          if ((isParent || isNanny) && (booking.isRequested || booking.isAccepted))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AppButton(
                label: 'Cancel Booking',
                variant: AppButtonVariant.danger,
                onTap: () => _updateStatus(context, 'CANCELLED'),
              ),
            ),
          if (isNanny && booking.isAccepted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AppButton(
                label: 'Mark as Completed',
                onTap: () => _updateStatus(context, 'COMPLETED'),
              ),
            ),
          if (isParent && booking.isCompleted && booking.review == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AppButton(
                label: 'Leave a Review',
                variant: AppButtonVariant.outline,
                prefixIcon: const Icon(Icons.star_outline_rounded, color: AppColors.primary, size: 20),
                onTap: () => _showReviewDialog(context, booking.id),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      await apiClient.dio.patch('/bookings/${booking.id}/status', data: {'status': status});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking $status')));
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showReviewDialog(BuildContext context, String bookingId) {
    int rating = 5;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Leave a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(i < rating ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.star),
                  onPressed: () => setState(() => rating = i + 1),
                )),
              ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Write your review (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await apiClient.dio.post('/reviews', data: {
                  'bookingId': bookingId, 'rating': rating,
                  if (controller.text.isNotEmpty) 'comment': controller.text,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _Row({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
        ],
      );
}
