import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_indicator.dart';

final _bookingsProvider = FutureProvider.autoDispose.family<List<BookingModel>, String?>((ref, status) async {
  final params = <String, dynamic>{'limit': '50'};
  if (status != null) params['status'] = status;
  final resp = await apiClient.dio.get('/bookings', queryParameters: params);
  return (resp.data['data']['bookings'] as List<dynamic>)
      .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class BookingsHistoryScreen extends ConsumerStatefulWidget {
  const BookingsHistoryScreen({super.key});

  @override
  ConsumerState<BookingsHistoryScreen> createState() => _BookingsHistoryScreenState();
}

class _BookingsHistoryScreenState extends ConsumerState<BookingsHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  static const _statuses = [null, 'REQUESTED', 'ACCEPTED', 'COMPLETED', 'CANCELLED'];
  static const _labels = ['All', 'Pending', 'Accepted', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelColor: AppColors.textHint,
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: _statuses.map((s) => _BookingsList(status: s)).toList(),
      ),
    );
  }
}

class _BookingsList extends ConsumerWidget {
  final String? status;
  const _BookingsList({this.status});

  Color _statusColor(String s) => switch (s) {
        'REQUESTED' => AppColors.warning,
        'ACCEPTED' => AppColors.success,
        'COMPLETED' => AppColors.primary,
        _ => AppColors.error,
      };

  IconData _statusIcon(String s) => switch (s) {
        'REQUESTED' => Icons.schedule_rounded,
        'ACCEPTED' => Icons.check_circle_outline_rounded,
        'COMPLETED' => Icons.check_circle_rounded,
        _ => Icons.cancel_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_bookingsProvider(status));

    return async.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => EmptyState(title: 'Error', subtitle: e.toString()),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_today_outlined, size: 28, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                const Text('No bookings yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Your bookings will appear here', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(_bookingsProvider(status).future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (_, i) {
              final b = bookings[i];
              final fmt = DateFormat('MMM d, yyyy • HH:mm');
              final sColor = _statusColor(b.status);

              return GestureDetector(
                onTap: () => context.go('/bookings/${b.id}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Row(
                          children: [
                            AvatarWidget(
                              imageUrl: b.nanny?.avatarUrl ?? b.parent?.avatarUrl,
                              name: b.nanny?.fullName ?? b.parent?.fullName,
                              size: 46,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.nanny?.fullName ?? b.parent?.fullName ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textHint),
                                      const SizedBox(width: 4),
                                      Text(fmt.format(b.startTime), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: sColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_statusIcon(b.status), size: 12, color: sColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    b.status,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.bg.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  '${b.durationHours.toStringAsFixed(1)}h',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.child_care_rounded, size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  '${b.childrenCount} child(ren)',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(
                              '\u20AA${b.totalAmountNis}',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
