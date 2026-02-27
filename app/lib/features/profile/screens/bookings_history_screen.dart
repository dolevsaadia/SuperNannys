import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
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
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_bookingsProvider(status));

    return async.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => EmptyState(title: 'Error', subtitle: e.toString()),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const EmptyState(
            title: 'No bookings yet',
            subtitle: 'Your bookings will appear here',
            icon: Icons.calendar_today_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(_bookingsProvider(status).future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (_, i) {
              final b = bookings[i];
              final fmt = DateFormat('MMM d, yyyy • HH:mm');
              return GestureDetector(
                onTap: () => context.go('/bookings/${b.id}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AvatarWidget(
                            imageUrl: b.nanny?.avatarUrl ?? b.parent?.avatarUrl,
                            name: b.nanny?.fullName ?? b.parent?.fullName,
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.nanny?.fullName ?? b.parent?.fullName ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(fmt.format(b.startTime), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(b.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              b.status,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(b.status)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${b.durationHours.toStringAsFixed(1)}h · ${b.childrenCount} child(ren)',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('₪${b.totalAmountNis}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
                        ],
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
