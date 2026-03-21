import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:timeago/timeago.dart' as timeago;
import '../../../core/network/api_client.dart';
import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/utils/async_value_ui.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';

final _conversationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(dataRefreshProvider);
  final resp = await apiClient.dio.get('/messages/conversations');
  return resp.data['data'] as List<dynamic>;
});

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Poll for new messages / unread changes every 10 seconds while on this screen
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(_conversationsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String bookingId, String otherName) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.deleteChat, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(
          l.hideChatMessage(otherName),
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: Text(l.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dc);
              try {
                await apiClient.dio.delete('/messages/$bookingId/hide');
                ref.invalidate(_conversationsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.chatRemoved), backgroundColor: AppColors.textSecondary),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.couldNotDeleteChat), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_conversationsProvider);
    final currentUser = ref.watch(currentUserProvider);

    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l.messages),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: async.authAwareWhen(
        ref,
        loading: () => const SkeletonList(count: 6, skeleton: ChatSkeleton()),
        errorTitle: l.couldNotLoadMessages,
        onRetry: () => ref.invalidate(_conversationsProvider),
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
                  Text(
                    l.noMessagesYet,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.startConversationByBooking,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                  onLongPress: () => _showDeleteDialog(
                    context,
                    ref,
                    conv['id'] as String,
                    otherName,
                  ),
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
                                lastMsg?['text'] as String? ?? l.noMessagesYet,
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
