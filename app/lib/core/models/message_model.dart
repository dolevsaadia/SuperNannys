class MessageModel {
  final String id;
  final String bookingId;
  final String fromUserId;
  final String text;
  final bool isRead;
  final DateTime createdAt;
  final MessageSender? from;

  const MessageModel({
    required this.id,
    required this.bookingId,
    required this.fromUserId,
    required this.text,
    required this.isRead,
    required this.createdAt,
    this.from,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        fromUserId: json['fromUserId'] as String,
        text: json['text'] as String,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        from: json['from'] != null ? MessageSender.fromJson(json['from'] as Map<String, dynamic>) : null,
      );
}

class MessageSender {
  final String id;
  final String fullName;
  final String? avatarUrl;

  const MessageSender({required this.id, required this.fullName, this.avatarUrl});

  factory MessageSender.fromJson(Map<String, dynamic> json) => MessageSender(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
      );
}
