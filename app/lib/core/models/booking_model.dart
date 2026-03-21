import '../utils/image_utils.dart';

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

  // ── Recurring fields ─────────────────────────────────
  final String? recurringBookingId;
  final bool isRecurring;
  final DateTime? occurrenceDate;

  final DateTime createdAt;
  final BookingUser? parent;
  final BookingUser? nanny;
  final BookingReview? review;

  // ── Live session fields ────────────────────────────────
  final bool parentConfirmedStart;
  final bool nannyConfirmedStart;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final bool parentConfirmedEnd;
  final bool nannyConfirmedEnd;
  final int? actualDurationMin;
  final int? finalAmountNis;
  final int overtimeAmountNis;

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
    this.recurringBookingId,
    this.isRecurring = false,
    this.occurrenceDate,
    required this.createdAt,
    this.parent,
    this.nanny,
    this.review,
    this.parentConfirmedStart = false,
    this.nannyConfirmedStart = false,
    this.actualStartTime,
    this.actualEndTime,
    this.parentConfirmedEnd = false,
    this.nannyConfirmedEnd = false,
    this.actualDurationMin,
    this.finalAmountNis,
    this.overtimeAmountNis = 0,
  });

  bool get isRequested => status == 'REQUESTED';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isDeclined => status == 'DECLINED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isCompleted => status == 'COMPLETED';

  double get durationHours =>
      endTime.difference(startTime).inMinutes / 60;

  /// Booked duration in minutes (scheduled)
  int get bookedDurationMin =>
      endTime.difference(startTime).inMinutes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentUserId': parentUserId,
        'nannyUserId': nannyUserId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'notes': notes,
        'status': status,
        'hourlyRateNis': hourlyRateNis,
        'totalAmountNis': totalAmountNis,
        'isPaid': isPaid,
        'childrenCount': childrenCount,
        'childrenAges': childrenAges,
        'address': address,
        'recurringBookingId': recurringBookingId,
        'isRecurring': isRecurring,
        'occurrenceDate': occurrenceDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'parent': parent?.toJson(),
        'nanny': nanny?.toJson(),
        'review': review?.toJson(),
        'parentConfirmedStart': parentConfirmedStart,
        'nannyConfirmedStart': nannyConfirmedStart,
        'actualStartTime': actualStartTime?.toIso8601String(),
        'actualEndTime': actualEndTime?.toIso8601String(),
        'parentConfirmedEnd': parentConfirmedEnd,
        'nannyConfirmedEnd': nannyConfirmedEnd,
        'actualDurationMin': actualDurationMin,
        'finalAmountNis': finalAmountNis,
        'overtimeAmountNis': overtimeAmountNis,
      };

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
        recurringBookingId: json['recurringBookingId'] as String?,
        isRecurring: json['isRecurring'] as bool? ?? false,
        occurrenceDate: json['occurrenceDate'] != null ? DateTime.parse(json['occurrenceDate'] as String) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        parent: json['parent'] != null ? BookingUser.fromJson(json['parent'] as Map<String, dynamic>) : null,
        nanny: json['nanny'] != null ? BookingUser.fromJson(json['nanny'] as Map<String, dynamic>) : null,
        review: json['review'] != null ? BookingReview.fromJson(json['review'] as Map<String, dynamic>) : null,
        parentConfirmedStart: json['parentConfirmedStart'] as bool? ?? false,
        nannyConfirmedStart: json['nannyConfirmedStart'] as bool? ?? false,
        actualStartTime: json['actualStartTime'] != null ? DateTime.parse(json['actualStartTime'] as String) : null,
        actualEndTime: json['actualEndTime'] != null ? DateTime.parse(json['actualEndTime'] as String) : null,
        parentConfirmedEnd: json['parentConfirmedEnd'] as bool? ?? false,
        nannyConfirmedEnd: json['nannyConfirmedEnd'] as bool? ?? false,
        actualDurationMin: json['actualDurationMin'] as int?,
        finalAmountNis: json['finalAmountNis'] as int?,
        overtimeAmountNis: json['overtimeAmountNis'] as int? ?? 0,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'phone': phone,
        'nannyProfile': {
          'latitude': latitude,
          'longitude': longitude,
          'city': city,
        },
      };

  factory BookingUser.fromJson(Map<String, dynamic> json) {
    final profile = json['nannyProfile'] as Map<String, dynamic>?;
    return BookingUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: ImageUtils.resolveAvatarUrl(json['avatarUrl'] as String?),
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

  Map<String, dynamic> toJson() => {
        'rating': rating,
        'comment': comment,
      };

  factory BookingReview.fromJson(Map<String, dynamic> json) => BookingReview(
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
      );
}
