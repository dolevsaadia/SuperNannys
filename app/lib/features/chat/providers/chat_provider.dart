import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/app_constants.dart';
import '../../../core/models/message_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/services/app_logger.dart';

/// State for a single chat conversation.
class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool otherTyping;
  final bool otherOnline;
  final bool socketConnected;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.otherTyping = false,
    this.otherOnline = false,
    this.socketConnected = false,
    this.error,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? otherTyping,
    bool? otherOnline,
    bool? socketConnected,
    String? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        otherTyping: otherTyping ?? this.otherTyping,
        otherOnline: otherOnline ?? this.otherOnline,
        socketConnected: socketConnected ?? this.socketConnected,
        error: error,
      );
}

/// Manages socket connection + messages for a single booking chat.
/// Auto-disposed when the chat screen is unmounted.
class ChatNotifier extends StateNotifier<ChatState> {
  final String bookingId;
  final String currentUserId;
  final Ref _ref;
  io.Socket? _socket;
  String? _otherUserId;

  ChatNotifier({required this.bookingId, required this.currentUserId, required Ref ref})
      : _ref = ref,
        super(const ChatState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadBookingInfo();
    await _loadMessages();
    await _connectSocket();
  }

  Future<void> _loadBookingInfo() async {
    try {
      final resp = await apiClient.dio.get('/bookings/$bookingId');
      final booking = resp.data['data'] as Map<String, dynamic>;
      final parentId = booking['parentUserId'] as String?;
      final nannyId = booking['nannyUserId'] as String?;
      _otherUserId = currentUserId == parentId ? nannyId : parentId;
    } catch (e) {
      appLog.warn('chat', 'load_booking_info_failed', 'Failed to load booking info: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final resp = await apiClient.dio.get('/messages/$bookingId');
      final list = (resp.data['data']['messages'] as List<dynamic>)
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(messages: list, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load messages');
    }
  }

  Future<void> refreshMessages() => _loadMessages();

  Future<void> _connectSocket() async {
    final token = await apiClient.getToken();
    if (token == null) return;

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('booking:join', bookingId);
      if (mounted) {
        state = state.copyWith(socketConnected: true);
      }
      appLog.debug('chat', 'socket_connected', 'Chat socket connected for booking $bookingId');
    });

    _socket!.onDisconnect((_) {
      if (mounted) {
        state = state.copyWith(socketConnected: false);
      }
    });

    _socket!.onReconnect((_) {
      _socket!.emit('booking:join', bookingId);
      _loadMessages();
      if (mounted) {
        state = state.copyWith(socketConnected: true);
      }
    });

    _socket!.on('message:new', (data) {
      if (!mounted) return;
      final msg = MessageModel.fromJson(data as Map<String, dynamic>);
      final currentMessages = List<MessageModel>.from(state.messages);
      // Avoid duplicates
      if (currentMessages.any((m) => m.id == msg.id)) return;
      currentMessages.add(msg);
      state = state.copyWith(messages: currentMessages);
      // If message is from the other user, mark as read immediately
      if (msg.fromUserId != currentUserId) {
        _markAsRead();
      }
    });

    _socket!.on('typing:start', (_) {
      if (mounted) state = state.copyWith(otherTyping: true);
    });
    _socket!.on('typing:stop', (_) {
      if (mounted) state = state.copyWith(otherTyping: false);
    });

    // Online status tracking
    _socket!.on('user:online-status', (data) {
      if (!mounted || data is! Map) return;
      final targetId = data['userId'] as String?;
      if (targetId == _otherUserId) {
        state = state.copyWith(otherOnline: data['online'] == true);
      }
    });
    _socket!.on('user:online', (data) {
      if (!mounted || data is! Map) return;
      if (data['userId'] == _otherUserId) {
        state = state.copyWith(otherOnline: true);
      }
    });
    _socket!.on('user:offline', (data) {
      if (!mounted || data is! Map) return;
      if (data['userId'] == _otherUserId) {
        state = state.copyWith(otherOnline: false);
      }
    });

    // Check if other user is online
    if (_otherUserId != null) {
      _socket!.emit('user:check-online', _otherUserId);
    }
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _socket?.emit('message:send', {'bookingId': bookingId, 'text': text.trim()});
  }

  void startTyping() {
    _socket?.emit('typing:start', {'bookingId': bookingId});
  }

  void stopTyping() {
    _socket?.emit('typing:stop', {'bookingId': bookingId});
  }

  /// Mark all messages in this chat as read via REST.
  /// This is called on enter and whenever a new message arrives from the other user.
  Future<void> _markAsRead() async {
    try {
      await apiClient.dio.get('/messages/$bookingId');
      // Trigger data refresh so chat list unread badge updates
      triggerDataRefreshFromRef(_ref);
    } catch (_) {}
  }

  /// Reconnect socket if disconnected (e.g. after app resume).
  Future<void> reconnectIfNeeded() async {
    if (_socket == null || _socket!.disconnected) {
      _socket?.dispose();
      _socket = null;
      await _connectSocket();
      await _loadMessages();
    }
  }

  @override
  void dispose() {
    _socket?.emit('booking:leave', bookingId);
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    super.dispose();
  }
}

/// Family provider — one ChatNotifier per bookingId, auto-disposed.
final chatProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, ChatState, String>((ref, bookingId) {
  final currentUser = ref.watch(currentUserProvider);
  return ChatNotifier(
    bookingId: bookingId,
    currentUserId: currentUser?.id ?? '',
    ref: ref,
  );
});
