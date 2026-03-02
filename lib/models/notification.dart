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
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'])
          : null,
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
      case 'invitation_declined':
        return 'Lời mời bị từ chối';
      case 'task_assigned':
        return 'Task được giao';
      case 'task_due_today':
        return 'Task đến hạn';
      case 'task_overdue':
        return 'Task quá hạn';
      case 'project_overdue':
        return 'Dự án quá hạn';
      case 'task_completed':
        return 'Task hoàn thành';
      case 'project_completed':
        return 'Dự án hoàn thành';
      case 'member_joined':
        return 'Thành viên mới';
      case 'member_removed':
        return 'Thành viên bị loại';
      case 'member_left':
        return 'Thành viên rời dự án';
      case 'comment_mention':
        return 'Được nhắc đến';
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
  final String? commentId;
  final String? commentContent;
  final String? invitationId;
  final String? invitationToken;
  final String? invitationEmail;
  final String? invitationStatus;
  final String? invitationMessage;
  final DateTime? invitationExpiresAt;
  final DateTime? invitationAcceptedAt;
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
    this.commentId,
    this.commentContent,
    this.invitationId,
    this.invitationToken,
    this.invitationEmail,
    this.invitationStatus,
    this.invitationMessage,
    this.invitationExpiresAt,
    this.invitationAcceptedAt,
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
      'commentId': commentId,
      'commentContent': commentContent,
      'invitationId': invitationId,
      'invitationToken': invitationToken,
      'invitationEmail': invitationEmail,
      'invitationStatus': invitationStatus,
      'invitationMessage': invitationMessage,
      'invitationExpiresAt': invitationExpiresAt?.toIso8601String(),
      'invitationAcceptedAt': invitationAcceptedAt?.toIso8601String(),
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
          : (map['projectId'] is Map
                ? map['projectId']['_id']?.toString()
                : null),
      projectTitle: map['projectTitle']?.toString(),
      taskId: map['taskId'] is String
          ? map['taskId']
          : (map['taskId'] is Map ? map['taskId']['_id']?.toString() : null),
      taskTitle: map['taskTitle']?.toString(),
      commentId: map['commentId']?.toString(),
      commentContent: map['commentContent']?.toString(),
      invitationId: map['invitationId']?.toString(),
      invitationToken: map['invitationToken']?.toString(),
      invitationEmail: map['invitationEmail']?.toString(),
      invitationStatus: map['invitationStatus']?.toString(),
      invitationMessage: map['invitationMessage']?.toString(),
      invitationExpiresAt: map['invitationExpiresAt'] != null
          ? DateTime.tryParse(map['invitationExpiresAt'].toString())
          : null,
      invitationAcceptedAt: map['invitationAcceptedAt'] != null
          ? DateTime.tryParse(map['invitationAcceptedAt'].toString())
          : null,
      fromUserId: map['fromUserId'] is String
          ? map['fromUserId']
          : (map['fromUserId'] is Map
                ? map['fromUserId']['_id']?.toString()
                : null),
      fromUserName: map['fromUserName']?.toString(),
      extra: map['extra'] is Map
          ? Map<String, dynamic>.from(map['extra'])
          : null,
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
    return {'inApp': inApp, 'push': push, 'email': email};
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
  final NotificationUser? createdBy;

  NotificationProject({required this.id, required this.title, this.createdBy});

  factory NotificationProject.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('NotificationProject.fromMap: map cannot be null');
    }

    return NotificationProject(
      id: map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      createdBy: map['createdBy'] is Map<String, dynamic>
          ? NotificationUser.fromMap(map['createdBy'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {'_id': id, 'title': title, 'createdBy': createdBy?.toMap()};
  }
}

class NotificationTask {
  final String id;
  final String title;
  final NotificationUser? createdBy;

  NotificationTask({required this.id, required this.title, this.createdBy});

  factory NotificationTask.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('NotificationTask.fromMap: map cannot be null');
    }

    return NotificationTask(
      id: map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      createdBy: map['createdBy'] is Map<String, dynamic>
          ? NotificationUser.fromMap(map['createdBy'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {'_id': id, 'title': title, 'createdBy': createdBy?.toMap()};
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
  final bool projectInvitations;
  final bool invitationDeclined;
  final bool taskAssignments;
  final bool taskDueToday;
  final bool taskOverdue;
  final bool projectOverdue;
  final bool taskCompleted;
  final bool projectCompleted;
  final bool memberJoined;
  final bool memberRemoved;
  final bool memberLeft;
  final bool commentMention;

  NotificationPreferences({
    this.projectInvitations = true,
    this.invitationDeclined = true,
    this.taskAssignments = true,
    this.taskDueToday = true,
    this.taskOverdue = true,
    this.projectOverdue = true,
    this.taskCompleted = true,
    this.projectCompleted = true,
    this.memberJoined = true,
    this.memberRemoved = true,
    this.memberLeft = true,
    this.commentMention = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectInvitations': projectInvitations,
      'invitationDeclined': invitationDeclined,
      'taskAssignments': taskAssignments,
      'taskDueToday': taskDueToday,
      'taskOverdue': taskOverdue,
      'projectOverdue': projectOverdue,
      'taskCompleted': taskCompleted,
      'projectCompleted': projectCompleted,
      'memberJoined': memberJoined,
      'memberRemoved': memberRemoved,
      'memberLeft': memberLeft,
      'commentMention': commentMention,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return NotificationPreferences();
    }

    return NotificationPreferences(
      projectInvitations: map['projectInvitations'] ?? true,
      invitationDeclined: map['invitationDeclined'] ?? true,
      taskAssignments: map['taskAssignments'] ?? true,
      taskDueToday: map['taskDueToday'] ?? map['taskDeadlineWarnings'] ?? true,
      taskOverdue: map['taskOverdue'] ?? map['taskDeadlineWarnings'] ?? true,
      projectOverdue:
          map['projectOverdue'] ?? map['projectDeadlineWarnings'] ?? true,
      taskCompleted: map['taskCompleted'] ?? true,
      projectCompleted: map['projectCompleted'] ?? true,
      memberJoined: map['memberJoined'] ?? true,
      memberRemoved: map['memberRemoved'] ?? true,
      memberLeft: map['memberLeft'] ?? true,
      commentMention: map['commentMention'] ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? projectInvitations,
    bool? invitationDeclined,
    bool? taskAssignments,
    bool? taskDueToday,
    bool? taskOverdue,
    bool? projectOverdue,
    bool? taskCompleted,
    bool? projectCompleted,
    bool? memberJoined,
    bool? memberRemoved,
    bool? memberLeft,
    bool? commentMention,
  }) {
    return NotificationPreferences(
      projectInvitations: projectInvitations ?? this.projectInvitations,
      invitationDeclined: invitationDeclined ?? this.invitationDeclined,
      taskAssignments: taskAssignments ?? this.taskAssignments,
      taskDueToday: taskDueToday ?? this.taskDueToday,
      taskOverdue: taskOverdue ?? this.taskOverdue,
      projectOverdue: projectOverdue ?? this.projectOverdue,
      taskCompleted: taskCompleted ?? this.taskCompleted,
      projectCompleted: projectCompleted ?? this.projectCompleted,
      memberJoined: memberJoined ?? this.memberJoined,
      memberRemoved: memberRemoved ?? this.memberRemoved,
      memberLeft: memberLeft ?? this.memberLeft,
      commentMention: commentMention ?? this.commentMention,
    );
  }
}
