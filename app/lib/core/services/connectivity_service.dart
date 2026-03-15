import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import 'app_logger.dart';

/// ──────────────────────────────────────────────────────────────
/// CONNECTIVITY SERVICE — bullet-proof internet monitoring
/// ──────────────────────────────────────────────────────────────
///
/// **Why the old approach broke:**
/// The previous service pinged `/nannies` (authenticated endpoint) every 10s.
/// When the auth token expired → 401 → catch → "No internet" — even though
/// the network was perfectly fine. A single failure flipped the banner.
///
/// **New approach (3 layers of defence):**
///
/// 1. **Separate Dio instance** — no auth interceptors, no retry, just a raw
///    HTTP call to `/health` (public, no auth required).
///
/// 2. **Consecutive failures** — must fail 3 times in a row (30s) before
///    showing the offline banner. One success resets the counter instantly.
///
/// 3. **Interceptor-based signal** — the main ApiClient calls
///    `reportApiResult()` on every response/error. If any real API call
///    gets an HTTP response (even 401/500), it means the network works →
///    reset to online immediately. Only SocketException / timeout / DNS
///    failures count as network errors.
///
/// This eliminates all false positives: token expiry, server 500s,
/// rate-limiting, and transient hiccups no longer trigger the banner.
/// ──────────────────────────────────────────────────────────────

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  Timer? _timer;

  /// Separate Dio — no auth, no retry, no logging noise.
  late final Dio _healthDio;

  /// How many consecutive health-check failures we've seen.
  int _consecutiveFailures = 0;

  /// How many consecutive failures before we show the offline banner.
  static const _failureThreshold = 3;

  /// Health check interval.
  static const _checkInterval = Duration(seconds: 30);

  /// Health endpoint timeout — short so it doesn't block.
  static const _healthTimeout = Duration(seconds: 6);

  ConnectivityNotifier() : super(const ConnectivityState()) {
    _initHealthDio();
    _startMonitoring();
  }

  void _initHealthDio() {
    // Base URL is the server root (not /api) because /health lives at root.
    // AppConstants.apiBaseUrl = "https://api.supernanny.net/api"
    // We strip "/api" to get the server root.
    String serverRoot = AppConstants.apiBaseUrl;
    if (serverRoot.endsWith('/api')) {
      serverRoot = serverRoot.substring(0, serverRoot.length - 4);
    }

    _healthDio = Dio(BaseOptions(
      baseUrl: serverRoot,
      connectTimeout: _healthTimeout,
      receiveTimeout: _healthTimeout,
      sendTimeout: _healthTimeout,
      // No auth headers, no extra interceptors.
    ));
  }

  void _startMonitoring() {
    _check();
    _timer = Timer.periodic(_checkInterval, (_) => _check());
  }

  Future<void> _check() async {
    try {
      final resp = await _healthDio.get('/health');
      // ANY HTTP response from the server = network is working.
      if (resp.statusCode != null) {
        _onSuccess();
      } else {
        _onFailure('health: null status code');
      }
    } on DioException catch (e) {
      // If the server returned an HTTP response (even 4xx/5xx), the network
      // is working — the server is just unhappy about something.
      if (e.response != null) {
        _onSuccess();
        return;
      }
      // Genuine network failures:
      _onFailure('health: ${e.type.name}');
    } on SocketException {
      _onFailure('health: SocketException');
    } catch (e) {
      _onFailure('health: $e');
    }
  }

  /// Called when a health check (or any API call) proves the network works.
  void _onSuccess() {
    _consecutiveFailures = 0;
    if (!state.isOnline) {
      appLog.info('connectivity', 'online', 'Connection restored');
      state = const ConnectivityState(isOnline: true);
    }
  }

  /// Called when a health check (or API call) encounters a real network error.
  void _onFailure(String reason) {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _failureThreshold && state.isOnline) {
      appLog.warn('connectivity', 'offline',
          'Connection lost after $_consecutiveFailures consecutive failures ($reason)');
      state = const ConnectivityState(isOnline: false);
    }
  }

  /// Called by [ApiClient] on every API response/error to provide an
  /// additional real-time signal beyond the periodic health checks.
  ///
  /// **Key insight:** If the server returned ANY HTTP status code (even
  /// 401, 403, 500), the network layer is working. Only genuine network
  /// errors (timeout, DNS, socket closed) indicate connectivity loss.
  void reportApiResult({required bool networkReachable}) {
    if (networkReachable) {
      _onSuccess();
    } else {
      _onFailure('apiClient: network error');
    }
  }

  /// Force an immediate check (e.g. on app resume).
  void checkNow() => _check();

  @override
  void dispose() {
    _timer?.cancel();
    _healthDio.close();
    super.dispose();
  }
}

class ConnectivityState {
  final bool isOnline;
  const ConnectivityState({this.isOnline = true});
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>(
  (ref) {
    final notifier = ConnectivityNotifier();
    // Wire the notifier into ApiClient so every API call
    // can report its network result in real-time.
    apiClient.connectivityNotifier = notifier;
    ref.onDispose(() {
      // Don't hold a stale reference after disposal.
      if (apiClient.connectivityNotifier == notifier) {
        apiClient.connectivityNotifier = null;
      }
    });
    return notifier;
  },
);
