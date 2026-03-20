import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/chat_provider.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with WidgetsBindingObserver {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  int _prevMessageCount = 0;
  String? _otherPhone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOtherPhone();
  }

  Future<void> _loadOtherPhone() async {
    try {
      final resp = await apiClient.dio.get('/bookings/${widget.bookingId}');
      final booking = resp.data['data'] as Map<String, dynamic>;
      final user = ref.read(currentUserProvider);
      final isParent = user?.isParent == true;
      final other = isParent
          ? booking['nanny'] as Map<String, dynamic>?
          : booking['parent'] as Map<String, dynamic>?;
      final phone = other?['phone'] as String?;
      if (phone != null && phone.isNotEmpty && mounted) {
        setState(() => _otherPhone = phone);
      }
    } catch (_) {}
  }

  Future<void> _callOtherUser() async {
    if (_otherPhone == null) return;
    final uri = Uri.parse('tel:$_otherPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(chatProvider(widget.bookingId).notifier).reconnectIfNeeded();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Scroll to bottom when keyboard opens/closes
    _scrollToBottom();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    ref.read(chatProvider(widget.bookingId).notifier).sendMessage(text);
  }

  void _onTyping(String value) {
    final notifier = ref.read(chatProvider(widget.bookingId).notifier);
    if (value.isNotEmpty) {
      notifier.startTyping();
    } else {
      notifier.stopTyping();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.bookingId));
    final currentUserId = ref.watch(currentUserProvider)?.id;

    // Auto-scroll when new messages arrive
    if (chatState.messages.length > _prevMessageCount) {
      _prevMessageCount = chatState.messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarWidget(imageUrl: widget.otherUserAvatar, name: widget.otherUserName, size: 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: chatState.otherTyping
                      ? const Text('typing...', key: ValueKey('typing'), style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w500))
                      : chatState.otherOnline
                          ? Row(
                              key: const ValueKey('online'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                const Text('Online', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500)),
                              ],
                            )
                          : Row(
                              key: const ValueKey('offline'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 7, height: 7, decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.5), shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                const Text('Offline', style: TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                              ],
                            ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.phone_outlined, size: 18, color: _otherPhone != null ? AppColors.primary : AppColors.textHint),
              onPressed: _otherPhone != null ? _callOtherUser : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Connection lost indicator ──────────────────
          if (!chatState.socketConnected && !chatState.isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: const Text(
                'Reconnecting...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ),

          Expanded(
            child: chatState.isLoading
                ? const Center(child: LoadingIndicator())
                : chatState.messages.isEmpty
                    ? Center(
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
                              child: const Icon(Icons.chat_bubble_outline_rounded, size: 28, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            const Text('Start the conversation!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: chatState.messages.length,
                        itemBuilder: (_, i) {
                          final msg = chatState.messages[i];
                          final isMe = msg.fromUserId == currentUserId;

                          // Date separator
                          Widget? dateSeparator;
                          if (i == 0 || !_isSameDay(chatState.messages[i - 1].createdAt, msg.createdAt)) {
                            dateSeparator = _DateSeparator(date: msg.createdAt);
                          }

                          return Column(
                            children: [
                              if (dateSeparator != null) dateSeparator,
                              _MessageBubble(message: msg, isMe: isMe),
                            ],
                          );
                        },
                      ),
          ),

          // ── Typing indicator ──────────────────
          if (chatState.otherTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) => Padding(
                    padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                    child: _TypingDot(delay: i * 150),
                  )),
                ),
              ),
            ),

          // ── Input bar ──────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.top,
            ),
            padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgController,
                      onChanged: _onTyping,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.primaryGlow(0.2),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Date Separator ──────────────────
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday = date.year == now.year && date.month == now.month && date.day == now.day - 1;

    final label = isToday
        ? 'Today'
        : isYesterday
            ? 'Yesterday'
            : DateFormat('MMM d, yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.divider.withValues(alpha: 0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint),
            ),
          ),
          Expanded(child: Divider(color: AppColors.divider.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

// ── Message Bubble ──────────────────
class _MessageBubble extends StatelessWidget {
  final dynamic message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt.toLocal());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? const LinearGradient(colors: AppColors.gradientPrimary) : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isMe ? 0.08 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white.withValues(alpha: 0.6) : AppColors.textHint,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 3),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: message.isRead ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Typing Dot ──────────────────
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textHint.withValues(alpha: 0.3 + _ctrl.value * 0.5),
            shape: BoxShape.circle,
          ),
        ),
      );
}
