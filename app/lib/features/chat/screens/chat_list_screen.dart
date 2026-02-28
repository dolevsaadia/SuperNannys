import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:timeago/timeago.dart' as timeago;
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_indicator.dart';

final _conversationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final resp = await apiClient.dio.get('/messages/conversations');
  return resp.data['data'] as List<dynamic>;
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_conversationsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: async.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => EmptyState(title: 'Error', subtitle: e.toString()),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Start a conversation by booking a nanny',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(_conversationsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: conversations.length,
              itemBuilder: (_, i) {
                final conv = conversations[i] as Map<String, dynamic>;
                final messages = conv['messages'] as List<dynamic>? ?? [];
                final lastMsg = messages.isNotEmpty ? messages.first as Map<String, dynamic> : null;
                final unreadCount = (conv['_count'] as Map<String, dynamic>?)?['messages'] as int? ?? 0;

                final isParent = currentUser?.isParent == true;
                final other = isParent
                    ? conv['nanny'] as Map<String, dynamic>?
                    : conv['parent'] as Map<String, dynamic>?;

                final otherName = other?['fullName'] as String? ?? '';
                final otherAvatar = other?['avatarUrl'] as String?;

                final createdAt = lastMsg != null
                    ? DateTime.tryParse(lastMsg['createdAt'] as String? ?? '')
                    : null;

                return GestureDetector(
                  onTap: () => context.go('/chat/${conv['id']}', extra: {
                    'otherUserName': otherName,
                    'otherUserAvatar': otherAvatar,
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: unreadCount > 0 ? AppShadows.md : AppShadows.sm,
                      border: unreadCount > 0 ? Border.all(color: AppColors.primary.withValues(alpha: 0.15)) : null,
                    ),
                    child: Row(
                      children: [
                        // Avatar with unread badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AvatarWidget(imageUrl: otherAvatar, name: otherName, size: 50),
                            if (unreadCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Name + message
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                otherName,
                                style: TextStyle(
                                  fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                lastMsg?['text'] as String? ?? 'No messages yet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: unreadCount > 0 ? AppColors.textPrimary : AppColors.textHint,
                                  fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Time
                        if (createdAt != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                timeago.format(createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: unreadCount > 0 ? AppColors.primary : AppColors.textHint,
                                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              if (unreadCount > 0) ...[
                                const SizedBox(height: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
