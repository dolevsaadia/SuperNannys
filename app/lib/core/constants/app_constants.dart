import 'dart:io';

class AppConstants {
  AppConstants._();

  static const String _lanHost = '192.168.1.190';

  static String get _host {
    // Use LAN IP for mobile devices so physical phones can reach the backend.
    if (Platform.isAndroid || Platform.isIOS) {
      return _lanHost;
    }

    // Desktop development on the same machine
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return 'localhost';
    }

    return _lanHost;
  }

  static String get apiBaseUrl => 'http://$_host:8080/api';
  static String get socketUrl => 'http://$_host:8080';

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static const int pageSize = 20;

  static const List<String> languages = [
    'Hebrew',
    'English',
    'Arabic',
    'Russian',
    'French',
    'Spanish',
    'Amharic',
  ];

  static const List<String> skills = [
    'Infant Care',
    'Toddler Care',
    'School Age Care',
    'Homework Help',
    'Cooking',
    'Meal Preparation',
    'Driving',
    'Swimming Supervision',
    'First Aid',
    'Special Needs Care',
    'Arts & Crafts',
    'Music',
    'Sports & Physical Activity',
    'Educational Play',
    'Bedtime Routines',
    'School Pickup',
    'Bilingual Care',
  ];

  static const List<int> hourlyRateOptions = [
    30,
    40,
    50,
    60,
    70,
    80,
    100,
    120,
    150,
  ];
}
