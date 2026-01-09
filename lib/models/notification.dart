import 'dart:convert';

class AppNotification {
  final String id;
  final String recipient;
  final String type;
  final String title;
  final String message;
  final NotificationData data;
  final bool isRead;
  final DeliveryChannels deliveryChannels;
  final DateTime? readAt;
  final String priority;
  final String? actionUrl;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppNotification({
    required this.id,
    required this.recipient,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    required this.deliveryChannels,
    this.readAt,
    required this.priority,
    this.actionUrl,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'recipient': recipient,
      'type': type,
      'title': title,
      'message': message,
      'data': data.toMap(),
      'isRead': isRead,
      'deliveryChannels': deliveryChannels.toMap(),
      'readAt': readAt?.toIso8601String(),
      'priority': priority,
      'actionUrl': actionUrl,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('AppNotification.fromMap: map cannot be null');
    }

    return AppNotification(
      id: map['_id']?.toString() ?? '',
      recipient: map['recipient']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      data: NotificationData.fromMap(map['data'] ?? {}),
      isRead: map['isRead'] ?? false,
      deliveryChannels: DeliveryChannels.fromMap(map['deliveryChannels'] ?? {}),
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt']) : null,
      priority: map['priority']?.toString() ?? 'medium',
      actionUrl: map['actionUrl']?.toString(),
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppNotification.fromJson(String source) =>
      AppNotification.fromMap(json.decode(source));

  AppNotification copyWith({
    String? id,
    String? recipient,
    String? type,
    String? title,
    String? message,
    NotificationData? data,
    bool? isRead,
    DeliveryChannels? deliveryChannels,
    DateTime? readAt,
    String? priority,
    String? actionUrl,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      recipient: recipient ?? this.recipient,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      deliveryChannels: deliveryChannels ?? this.deliveryChannels,
      readAt: readAt ?? this.readAt,
      priority: priority ?? this.priority,
      actionUrl: actionUrl ?? this.actionUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, type: $type, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  // Utility getters
  String get typeDisplayName {
    switch (type) {
      case 'project_invitation':
        return 'Lời mời dự án';
      case 'task_assigned':
        return 'Task được giao';
      case 'task_deadline_warning':
        return 'Task sắp hết hạn';
      case 'project_deadline_warning':
        return 'Dự án sắp hết hạn';
      case 'task_completed':
        return 'Task hoàn thành';
      case 'project_completed':
        return 'Dự án hoàn thành';
      case 'member_joined':
        return 'Thành viên mới';
      case 'system':
        return 'Hệ thống';
      default:
        return 'Thông báo';
    }
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isUrgent => priority == 'urgent' || priority == 'high';
}

class NotificationData {
  final String? projectId;
  final String? projectTitle;
  final String? taskId;
  final String? taskTitle;
  final String? invitationId;
  final String? fromUserId;
  final String? fromUserName;
  final Map<String, dynamic>? extra;

  // Populated fields
  final NotificationUser? fromUser;
  final NotificationProject? project;
  final NotificationTask? task;

  NotificationData({
    this.projectId,
    this.projectTitle,
    this.taskId,
    this.taskTitle,
    this.invitationId,
    this.fromUserId,
    this.fromUserName,
    this.extra,
    this.fromUser,
    this.project,
    this.task,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'projectTitle': projectTitle,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'invitationId': invitationId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'extra': extra,
    };
  }

  factory NotificationData.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return NotificationData();
    }

    return NotificationData(
      projectId: map['projectId'] is String
          ? map['projectId']
          : (map['projectId'] is Map ? map['projectId']['_id']?.toString() : null),
      projectTitle: map['projectTitle']?.toString(),
      taskId: map['taskId'] is String
          ? map['taskId']
          : (map['taskId'] is Map ? map['taskId']['_id']?.toString() : null),
      taskTitle: map['taskTitle']?.toString(),
      invitationId: map['invitationId']?.toString(),
      fromUserId: map['fromUserId'] is String
          ? map['fromUserId']
          : (map['fromUserId'] is Map ? map['fromUserId']['_id']?.toString() : null),
      fromUserName: map['fromUserName']?.toString(),
      extra: map['extra'] is Map ? Map<String, dynamic>.from(map['extra']) : null,
      fromUser: map['fromUserId'] is Map<String, dynamic>
          ? NotificationUser.fromMap(map['fromUserId'])
          : null,
      project: map['projectId'] is Map<String, dynamic>
          ? NotificationProject.fromMap(map['projectId'])
          : null,
      task: map['taskId'] is Map<String, dynamic>
          ? NotificationTask.fromMap(map['taskId'])
          : null,
    );
  }
}

class DeliveryChannels {
  final bool inApp;
  final bool push;
  final bool email;

  DeliveryChannels({
    required this.inApp,
    required this.push,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'inApp': inApp,
      'push': push,
      'email': email,
    };
  }

  factory DeliveryChannels.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return DeliveryChannels(inApp: true, push: false, email: false);
    }

    return DeliveryChannels(
      inApp: map['inApp'] ?? true,
      push: map['push'] ?? false,
      email: map['email'] ?? false,
    );
  }
}

class NotificationUser {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? avatarColor;

  NotificationUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.avatarColor,
  });

  factory NotificationUser.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('NotificationUser.fromMap: map cannot be null');
    }

    return NotificationUser(
      id: map['_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      avatar: map['avatar']?.toString(),
      avatarColor: map['avatarColor']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'avatarColor': avatarColor,
    };
  }
}

class NotificationProject {
  final String id;
  final String title;

  NotificationProject({
    required this.id,
    required this.title,
  });

  factory NotificationProject.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('NotificationProject.fromMap: map cannot be null');
    }

    return NotificationProject(
      id: map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
    };
  }
}

class NotificationTask {
  final String id;
  final String title;

  NotificationTask({
    required this.id,
    required this.title,
  });

  factory NotificationTask.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('NotificationTask.fromMap: map cannot be null');
    }

    return NotificationTask(
      id: map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
    };
  }
}

// Notification Settings Model
class NotificationSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final NotificationPreferences preferences;

  NotificationSettings({
    required this.pushNotifications,
    required this.emailNotifications,
    required this.preferences,
  });

  Map<String, dynamic> toMap() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'preferences': preferences.toMap(),
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return NotificationSettings(
        pushNotifications: true,
        emailNotifications: true,
        preferences: NotificationPreferences(),
      );
    }

    return NotificationSettings(
      pushNotifications: map['pushNotifications'] ?? true,
      emailNotifications: map['emailNotifications'] ?? true,
      preferences: NotificationPreferences.fromMap(map['preferences']),
    );
  }

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    NotificationPreferences? preferences,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      preferences: preferences ?? this.preferences,
    );
  }
}

class NotificationPreferences {
  final bool projectDeadlineWarnings;
  final bool taskDeadlineWarnings;
  final bool taskAssignments;
  final bool projectInvitations;

  NotificationPreferences({
    this.projectDeadlineWarnings = true,
    this.taskDeadlineWarnings = true,
    this.taskAssignments = true,
    this.projectInvitations = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectDeadlineWarnings': projectDeadlineWarnings,
      'taskDeadlineWarnings': taskDeadlineWarnings,
      'taskAssignments': taskAssignments,
      'projectInvitations': projectInvitations,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return NotificationPreferences();
    }

    return NotificationPreferences(
      projectDeadlineWarnings: map['projectDeadlineWarnings'] ?? true,
      taskDeadlineWarnings: map['taskDeadlineWarnings'] ?? true,
      taskAssignments: map['taskAssignments'] ?? true,
      projectInvitations: map['projectInvitations'] ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? projectDeadlineWarnings,
    bool? taskDeadlineWarnings,
    bool? taskAssignments,
    bool? projectInvitations,
  }) {
    return NotificationPreferences(
      projectDeadlineWarnings:
          projectDeadlineWarnings ?? this.projectDeadlineWarnings,
      taskDeadlineWarnings: taskDeadlineWarnings ?? this.taskDeadlineWarnings,
      taskAssignments: taskAssignments ?? this.taskAssignments,
      projectInvitations: projectInvitations ?? this.projectInvitations,
    );
  }
}

