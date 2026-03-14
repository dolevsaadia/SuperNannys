import 'package:flutter/foundation.dart';

/// Severity levels for structured logging.
enum LogLevel { debug, info, warn, error }

/// A structured log entry with context fields for traceability.
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String module;
  final String action;
  final String message;
  final String? screen;
  final String? userId;
  final String? requestId;
  final String? endpoint;
  final String? errorCode;
  final Map<String, dynamic>? extra;

  LogEntry({
    required this.level,
    required this.module,
    required this.action,
    required this.message,
    this.screen,
    this.userId,
    this.requestId,
    this.endpoint,
    this.errorCode,
    this.extra,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
    'ts': timestamp.toIso8601String(),
    'level': level.name,
    'module': module,
    'action': action,
    'msg': message,
    if (screen != null) 'screen': screen,
    if (userId != null) 'userId': userId,
    if (requestId != null) 'requestId': requestId,
    if (endpoint != null) 'endpoint': endpoint,
    if (errorCode != null) 'errorCode': errorCode,
    if (extra != null) ...extra!,
  };

  @override
  String toString() {
    final buf = StringBuffer()
      ..write('[${level.name.toUpperCase()}] ')
      ..write('$module.$action: $message');
    if (screen != null) buf.write(' | screen=$screen');
    if (endpoint != null) buf.write(' | endpoint=$endpoint');
    if (errorCode != null) buf.write(' | errorCode=$errorCode');
    if (extra != null && extra!.isNotEmpty) buf.write(' | $extra');
    return buf.toString();
  }
}

/// Global structured logger for the Flutter app.
///
/// Provides structured logging with consistent fields for traceability.
/// In debug mode, logs go to console. In production, logs are stored
/// in a ring buffer and can be flushed to a remote service.
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  /// Current user ID — set after login for correlation
  String? _userId;

  /// Current screen name — updated on navigation
  String? _currentScreen;

  /// Ring buffer of recent logs for crash reports (keeps last 200)
  final List<LogEntry> _recentLogs = [];
  static const _maxRecentLogs = 200;

  /// Set after login for automatic user correlation
  void setUserId(String? userId) => _userId = userId;

  /// Update on every screen navigation
  void setCurrentScreen(String screen) {
    _currentScreen = screen;
    debug('navigation', 'screen_enter', 'Entered $screen', screen: screen);
  }

  /// Get recent logs (for crash reports or diagnostics)
  List<LogEntry> get recentLogs => List.unmodifiable(_recentLogs);

  // ── Convenience methods ──────────────────────────────────

  void debug(String module, String action, String message, {
    String? screen, String? endpoint, String? requestId,
    String? errorCode, Map<String, dynamic>? extra,
  }) => _log(LogLevel.debug, module, action, message,
      screen: screen, endpoint: endpoint, requestId: requestId,
      errorCode: errorCode, extra: extra);

  void info(String module, String action, String message, {
    String? screen, String? endpoint, String? requestId,
    String? errorCode, Map<String, dynamic>? extra,
  }) => _log(LogLevel.info, module, action, message,
      screen: screen, endpoint: endpoint, requestId: requestId,
      errorCode: errorCode, extra: extra);

  void warn(String module, String action, String message, {
    String? screen, String? endpoint, String? requestId,
    String? errorCode, Map<String, dynamic>? extra,
  }) => _log(LogLevel.warn, module, action, message,
      screen: screen, endpoint: endpoint, requestId: requestId,
      errorCode: errorCode, extra: extra);

  void error(String module, String action, String message, {
    String? screen, String? endpoint, String? requestId,
    String? errorCode, Map<String, dynamic>? extra,
    Object? error, StackTrace? stackTrace,
  }) {
    final mergedExtra = <String, dynamic>{...?extra};
    if (error != null) mergedExtra['error'] = error.toString();
    if (stackTrace != null) mergedExtra['stackTrace'] = stackTrace.toString().split('\n').take(10).join('\n');
    _log(LogLevel.error, module, action, message,
        screen: screen, endpoint: endpoint, requestId: requestId,
        errorCode: errorCode, extra: mergedExtra.isEmpty ? null : mergedExtra);
  }

  // ── Core logging ─────────────────────────────────────────

  void _log(LogLevel level, String module, String action, String message, {
    String? screen, String? endpoint, String? requestId,
    String? errorCode, Map<String, dynamic>? extra,
  }) {
    final entry = LogEntry(
      level: level,
      module: module,
      action: action,
      message: message,
      screen: screen ?? _currentScreen,
      userId: _userId,
      requestId: requestId,
      endpoint: endpoint,
      errorCode: errorCode,
      extra: extra,
    );

    // Ring buffer
    _recentLogs.add(entry);
    if (_recentLogs.length > _maxRecentLogs) {
      _recentLogs.removeAt(0);
    }

    // Console output in debug mode
    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }
}

/// Shorthand global accessor
final appLog = AppLogger.instance;
