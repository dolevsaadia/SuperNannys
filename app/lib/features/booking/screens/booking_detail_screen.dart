import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/services/booking_reminder_service.dart';
import 'booking_map_screen.dart';

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
      backgroundColor: AppColors.bg,
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

  IconData _statusIcon(String status) => switch (status) {
        'REQUESTED' => Icons.schedule_rounded,
        'ACCEPTED' => Icons.check_circle_outline_rounded,
        'COMPLETED' => Icons.check_circle_rounded,
        'DECLINED' || 'CANCELLED' => Icons.cancel_rounded,
        _ => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isParent = user?.isParent == true;
    final isNanny = user?.isNanny == true;
    final fmt = DateFormat('EEE, MMM d • HH:mm');
    final statusColor = _statusColor(booking.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Status Timeline Card ──────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(booking.status), color: statusColor, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  booking.status.replaceAll('_', ' '),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: statusColor),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusDescription(booking.status),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Timeline steps
                _StatusTimeline(currentStatus: booking.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Person card with gradient header ──────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.sm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.gradientPrimary,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(
                    isParent ? 'Your Nanny' : 'Parent',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      AvatarWidget(
                        imageUrl: isParent ? booking.nanny?.avatarUrl : booking.parent?.avatarUrl,
                        name: isParent ? booking.nanny?.fullName : booking.parent?.fullName,
                        size: 50,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isParent ? booking.nanny?.fullName ?? '' : booking.parent?.fullName ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            if (isParent && booking.nanny?.city != null)
                              Text(
                                booking.nanny!.city!,
                                style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                              ),
                          ],
                        ),
                      ),
                      if (booking.nanny?.latitude != null && booking.nanny?.longitude != null)
                        _IconBtn(Icons.map_rounded, AppColors.accent, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingMapScreen(
                                nannyName: booking.nanny!.fullName,
                                nannyLat: booking.nanny!.latitude!,
                                nannyLng: booking.nanny!.longitude!,
                              ),
                            ),
                          );
                        }),
                      const SizedBox(width: 8),
                      _IconBtn(Icons.chat_bubble_outline_rounded, AppColors.primary, () {
                        context.go('/chat/${booking.id}', extra: {
                          'otherUserName': isParent ? booking.nanny?.fullName : booking.parent?.fullName,
                          'otherUserAvatar': isParent ? booking.nanny?.avatarUrl : booking.parent?.avatarUrl,
                        });
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Mini Map ──────────────────
          if (booking.nanny?.latitude != null && booking.nanny?.longitude != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingMapScreen(
                    nannyName: booking.nanny!.fullName,
                    nannyLat: booking.nanny!.latitude!,
                    nannyLng: booking.nanny!.longitude!,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.sm,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SizedBox(
                      height: 160,
                      child: IgnorePointer(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(booking.nanny!.latitude!, booking.nanny!.longitude!),
                            initialZoom: 14,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.supernanny.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(booking.nanny!.latitude!, booking.nanny!.longitude!),
                                  width: 36,
                                  height: 36,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: AppShadows.sm,
                                    ),
                                    child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.place_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            booking.nanny?.city ?? 'See on map',
                            style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          const Text('Tap to expand', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                          const SizedBox(width: 4),
                          const Icon(Icons.open_in_full_rounded, size: 14, color: AppColors.textHint),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Schedule Card ──────────────────
          _PremiumInfoCard(
            icon: Icons.event_rounded,
            iconColor: AppColors.primary,
            title: 'Schedule',
            child: Column(
              children: [
                _PremiumRow(icon: Icons.play_circle_outline_rounded, label: 'Start', value: fmt.format(booking.startTime)),
                _premiumDivider(),
                _PremiumRow(icon: Icons.stop_circle_outlined, label: 'End', value: fmt.format(booking.endTime)),
                _premiumDivider(),
                _PremiumRow(icon: Icons.timer_outlined, label: 'Duration', value: '${booking.durationHours.toStringAsFixed(1)} hours'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Payment Card ──────────────────
          _PremiumInfoCard(
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.success,
            title: 'Payment',
            child: Column(
              children: [
                _PremiumRow(icon: Icons.attach_money_rounded, label: 'Rate', value: '\u20AA${booking.hourlyRateNis}/hr'),
                _premiumDivider(),
                _PremiumRow(
                  icon: Icons.receipt_rounded,
                  label: 'Total',
                  value: '\u20AA${booking.totalAmountNis}',
                  valueBold: true,
                ),
                _premiumDivider(),
                _PremiumRow(
                  icon: booking.isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                  label: 'Status',
                  value: booking.isPaid ? 'Paid' : 'Pending',
                  valueColor: booking.isPaid ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ),

          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _PremiumInfoCard(
              icon: Icons.notes_rounded,
              iconColor: AppColors.accent,
              title: 'Notes',
              child: Text(booking.notes!, style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
            ),
          ],

          const SizedBox(height: 24),

          // ── Actions ──────────────────
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
                  child: AppButton(
                    label: 'Accept',
                    variant: AppButtonVariant.gradient,
                    onTap: () => _updateStatus(context, 'ACCEPTED'),
                  ),
                ),
              ],
            ),
          ],
          if ((isParent || isNanny) && (booking.isRequested || booking.isAccepted))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AppButton(
                label: 'Cancel Booking',
                variant: AppButtonVariant.danger,
                onTap: () => _updateStatus(context, 'CANCELLED'),
              ),
            ),
          if (isNanny && booking.isAccepted)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AppButton(
                label: 'Mark as Completed',
                variant: AppButtonVariant.gradient,
                onTap: () => _updateStatus(context, 'COMPLETED'),
              ),
            ),
          if (isParent && booking.isCompleted && booking.review == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AppButton(
                label: 'Leave a Review',
                variant: AppButtonVariant.outline,
                prefixIcon: const Icon(Icons.star_outline_rounded, color: AppColors.primary, size: 20),
                onTap: () => _showReviewDialog(context, booking.id),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _statusDescription(String status) => switch (status) {
        'REQUESTED' => 'Waiting for nanny to respond',
        'ACCEPTED' => 'Booking confirmed! See you soon',
        'COMPLETED' => 'This booking has been completed',
        'DECLINED' => 'The nanny declined this request',
        'CANCELLED' => 'This booking was cancelled',
        _ => '',
      };

  Widget _premiumDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
      );

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      await apiClient.dio.patch('/bookings/${booking.id}/status', data: {'status': status});

      if (status == 'CANCELLED' || status == 'DECLINED') {
        await BookingReminderService.instance.cancelReminders(booking.id);
      }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Leave a Review', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setState(() => rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.star,
                      size: 36,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write your review (optional)',
                  hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await apiClient.dio.post('/reviews', data: {
                  'bookingId': bookingId,
                  'rating': rating,
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

// ── Icon Button ──────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      );
}

// ── Status Timeline ──────────────────
class _StatusTimeline extends StatelessWidget {
  final String currentStatus;
  const _StatusTimeline({required this.currentStatus});

  static const _steps = ['REQUESTED', 'ACCEPTED', 'COMPLETED'];

  int get _currentIndex {
    if (currentStatus == 'DECLINED' || currentStatus == 'CANCELLED') return -1;
    return _steps.indexOf(currentStatus);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == -1) return const SizedBox.shrink();

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final isDone = stepIdx < _currentIndex;
          return Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: isDone ? AppColors.success : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final isDone = stepIdx <= _currentIndex;
        final isCurrent = stepIdx == _currentIndex;
        return Container(
          width: isCurrent ? 32 : 24,
          height: isCurrent ? 32 : 24,
          decoration: BoxDecoration(
            color: isDone ? AppColors.success : AppColors.bg,
            shape: BoxShape.circle,
            border: isDone ? null : Border.all(color: AppColors.divider, width: 2),
            boxShadow: isCurrent ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 8)] : null,
          ),
          child: isDone
              ? Icon(Icons.check_rounded, size: isCurrent ? 18 : 14, color: Colors.white)
              : null,
        );
      }),
    );
  }
}

// ── Premium Info Card ──────────────────
class _PremiumInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _PremiumInfoCard({required this.icon, required this.iconColor, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

// ── Premium Row ──────────────────
class _PremiumRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;
  const _PremiumRow({required this.icon, required this.label, required this.value, this.valueColor, this.valueBold = false});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: valueBold ? 15 : 13,
              fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      );
}
