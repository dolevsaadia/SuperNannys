class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'https://api.supernanny.net/api';
  static const String socketUrl = 'https://api.supernanny.net';

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String googleServerClientId = '';

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
