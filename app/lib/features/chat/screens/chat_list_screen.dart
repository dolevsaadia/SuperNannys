import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(title: const Text('Messages'), backgroundColor: Colors.white),
      body: async.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => EmptyState(title: 'Error', subtitle: e.toString()),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const EmptyState(
              title: 'No messages yet',
              subtitle: 'Start a conversation by booking a nanny',
              icon: Icons.chat_bubble_outline_rounded,
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(_conversationsProvider.future),
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(indent: 72, height: 1),
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

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AvatarWidget(imageUrl: otherAvatar, name: otherName, size: 50),
                      if (unreadCount > 0)
                        Positioned(
                          top: -2, right: -2,
                          child: Container(
                            width: 18, height: 18,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: Center(
                              child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(otherName, style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w600)),
                  subtitle: Text(
                    lastMsg?['text'] as String? ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: unreadCount > 0 ? AppColors.textPrimary : AppColors.textHint,
                      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  trailing: createdAt != null
                      ? Text(timeago.format(createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint))
                      : null,
                  onTap: () => context.go('/chat/${conv['id']}', extra: {
                    'otherUserName': otherName,
                    'otherUserAvatar': otherAvatar,
                  }),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
