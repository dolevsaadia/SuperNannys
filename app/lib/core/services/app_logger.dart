import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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
/// in a ring buffer and errors are persisted to disk for crash analysis.
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

  /// Crash log file for persistent error storage
  File? _crashLogFile;
  bool _crashLogReady = false;

  /// Initialize persistent crash log storage.
  /// Call once during app startup after WidgetsFlutterBinding.ensureInitialized().
  Future<void> initPersistentStorage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
      _crashLogFile = File('${logDir.path}/crash_log.jsonl');

      // Rotate: keep last 500KB max (trim older entries)
      if (_crashLogFile!.existsSync()) {
        final size = _crashLogFile!.lengthSync();
        if (size > 500 * 1024) {
          // Keep only last 200KB
          final content = _crashLogFile!.readAsStringSync();
          final keepFrom = content.length - (200 * 1024);
          final trimmed = content.substring(keepFrom > 0 ? keepFrom : 0);
          // Find first complete line
          final firstNewline = trimmed.indexOf('\n');
          _crashLogFile!.writeAsStringSync(
            firstNewline >= 0 ? trimmed.substring(firstNewline + 1) : trimmed,
          );
        }
      }

      _crashLogReady = true;
    } catch (e) {
      // Can't persist logs — fallback to in-memory only
      debugPrint('[AppLogger] Failed to init persistent storage: $e');
    }
  }

  /// Set after login for automatic user correlation
  void setUserId(String? userId) => _userId = userId;

  /// Update on every screen navigation
  void setCurrentScreen(String screen) {
    _currentScreen = screen;
    debug('navigation', 'screen_enter', 'Entered $screen', screen: screen);
  }

  /// Get recent logs (for crash reports or diagnostics)
  List<LogEntry> get recentLogs => List.unmodifiable(_recentLogs);

  /// Get crash log file contents for sharing/debugging
  Future<String> getCrashLogContents() async {
    if (_crashLogFile != null && _crashLogFile!.existsSync()) {
      return _crashLogFile!.readAsString();
    }
    return '';
  }

  /// Get crash log file path (for attaching to bug reports)
  String? get crashLogPath => _crashLogFile?.path;

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

    // Persist errors and warnings to disk (fire-and-forget)
    if (_crashLogReady && (level == LogLevel.error || level == LogLevel.warn)) {
      _persistEntry(entry);
    }
  }

  /// Write a log entry to the crash log file (JSONL format).
  void _persistEntry(LogEntry entry) {
    try {
      final line = '${jsonEncode(entry.toJson())}\n';
      _crashLogFile?.writeAsStringSync(line, mode: FileMode.append, flush: false);
    } catch (_) {
      // Silently fail — don't crash the app over logging
    }
  }
}

/// Shorthand global accessor
final appLog = AppLogger.instance;
