import 'dart:io' show Platform;

class AppConstants {
  AppConstants._();

  // Android emulator uses 10.0.2.2 to reach host machine,
  // iOS simulator and desktop use localhost directly.
  static final String _host =
      Platform.isAndroid ? '10.0.2.2' : 'localhost';

  static final String apiBaseUrl = 'http://$_host:8080/api';
  static final String socketUrl = 'http://$_host:8080';

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static const int pageSize = 20;

  // Supported languages
  static const List<String> languages = [
    'Hebrew', 'English', 'Arabic', 'Russian', 'French', 'Spanish', 'Amharic',
  ];

  // Nanny skills
  static const List<String> skills = [
    'Infant Care', 'Toddler Care', 'School Age Care',
    'Homework Help', 'Cooking', 'Meal Preparation',
    'Driving', 'Swimming Supervision', 'First Aid',
    'Special Needs Care', 'Arts & Crafts', 'Music',
    'Sports & Physical Activity', 'Educational Play',
    'Bedtime Routines', 'School Pickup', 'Bilingual Care',
  ];

  static const List<int> hourlyRateOptions = [30, 40, 50, 60, 70, 80, 100, 120, 150];
}
