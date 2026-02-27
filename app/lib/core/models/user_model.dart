class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role; // PARENT | NANNY | ADMIN
  final bool isVerified;
  final NannyProfileSummary? nannyProfile;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.isVerified = false,
    this.nannyProfile,
  });

  bool get isNanny => role == 'NANNY';
  bool get isParent => role == 'PARENT';
  bool get isAdmin => role == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        role: json['role'] as String,
        isVerified: json['isVerified'] as bool? ?? false,
        nannyProfile: json['nannyProfile'] != null
            ? NannyProfileSummary.fromJson(json['nannyProfile'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'email': email, 'fullName': fullName,
        'phone': phone, 'avatarUrl': avatarUrl, 'role': role,
        'isVerified': isVerified,
      };

  UserModel copyWith({
    String? fullName, String? phone, String? avatarUrl,
    NannyProfileSummary? nannyProfile,
  }) => UserModel(
        id: id, email: email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role, isVerified: isVerified,
        nannyProfile: nannyProfile ?? this.nannyProfile,
      );
}

class NannyProfileSummary {
  final String id;
  final String? headline;
  final int hourlyRateNis;
  final double rating;
  final int reviewsCount;
  final bool isVerified;
  final bool isAvailable;
  final String city;
  final List<String> badges;
  final int completedJobs;
  final int totalEarnings;

  const NannyProfileSummary({
    required this.id,
    this.headline,
    required this.hourlyRateNis,
    required this.rating,
    required this.reviewsCount,
    required this.isVerified,
    required this.isAvailable,
    required this.city,
    required this.badges,
    required this.completedJobs,
    required this.totalEarnings,
  });

  factory NannyProfileSummary.fromJson(Map<String, dynamic> json) => NannyProfileSummary(
        id: json['id'] as String,
        headline: json['headline'] as String?,
        hourlyRateNis: json['hourlyRateNis'] as int? ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewsCount: json['reviewsCount'] as int? ?? 0,
        isVerified: json['isVerified'] as bool? ?? false,
        isAvailable: json['isAvailable'] as bool? ?? true,
        city: json['city'] as String? ?? '',
        badges: (json['badges'] as List<dynamic>?)?.cast<String>() ?? [],
        completedJobs: json['completedJobs'] as int? ?? 0,
        totalEarnings: json['totalEarnings'] as int? ?? 0,
      );
}
