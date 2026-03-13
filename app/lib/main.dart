import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

/// Global navigator key for overlay services (floating bubble etc.)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Catch ALL errors (sync + async) so no unhandled exception can crash
  // the iOS isolate and prevent the app from ever relaunching.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch Flutter framework errors (layout, rendering, etc.)
    FlutterError.onError = (details) {
      FlutterError.presentError(details); // logs to console
    };

    // Catch platform errors (native plugin crashes surfaced to Dart)
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformDispatcher error: $error');
      return true; // handled — don't crash
    };

    // On iOS, changing KeychainAccessibility can cause old keychain entries to
    // hang on read (the Future never completes). On the first launch after an
    // update we wipe the secure storage so fresh entries use the new policy.
    await _migrateSecureStorageIfNeeded();

    // Initialize API client
    apiClient.init();

    // Initialize notifications — wrapped in try-catch so a permission dialog
    // or plugin error doesn't prevent the app from launching.
    try {
      await NotificationService.instance.init().timeout(const Duration(seconds: 5));
    } catch (_) {}

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    runApp(const ProviderScope(child: SuperNannyApp()));
  }, (error, stack) {
    // Last-resort error handler — prevent isolate crash
    debugPrint('Uncaught error: $error');
  });
}

/// Wipe legacy keychain entries that were written with the default iOS
/// accessibility (whenUnlocked). Reading those entries with
/// [KeychainAccessibility.first_unlock] can deadlock forever on iOS,
/// preventing the app from ever launching again.
///
/// This runs once per install/update — detected via a SharedPreferences flag.
Future<void> _migrateSecureStorageIfNeeded() async {
  const migrationKey = 'keychain_migrated_v2';
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(migrationKey) == true) return; // already migrated

    // Delete ALL keychain entries (with a timeout so it can't hang either)
    const storage = FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.deleteAll().timeout(const Duration(seconds: 3));

    await prefs.setBool(migrationKey, true);
  } catch (_) {
    // If anything fails, the app will just show the login screen.
    // Mark as migrated so we don't retry every launch.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(migrationKey, true);
    } catch (_) {}
  }
}

class SuperNannyApp extends ConsumerWidget {
  const SuperNannyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SuperNanny',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
