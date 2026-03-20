class RecurringBookingModel {
  final String id;
  final String parentUserId;
  final String nannyUserId;
  final List<int> daysOfWeek;
  final String startTime;
  final String endTime;
  final DateTime startDate;
  final DateTime? endDate;
  final int hourlyRateNis;
  final int childrenCount;
  final List<String> childrenAges;
  final String? address;
  final String? notes;
  final String status;
  final DateTime? lastGeneratedAt;
  final DateTime createdAt;
  final RecurringBookingUser? parent;
  final RecurringBookingUser? nanny;
  final int bookingsCount;

  const RecurringBookingModel({
    required this.id,
    required this.parentUserId,
    required this.nannyUserId,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    this.endDate,
    required this.hourlyRateNis,
    required this.childrenCount,
    required this.childrenAges,
    this.address,
    this.notes,
    required this.status,
    this.lastGeneratedAt,
    required this.createdAt,
    this.parent,
    this.nanny,
    this.bookingsCount = 0,
  });

  bool get isPending => status == 'PENDING';
  bool get isActive => status == 'ACTIVE';
  bool get isPaused => status == 'PAUSED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isEnded => status == 'ENDED';

  /// Weekly hours = hours per session * number of days
  double get weeklyHours {
    final parts1 = startTime.split(':');
    final parts2 = endTime.split(':');
    final start = int.parse(parts1[0]) + int.parse(parts1[1]) / 60;
    final end = int.parse(parts2[0]) + int.parse(parts2[1]) / 60;
    return (end - start) * daysOfWeek.length;
  }

  /// Estimated weekly cost
  int get weeklyEstimatedCostNis => (weeklyHours * hourlyRateNis).round();

  /// Human-readable days
  String get daysLabel {
    const names = ['א\'', 'ב\'', 'ג\'', 'ד\'', 'ה\'', 'ו\'', 'ש\''];
    final sorted = List<int>.from(daysOfWeek)..sort();
    return sorted.map((d) => names[d]).join(', ');
  }

  /// Human-readable schedule
  String get scheduleLabel => '$daysLabel  $startTime–$endTime';

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentUserId': parentUserId,
        'nannyUserId': nannyUserId,
        'daysOfWeek': daysOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'hourlyRateNis': hourlyRateNis,
        'childrenCount': childrenCount,
        'childrenAges': childrenAges,
        'address': address,
        'notes': notes,
        'status': status,
        'lastGeneratedAt': lastGeneratedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'parent': parent?.toJson(),
        'nanny': nanny?.toJson(),
        '_count': {'bookings': bookingsCount},
      };

  factory RecurringBookingModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    return RecurringBookingModel(
      id: json['id'] as String,
      parentUserId: json['parentUserId'] as String,
      nannyUserId: json['nannyUserId'] as String,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>).cast<int>(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      hourlyRateNis: json['hourlyRateNis'] as int,
      childrenCount: json['childrenCount'] as int? ?? 1,
      childrenAges: (json['childrenAges'] as List<dynamic>?)?.cast<String>() ?? [],
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      lastGeneratedAt: json['lastGeneratedAt'] != null ? DateTime.parse(json['lastGeneratedAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      parent: json['parent'] != null ? RecurringBookingUser.fromJson(json['parent'] as Map<String, dynamic>) : null,
      nanny: json['nanny'] != null ? RecurringBookingUser.fromJson(json['nanny'] as Map<String, dynamic>) : null,
      bookingsCount: count?['bookings'] as int? ?? 0,
    );
  }
}

class RecurringBookingUser {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;

  const RecurringBookingUser({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'phone': phone,
      };

  factory RecurringBookingUser.fromJson(Map<String, dynamic> json) => RecurringBookingUser(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        phone: json['phone'] as String?,
      );
}
