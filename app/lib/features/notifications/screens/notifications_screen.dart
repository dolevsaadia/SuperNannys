import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/utils/async_value_ui.dart';

final _notificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final resp = await apiClient.dio.get('/users/me/notifications');
  final list = resp.data['data']['notifications'] as List<dynamic>? ?? [];
  return list.cast<Map<String, dynamic>>();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await apiClient.dio.patch('/users/me/notifications/read-all');
                ref.invalidate(_notificationsProvider);
              } catch (_) {}
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: async.authAwareWhen(
        ref,
        loading: () => const FullScreenLoader(),
        errorTitle: 'Could not load notifications',
        onRetry: () => ref.invalidate(_notificationsProvider),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded,
                          size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'When you receive booking updates, messages, or other alerts, they\'ll appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(_notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(notification: n);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  const _NotificationTile({required this.notification});

  static const _typeIcons = <String, IconData>{
    'BOOKING_REQUESTED': Icons.calendar_today_rounded,
    'BOOKING_ACCEPTED': Icons.check_circle_rounded,
    'BOOKING_REJECTED': Icons.cancel_rounded,
    'BOOKING_CANCELLED': Icons.event_busy_rounded,
    'SESSION_STARTED': Icons.play_circle_rounded,
    'SESSION_ENDED': Icons.stop_circle_rounded,
    'NEW_MESSAGE': Icons.chat_bubble_rounded,
    'NEW_REVIEW': Icons.star_rounded,
    'PAYMENT_RECEIVED': Icons.payments_rounded,
    'VERIFICATION_APPROVED': Icons.verified_rounded,
    'VERIFICATION_REJECTED': Icons.gpp_bad_rounded,
  };

  static const _typeColors = <String, Color>{
    'BOOKING_REQUESTED': AppColors.primary,
    'BOOKING_ACCEPTED': AppColors.success,
    'BOOKING_REJECTED': AppColors.error,
    'BOOKING_CANCELLED': AppColors.warning,
    'SESSION_STARTED': AppColors.success,
    'SESSION_ENDED': AppColors.info,
    'NEW_MESSAGE': AppColors.accent,
    'NEW_REVIEW': AppColors.star,
    'PAYMENT_RECEIVED': AppColors.success,
    'VERIFICATION_APPROVED': AppColors.success,
    'VERIFICATION_REJECTED': AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] as String? ?? '';
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final isRead = notification['isRead'] as bool? ?? false;
    final createdAt = notification['createdAt'] as String?;
    final icon = _typeIcons[type] ?? Icons.notifications_rounded;
    final color = _typeColors[type] ?? AppColors.textHint;

    String timeAgo = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else if (diff.inDays < 7) {
          timeAgo = '${diff.inDays}d ago';
        } else {
          timeAgo = DateFormat('MMM d').format(dt);
        }
      } catch (_) {}
    }

    return Container(
      color: isRead ? Colors.transparent : AppColors.primarySoft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (timeAgo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
