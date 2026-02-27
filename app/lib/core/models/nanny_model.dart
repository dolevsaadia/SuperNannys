class NannyModel {
  final String id;
  final String userId;
  final String headline;
  final String bio;
  final int hourlyRateNis;
  final int yearsExperience;
  final List<String> languages;
  final List<String> skills;
  final List<String> badges;
  final bool isVerified;
  final bool isAvailable;
  final double? latitude;
  final double? longitude;
  final String city;
  final String address;
  final double rating;
  final int reviewsCount;
  final int completedJobs;
  final double? distanceKm;
  final NannyUser? user;
  final List<AvailabilitySlot> availability;

  const NannyModel({
    required this.id,
    required this.userId,
    required this.headline,
    required this.bio,
    required this.hourlyRateNis,
    required this.yearsExperience,
    required this.languages,
    required this.skills,
    required this.badges,
    required this.isVerified,
    required this.isAvailable,
    this.latitude,
    this.longitude,
    required this.city,
    required this.address,
    required this.rating,
    required this.reviewsCount,
    required this.completedJobs,
    this.distanceKm,
    this.user,
    required this.availability,
  });

  factory NannyModel.fromJson(Map<String, dynamic> json) => NannyModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        headline: json['headline'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        hourlyRateNis: json['hourlyRateNis'] as int? ?? 50,
        yearsExperience: json['yearsExperience'] as int? ?? 0,
        languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
        skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
        badges: (json['badges'] as List<dynamic>?)?.cast<String>() ?? [],
        isVerified: json['isVerified'] as bool? ?? false,
        isAvailable: json['isAvailable'] as bool? ?? true,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        city: json['city'] as String? ?? '',
        address: json['address'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewsCount: json['reviewsCount'] as int? ?? 0,
        completedJobs: json['completedJobs'] as int? ?? 0,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        user: json['user'] != null ? NannyUser.fromJson(json['user'] as Map<String, dynamic>) : null,
        availability: (json['availability'] as List<dynamic>?)
                ?.map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class NannyUser {
  final String id;
  final String fullName;
  final String? avatarUrl;

  const NannyUser({required this.id, required this.fullName, this.avatarUrl});

  factory NannyUser.fromJson(Map<String, dynamic> json) => NannyUser(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

class AvailabilitySlot {
  final int dayOfWeek; // 0=Sun
  final String fromTime;
  final String toTime;
  final bool isAvailable;

  const AvailabilitySlot({
    required this.dayOfWeek,
    required this.fromTime,
    required this.toTime,
    required this.isAvailable,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) => AvailabilitySlot(
        dayOfWeek: json['dayOfWeek'] as int,
        fromTime: json['fromTime'] as String,
        toTime: json['toTime'] as String,
        isAvailable: json['isAvailable'] as bool? ?? true,
      );

  static const List<String> dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const List<String> dayNamesHe = ['א\'', 'ב\'', 'ג\'', 'ד\'', 'ה\'', 'ו\'', 'ש\''];
  String get dayName => dayNames[dayOfWeek];
}
