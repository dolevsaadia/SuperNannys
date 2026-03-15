import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

/// Session phase — mirrors server-side phases
enum SessionPhase {
  idle,
  promptStart,
  waitingStartConfirmation,
  active,
  waitingEndConfirmation,
  ended,
}

/// Live session state
class SessionState {
  final SessionPhase phase;
  final String? bookingId;
  final bool parentConfirmedStart;
  final bool nannyConfirmedStart;
  final bool parentConfirmedEnd;
  final bool nannyConfirmedEnd;
  final int elapsedSeconds;
  final bool isOvertime;
  final int currentAmountNis;
  final int bookedDurationMin;
  final int hourlyRateNis;
  final int? actualDurationMin;
  final int? finalAmountNis;
  final int? overtimeAmountNis;
  final int? platformFee;
  final int? netAmountNis;
  final String? actualStartTime;
  final String? error;
  final bool isLoading;

  const SessionState({
    this.phase = SessionPhase.idle,
    this.bookingId,
    this.parentConfirmedStart = false,
    this.nannyConfirmedStart = false,
    this.parentConfirmedEnd = false,
    this.nannyConfirmedEnd = false,
    this.elapsedSeconds = 0,
    this.isOvertime = false,
    this.currentAmountNis = 0,
    this.bookedDurationMin = 0,
    this.hourlyRateNis = 0,
    this.actualDurationMin,
    this.finalAmountNis,
    this.overtimeAmountNis,
    this.platformFee,
    this.netAmountNis,
    this.actualStartTime,
    this.error,
    this.isLoading = false,
  });

  SessionState copyWith({
    SessionPhase? phase,
    String? bookingId,
    bool? parentConfirmedStart,
    bool? nannyConfirmedStart,
    bool? parentConfirmedEnd,
    bool? nannyConfirmedEnd,
    int? elapsedSeconds,
    bool? isOvertime,
    int? currentAmountNis,
    int? bookedDurationMin,
    int? hourlyRateNis,
    int? actualDurationMin,
    int? finalAmountNis,
    int? overtimeAmountNis,
    int? platformFee,
    int? netAmountNis,
    String? actualStartTime,
    String? error,
    bool? isLoading,
  }) {
    return SessionState(
      phase: phase ?? this.phase,
      bookingId: bookingId ?? this.bookingId,
      parentConfirmedStart: parentConfirmedStart ?? this.parentConfirmedStart,
      nannyConfirmedStart: nannyConfirmedStart ?? this.nannyConfirmedStart,
      parentConfirmedEnd: parentConfirmedEnd ?? this.parentConfirmedEnd,
      nannyConfirmedEnd: nannyConfirmedEnd ?? this.nannyConfirmedEnd,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isOvertime: isOvertime ?? this.isOvertime,
      currentAmountNis: currentAmountNis ?? this.currentAmountNis,
      bookedDurationMin: bookedDurationMin ?? this.bookedDurationMin,
      hourlyRateNis: hourlyRateNis ?? this.hourlyRateNis,
      actualDurationMin: actualDurationMin ?? this.actualDurationMin,
      finalAmountNis: finalAmountNis ?? this.finalAmountNis,
      overtimeAmountNis: overtimeAmountNis ?? this.overtimeAmountNis,
      platformFee: platformFee ?? this.platformFee,
      netAmountNis: netAmountNis ?? this.netAmountNis,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Format elapsed time as HH:MM:SS
  String get formattedTime {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

/// Session notifier — manages socket connection and session state
class SessionNotifier extends StateNotifier<SessionState> {
  io.Socket? _socket;
  Timer? _localTimer;
  DateTime? _startTime;

  SessionNotifier() : super(const SessionState());

  /// Connect to socket and join booking room
  Future<void> connect(String bookingId) async {
    state = state.copyWith(bookingId: bookingId, isLoading: true, error: null);

    final token = await apiClient.getToken();
    if (token == null) {
      state = state.copyWith(isLoading: false, error: 'Not authenticated');
      return;
    }

    // Disconnect previous socket
    disconnect();

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(10)
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('booking:join', bookingId);
      // Request current state from server
      _socket!.emit('session:get-state', {'bookingId': bookingId});
    });

    _socket!.onReconnect((_) {
      // Re-join room and resync state after reconnection
      _socket!.emit('booking:join', bookingId);
      _socket!.emit('session:get-state', {'bookingId': bookingId});
    });

    // ── Session events ───────────────────────────────────
    _socket!.on('session:state', (data) {
      _handleStateUpdate(data as Map<String, dynamic>);
    });

    _socket!.on('session:start-confirmed', (data) {
      final d = data as Map<String, dynamic>;
      state = state.copyWith(
        parentConfirmedStart: d['parentConfirmed'] as bool? ?? false,
        nannyConfirmedStart: d['nannyConfirmed'] as bool? ?? false,
        phase: (d['parentConfirmed'] == true && d['nannyConfirmed'] == true)
            ? SessionPhase.active
            : SessionPhase.waitingStartConfirmation,
      );
    });

    _socket!.on('session:started', (data) {
      final d = data as Map<String, dynamic>;
      _startTime = DateTime.parse(d['actualStartTime'] as String);
      state = state.copyWith(
        phase: SessionPhase.active,
        actualStartTime: d['actualStartTime'] as String?,
        bookedDurationMin: d['bookedDurationMin'] as int? ?? 0,
        hourlyRateNis: d['hourlyRateNis'] as int? ?? 0,
        parentConfirmedStart: true,
        nannyConfirmedStart: true,
      );
      _startLocalTimer();
    });

    _socket!.on('session:tick', (data) {
      final d = data as Map<String, dynamic>;
      state = state.copyWith(
        elapsedSeconds: d['elapsedSeconds'] as int? ?? 0,
        isOvertime: d['isOvertime'] as bool? ?? false,
        currentAmountNis: d['currentAmountNis'] as int? ?? 0,
        bookedDurationMin: d['bookedDurationMin'] as int? ?? state.bookedDurationMin,
      );
    });

    _socket!.on('session:end-requested', (data) {
      final d = data as Map<String, dynamic>;
      state = state.copyWith(
        parentConfirmedEnd: d['parentConfirmed'] as bool? ?? false,
        nannyConfirmedEnd: d['nannyConfirmed'] as bool? ?? false,
        phase: SessionPhase.waitingEndConfirmation,
      );
    });

    _socket!.on('session:ended', (data) {
      final d = data as Map<String, dynamic>;
      _stopLocalTimer();
      state = state.copyWith(
        phase: SessionPhase.ended,
        actualDurationMin: d['actualDurationMin'] as int?,
        finalAmountNis: d['finalAmountNis'] as int?,
        overtimeAmountNis: d['overtimeAmountNis'] as int?,
        platformFee: d['platformFee'] as int?,
        netAmountNis: d['netAmountNis'] as int?,
      );
    });

    _socket!.on('session:timeout', (data) {
      _stopLocalTimer();
      state = state.copyWith(
        phase: SessionPhase.idle,
        error: 'Session timed out',
      );
    });

    _socket!.on('session:error', (data) {
      final d = data as Map<String, dynamic>;
      state = state.copyWith(
        error: d['message'] as String? ?? 'Unknown error',
        isLoading: false,
      );
    });

    _socket!.onDisconnect((_) {
      // Don't reset state, just flag
    });

    state = state.copyWith(isLoading: false);
  }

  /// Handle full state update from server
  void _handleStateUpdate(Map<String, dynamic> data) {
    final phaseStr = data['phase'] as String? ?? 'idle';
    final phase = _parsePhase(phaseStr);

    state = state.copyWith(
      phase: phase,
      bookingId: data['bookingId'] as String? ?? state.bookingId,
      parentConfirmedStart: data['parentConfirmedStart'] as bool? ?? false,
      nannyConfirmedStart: data['nannyConfirmedStart'] as bool? ?? false,
      parentConfirmedEnd: data['parentConfirmedEnd'] as bool? ?? false,
      nannyConfirmedEnd: data['nannyConfirmedEnd'] as bool? ?? false,
      actualStartTime: data['actualStartTime'] as String?,
      actualDurationMin: data['actualDurationMin'] as int?,
      finalAmountNis: data['finalAmountNis'] as int?,
      overtimeAmountNis: data['overtimeAmountNis'] as int?,
      bookedDurationMin: data['bookedDurationMin'] as int? ?? 0,
      hourlyRateNis: data['hourlyRateNis'] as int? ?? 0,
      isLoading: false,
    );

    // Handle timer data
    final timer = data['timer'] as Map<String, dynamic>?;
    if (timer != null) {
      state = state.copyWith(
        elapsedSeconds: timer['elapsedSeconds'] as int? ?? 0,
        isOvertime: timer['isOvertime'] as bool? ?? false,
        currentAmountNis: timer['currentAmountNis'] as int? ?? 0,
      );
      if (phase == SessionPhase.active && timer['startTime'] != null) {
        _startTime = DateTime.parse(timer['startTime'] as String);
        _startLocalTimer();
      }
    }

    // Handle summary (for ended phase)
    final summary = data['summary'] as Map<String, dynamic>?;
    if (summary != null) {
      state = state.copyWith(
        actualDurationMin: summary['actualDurationMin'] as int?,
        finalAmountNis: summary['finalAmountNis'] as int?,
        overtimeAmountNis: summary['overtimeAmountNis'] as int?,
        platformFee: summary['platformFee'] as int?,
        netAmountNis: summary['netAmountNis'] as int?,
      );
    }
  }

  SessionPhase _parsePhase(String phase) => switch (phase) {
        'prompt_start' => SessionPhase.promptStart,
        'waiting_start_confirmation' || 'waiting_confirmation' => SessionPhase.waitingStartConfirmation,
        'active' => SessionPhase.active,
        'waiting_end_confirmation' => SessionPhase.waitingEndConfirmation,
        'ended' => SessionPhase.ended,
        _ => SessionPhase.idle,
      };

  /// Confirm session start
  void confirmStart() {
    if (_socket == null || state.bookingId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    _socket!.emit('session:confirm-start', {'bookingId': state.bookingId});
  }

  /// Request session end
  void requestEnd() {
    if (_socket == null || state.bookingId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    _socket!.emit('session:request-end', {'bookingId': state.bookingId});
  }

  /// Confirm session end
  void confirmEnd() {
    if (_socket == null || state.bookingId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    _socket!.emit('session:confirm-end', {'bookingId': state.bookingId});
  }

  /// Start a local timer for smooth UI updates between server ticks
  void _startLocalTimer() {
    _stopLocalTimer();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime == null) return;
      final elapsed = DateTime.now().difference(_startTime!).inSeconds;
      final isOvertime = elapsed > (state.bookedDurationMin * 60);
      state = state.copyWith(
        elapsedSeconds: elapsed,
        isOvertime: isOvertime,
      );
    });
  }

  void _stopLocalTimer() {
    _localTimer?.cancel();
    _localTimer = null;
  }

  /// Disconnect socket
  void disconnect() {
    _stopLocalTimer();
    _socket?.dispose();
    _socket = null;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Provider for session state — scoped per booking
final sessionProvider =
    StateNotifierProvider.autoDispose<SessionNotifier, SessionState>((ref) {
  final notifier = SessionNotifier();
  ref.onDispose(() => notifier.disconnect());
  return notifier;
});
