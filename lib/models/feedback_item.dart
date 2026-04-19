class FeedbackItem {
  final String id;
  final String userId;
  final String type;
  final String subject;
  final String message;
  final String status;
  final String adminNote;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeedbackItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.subject,
    required this.message,
    required this.status,
    required this.adminNote,
    required this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackItem.fromMap(Map<String, dynamic> map) {
    String parsedUserId = '';
    final rawUserId = map['userId'];
    if (rawUserId is Map<String, dynamic>) {
      parsedUserId = rawUserId['_id']?.toString() ?? '';
    } else {
      parsedUserId = rawUserId?.toString() ?? '';
    }

    return FeedbackItem(
      id: map['_id']?.toString() ?? '',
      userId: parsedUserId,
      type: map['type']?.toString() ?? 'other',
      subject: map['subject']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      status: map['status']?.toString() ?? 'open',
      adminNote: map['adminNote']?.toString() ?? '',
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.tryParse(map['resolvedAt'].toString())
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'].toString())
          : DateTime.now(),
    );
  }
}
