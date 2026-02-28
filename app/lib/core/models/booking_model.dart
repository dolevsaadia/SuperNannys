class BookingModel {
  final String id;
  final String parentUserId;
  final String nannyUserId;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final String status;
  final int hourlyRateNis;
  final int totalAmountNis;
  final bool isPaid;
  final int childrenCount;
  final List<String> childrenAges;
  final String? address;
  final DateTime createdAt;
  final BookingUser? parent;
  final BookingUser? nanny;
  final BookingReview? review;

  const BookingModel({
    required this.id,
    required this.parentUserId,
    required this.nannyUserId,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.status,
    required this.hourlyRateNis,
    required this.totalAmountNis,
    required this.isPaid,
    required this.childrenCount,
    required this.childrenAges,
    this.address,
    required this.createdAt,
    this.parent,
    this.nanny,
    this.review,
  });

  bool get isRequested => status == 'REQUESTED';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isDeclined => status == 'DECLINED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isCompleted => status == 'COMPLETED';

  double get durationHours =>
      endTime.difference(startTime).inMinutes / 60;

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] as String,
        parentUserId: json['parentUserId'] as String,
        nannyUserId: json['nannyUserId'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        notes: json['notes'] as String?,
        status: json['status'] as String,
        hourlyRateNis: json['hourlyRateNis'] as int,
        totalAmountNis: json['totalAmountNis'] as int,
        isPaid: json['isPaid'] as bool? ?? false,
        childrenCount: json['childrenCount'] as int? ?? 1,
        childrenAges: (json['childrenAges'] as List<dynamic>?)?.cast<String>() ?? [],
        address: json['address'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        parent: json['parent'] != null ? BookingUser.fromJson(json['parent'] as Map<String, dynamic>) : null,
        nanny: json['nanny'] != null ? BookingUser.fromJson(json['nanny'] as Map<String, dynamic>) : null,
        review: json['review'] != null ? BookingReview.fromJson(json['review'] as Map<String, dynamic>) : null,
      );
}

class BookingUser {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? city;

  const BookingUser({required this.id, required this.fullName, this.avatarUrl, this.phone, this.latitude, this.longitude, this.city});

  factory BookingUser.fromJson(Map<String, dynamic> json) {
    final profile = json['nannyProfile'] as Map<String, dynamic>?;
    return BookingUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      latitude: (profile?['latitude'] as num?)?.toDouble(),
      longitude: (profile?['longitude'] as num?)?.toDouble(),
      city: profile?['city'] as String?,
    );
  }
}

class BookingReview {
  final int rating;
  final String? comment;

  const BookingReview({required this.rating, this.comment});

  factory BookingReview.fromJson(Map<String, dynamic> json) => BookingReview(
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
      );
}
