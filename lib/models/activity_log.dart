/// Model đại diện cho một Activity Log entry
class ActivityLog {
  final String id;
  final String projectId;
  final String? taskId;
  final Map<String, dynamic> actor;
  final Map<String, dynamic>? targetUser;
  final String action;
  final String? field;
  final dynamic oldValue;
  final dynamic newValue;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.projectId,
    this.taskId,
    required this.actor,
    this.targetUser,
    required this.action,
    this.field,
    this.oldValue,
    this.newValue,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['_id'] ?? '',
      projectId: _extractId(map['projectId']),
      taskId: map['taskId'] != null ? _extractId(map['taskId']) : null,
      actor: _extractUserMap(map['actor']),
      targetUser: map['targetUser'] != null
          ? _extractUserMap(map['targetUser'])
          : null,
      action: map['action'] ?? '',
      field: map['field'],
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Extract ID từ field có thể là String hoặc Map (populated)
  static String _extractId(dynamic value) {
    if (value is String) return value;
    if (value is Map) return value['_id']?.toString() ?? '';
    return '';
  }

  /// Extract user map từ populated field
  static Map<String, dynamic> _extractUserMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return {
        'id': value['_id']?.toString() ?? '',
        'name': value['name'] ?? 'Unknown',
        'email': value['email'] ?? '',
        'avatar': value['avatar'] ?? '',
        'avatarColor': value['avatarColor'] ?? '#2196F3',
      };
    }
    return {
      'id': value?.toString() ?? '',
      'name': 'Unknown',
      'email': '',
      'avatar': '',
      'avatarColor': '#2196F3',
    };
  }

  // Helper getters
  String get actorName => actor['name'] ?? 'Unknown';
  String get actorAvatar => actor['avatar'] ?? '';
  String get actorAvatarColor => actor['avatarColor'] ?? '#2196F3';
  String get actorId => actor['id'] ?? '';

  String? get targetUserName => targetUser?['name'];
  String? get targetUserAvatar => targetUser?['avatar'];
  String? get targetUserAvatarColor => targetUser?['avatarColor'];
}
