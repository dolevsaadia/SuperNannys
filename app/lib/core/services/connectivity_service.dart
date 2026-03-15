import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import 'app_logger.dart';

/// Lightweight connectivity monitor — pings the API server periodically
/// and tracks online/offline state without requiring extra packages.
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  Timer? _timer;

  ConnectivityNotifier() : super(const ConnectivityState()) {
    _startMonitoring();
  }

  void _startMonitoring() {
    // Check immediately on startup
    _check();
    // Then check every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  Future<void> _check() async {
    try {
      // Quick HEAD-style check — use a GET to root health endpoint
      final resp = await apiClient.dio.get(
        '/nannies',
        queryParameters: {'limit': '1', 'page': '1'},
        options: Options(
          // Short timeout — we just want to know if server is reachable
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          // Don't trigger the retry interceptor for health checks
          extra: {'_retryCount': 99},
        ),
      );
      _setOnline(resp.statusCode == 200);
    } on SocketException {
      _setOnline(false);
    } catch (_) {
      // DioException (timeout etc.) — likely offline
      _setOnline(false);
    }
  }

  void _setOnline(bool online) {
    if (state.isOnline == online) return; // no change
    if (online && !state.isOnline) {
      appLog.info('connectivity', 'online', 'Connection restored');
    } else if (!online && state.isOnline) {
      appLog.warn('connectivity', 'offline', 'Connection lost');
    }
    state = ConnectivityState(isOnline: online);
  }

  /// Force an immediate check (e.g. on app resume)
  void checkNow() => _check();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class ConnectivityState {
  final bool isOnline;
  const ConnectivityState({this.isOnline = true});
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>(
  (ref) => ConnectivityNotifier(),
);
