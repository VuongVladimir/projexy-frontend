import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';

class Project {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic> createdBy;
  final List<ProjectMember> members;
  final List<String> tags;
  final int progress;
  final int taskCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPremium;

  Project({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.startDate,
    this.endDate,
    required this.createdBy,
    required this.members,
    required this.tags,
    required this.progress,
    required this.taskCount,
    required this.createdAt,
    required this.updatedAt,
    this.isPremium = false,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdBy': createdBy,
      'members': members,
      'tags': tags,
      'progress': progress,
      'taskCount': taskCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPremium': isPremium,
    };
  }

  factory Project.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('Project.fromMap: map cannot be null');
    }

    return Project(
      id: map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planning',
      priority: map['priority']?.toString() ?? 'Medium',
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      createdBy: map['createdBy'] is Map<String, dynamic>
          ? {
              'id': map['createdBy']['_id']?.toString() ?? '',
              'name': map['createdBy']['name']?.toString() ?? '',
              'email': map['createdBy']['email']?.toString() ?? '',
              'avatar': map['createdBy']['avatar']?.toString() ?? '',
              'avatarColor': map['createdBy']['avatarColor']?.toString() ?? '',
            }
          : {
              'id': '',
              'name': '',
              'email': '',
              'avatar': '',
              'avatarColor': '',
            },
      members: List<ProjectMember>.from(
        (map['members'] as List? ?? []).map(
          (member) => ProjectMember.fromMap(
            member is Map<String, dynamic> ? member : {'user': member},
          ),
        ),
      ),
      tags: List<String>.from(
        (map['tags'] as List? ?? []).map((tag) => tag.toString()),
      ),
      progress: map['progress']?.toInt() ?? 0,
      taskCount: map['taskCount']?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      isPremium: map['isPremium'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory Project.fromJson(String source) =>
      Project.fromMap(json.decode(source));

  Project copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? createdBy,
    List<ProjectMember>? members,
    List<String>? tags,
    int? progress,
    int? taskCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPremium,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      tags: tags ?? this.tags,
      progress: progress ?? this.progress,
      taskCount: taskCount ?? this.taskCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  String toString() {
    return 'Project(id: $id, title: $title, description: $description, status: $status, priority: $priority, startDate: $startDate, endDate: $endDate, createdBy: $createdBy, members: $members, tags: $tags, progress: $progress, taskCount: $taskCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Project && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  // Utility getters
  String get statusDisplayName {
    switch (status) {
      case 'Planning':
        return tr('planning');
      case 'In-progress':
        return tr('in_progress');
      case 'Completed':
        return tr('completed');
      default:
        return status;
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'Low':
        return tr('low');
      case 'Medium':
        return tr('medium');
      case 'High':
        return tr('high');
      default:
        return priority;
    }
  }

  String get priorityDisplayFullName {
    switch (priority) {
      case 'Low':
        return tr('low_priority');
      case 'Medium':
        return tr('medium_priority');
      case 'High':
        return tr('high_priority');
      default:
        return priority;
    }
  }

  // Kiểm tra trạng thái
  bool get isCompleted => status == 'Completed';
  bool get isInProgress => status == 'In-progress';
  bool get isPlanning => status == 'Planning';

  // Kiểm tra thời hạn
  bool get isOverdue =>
      endDate != null && DateTime.now().isAfter(endDate!) && !isCompleted;

  int get daysRemaining {
    if (isCompleted || endDate == null) return 0;
    final now = DateTime.now();
    final difference = endDate!.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  // Tính phần trăm hoàn thành
  double get progressPercentage => progress / 100.0;

  bool get hasValidDates => startDate != null && endDate != null;
}

class ProjectAnalytics {
  final AnalyticsMetrics metrics;
  final AnalyticsStatusOverview statusOverview;
  final AnalyticsTeamWorkload teamWorkload;

  ProjectAnalytics({
    required this.metrics,
    required this.statusOverview,
    required this.teamWorkload,
  });

  factory ProjectAnalytics.fromMap(Map<String, dynamic> map) {
    return ProjectAnalytics(
      metrics: AnalyticsMetrics.fromMap(
        map['metrics'] as Map<String, dynamic>? ?? {},
      ),
      statusOverview: AnalyticsStatusOverview.fromMap(
        map['statusOverview'] as Map<String, dynamic>? ?? {},
      ),
      teamWorkload: AnalyticsTeamWorkload.fromMap(
        map['teamWorkload'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class AnalyticsMetricBucket {
  final int count;
  final List<String> taskIds;

  AnalyticsMetricBucket({required this.count, required this.taskIds});

  factory AnalyticsMetricBucket.fromMap(Map<String, dynamic> map) {
    return AnalyticsMetricBucket(
      count: map['count']?.toInt() ?? 0,
      taskIds: List<String>.from(
        (map['taskIds'] as List? ?? []).map((item) => item.toString()),
      ),
    );
  }
}

class AnalyticsMetrics {
  final AnalyticsMetricBucket doneLast7Days;
  final AnalyticsMetricBucket updatedLast7Days;
  final AnalyticsMetricBucket createdLast7Days;
  final AnalyticsMetricBucket dueSoonNext7Days;
  final AnalyticsMetricBucket dependencyViolations;
  final AnalyticsMetricBucket blockedTasks;

  AnalyticsMetrics({
    required this.doneLast7Days,
    required this.updatedLast7Days,
    required this.createdLast7Days,
    required this.dueSoonNext7Days,
    required this.dependencyViolations,
    required this.blockedTasks,
  });

  factory AnalyticsMetrics.fromMap(Map<String, dynamic> map) {
    return AnalyticsMetrics(
      doneLast7Days: AnalyticsMetricBucket.fromMap(
        map['doneLast7Days'] as Map<String, dynamic>? ?? {},
      ),
      updatedLast7Days: AnalyticsMetricBucket.fromMap(
        map['updatedLast7Days'] as Map<String, dynamic>? ?? {},
      ),
      createdLast7Days: AnalyticsMetricBucket.fromMap(
        map['createdLast7Days'] as Map<String, dynamic>? ?? {},
      ),
      dueSoonNext7Days: AnalyticsMetricBucket.fromMap(
        map['dueSoonNext7Days'] as Map<String, dynamic>? ?? {},
      ),
      dependencyViolations: AnalyticsMetricBucket.fromMap(
        map['dependencyViolations'] as Map<String, dynamic>? ?? {},
      ),
      blockedTasks: AnalyticsMetricBucket.fromMap(
        map['blockedTasks'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class AnalyticsStatusBucket {
  final String status;
  final int count;
  final List<String> taskIds;

  AnalyticsStatusBucket({
    required this.status,
    required this.count,
    required this.taskIds,
  });

  factory AnalyticsStatusBucket.fromMap(Map<String, dynamic> map) {
    return AnalyticsStatusBucket(
      status: map['status']?.toString() ?? 'todo',
      count: map['count']?.toInt() ?? 0,
      taskIds: List<String>.from(
        (map['taskIds'] as List? ?? []).map((item) => item.toString()),
      ),
    );
  }
}

class AnalyticsStatusOverview {
  final int total;
  final int periodDays;
  final List<AnalyticsStatusBucket> buckets;

  AnalyticsStatusOverview({
    required this.total,
    required this.periodDays,
    required this.buckets,
  });

  factory AnalyticsStatusOverview.fromMap(Map<String, dynamic> map) {
    return AnalyticsStatusOverview(
      total: map['total']?.toInt() ?? 0,
      periodDays: map['periodDays']?.toInt() ?? 14,
      buckets: List<AnalyticsStatusBucket>.from(
        (map['buckets'] as List? ?? []).map(
          (item) => AnalyticsStatusBucket.fromMap(item as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class AnalyticsWorkloadMember {
  final String? userId;
  final String name;
  final String avatar;
  final String avatarColor;
  final int count;
  final int percentage;
  final List<String> taskIds;

  AnalyticsWorkloadMember({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.avatarColor,
    required this.count,
    required this.percentage,
    required this.taskIds,
  });

  factory AnalyticsWorkloadMember.fromMap(Map<String, dynamic> map) {
    return AnalyticsWorkloadMember(
      userId: map['userId']?.toString(),
      name: map['name']?.toString() ?? '',
      avatar: map['avatar']?.toString() ?? '',
      avatarColor: map['avatarColor']?.toString() ?? '#9CA3AF',
      count: map['count']?.toInt() ?? 0,
      percentage: map['percentage']?.toInt() ?? 0,
      taskIds: List<String>.from(
        (map['taskIds'] as List? ?? []).map((item) => item.toString()),
      ),
    );
  }
}

class AnalyticsTeamWorkload {
  final int totalActiveTasks;
  final List<AnalyticsWorkloadMember> members;

  AnalyticsTeamWorkload({
    required this.totalActiveTasks,
    required this.members,
  });

  factory AnalyticsTeamWorkload.fromMap(Map<String, dynamic> map) {
    return AnalyticsTeamWorkload(
      totalActiveTasks: map['totalActiveTasks']?.toInt() ?? 0,
      members: List<AnalyticsWorkloadMember>.from(
        (map['members'] as List? ?? []).map(
          (item) =>
              AnalyticsWorkloadMember.fromMap(item as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class ProjectMember {
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? avatar;
  final String? avatarColor;
  final String role; // Owner, Manager, Member, Viewer
  final ProjectPermissions permissions;
  final DateTime joinedAt;

  ProjectMember({
    required this.userId,
    this.userName,
    this.userEmail,
    this.avatar,
    this.avatarColor,
    required this.role,
    required this.permissions,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user': userId,
      'userName': userName,
      'userEmail': userEmail,
      'avatar': avatar,
      'avatarColor': avatarColor,
      'role': role,
      'permissions': permissions.toMap(),
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory ProjectMember.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('ProjectMember.fromMap: map cannot be null');
    }

    return ProjectMember(
      userId: map['user'] is String
          ? map['user']
          : (map['user'] is Map ? map['user']['_id']?.toString() ?? '' : ''),
      userName: map['user'] is String
          ? null
          : (map['user'] is Map ? map['user']['name']?.toString() : null),
      userEmail: map['user'] is String
          ? null
          : (map['user'] is Map ? map['user']['email']?.toString() : null),
      avatar: map['user'] is String
          ? null
          : (map['user'] is Map ? map['user']['avatar']?.toString() : null),
      avatarColor: map['user'] is String
          ? null
          : (map['user'] is Map
                ? map['user']['avatarColor']?.toString()
                : null),
      role: map['role']?.toString() ?? 'Member',
      permissions: ProjectPermissions.fromMap(map['permissions'] ?? {}),
      joinedAt: map['joinedAt'] != null
          ? DateTime.parse(map['joinedAt'])
          : DateTime.now(),
    );
  }

  ProjectMember copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? avatar,
    String? avatarColor,
    String? role,
    ProjectPermissions? permissions,
    DateTime? joinedAt,
  }) {
    return ProjectMember(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      avatar: avatar ?? this.avatar,
      avatarColor: avatarColor ?? this.avatarColor,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  // Utility getters for role display
  String get roleDisplayName {
    switch (role) {
      case 'Owner':
        return tr('owner');
      case 'Manager':
        return tr('manager');
      case 'Member':
        return tr('member');
      case 'Viewer':
        return tr('viewer');
      default:
        return role;
    }
  }

  bool get isViewer => role == 'Viewer';
  bool get isManager => role == 'Manager';
  bool get isMember => role == 'Member';
}

class ProjectPermissions {
  final bool editProjectPermission;
  final bool addMemberPermission;
  final bool removeMemberPermission;
  final bool manageAccessPermission;
  final bool createTaskPermission;
  final bool editTaskPermission;
  final bool deleteTaskPermission;
  final bool assignTaskPermission;
  final bool markCompleteTaskPermission;
  final bool addAttachmentPermission;
  final bool deleteAttachmentPermission;
  final bool addCommentPermission;
  final bool deleteCommentPermission;

  ProjectPermissions({
    this.editProjectPermission = false,
    this.addMemberPermission = false,
    this.removeMemberPermission = false,
    this.manageAccessPermission = false,
    this.createTaskPermission = false,
    this.editTaskPermission = false,
    this.deleteTaskPermission = false,
    this.assignTaskPermission = false,
    this.markCompleteTaskPermission = false,
    this.addAttachmentPermission = false,
    this.deleteAttachmentPermission = false,
    this.addCommentPermission = false,
    this.deleteCommentPermission = false,
  });

  static ProjectPermissions defaultForRole(String role) {
    switch (role) {
      case 'Manager':
        return ProjectPermissions(
          editProjectPermission: true,
          addMemberPermission: true,
          removeMemberPermission: true,
          manageAccessPermission: true,
          createTaskPermission: true,
          editTaskPermission: true,
          deleteTaskPermission: true,
          assignTaskPermission: true,
          markCompleteTaskPermission: true,
          addAttachmentPermission: true,
          deleteAttachmentPermission: true,
          addCommentPermission: true,
          deleteCommentPermission: true,
        );
      case 'Viewer':
        return ProjectPermissions(
          editProjectPermission: false,
          addMemberPermission: false,
          removeMemberPermission: false,
          manageAccessPermission: false,
          createTaskPermission: false,
          editTaskPermission: false,
          deleteTaskPermission: false,
          assignTaskPermission: false,
          markCompleteTaskPermission: false,
          addAttachmentPermission: false,
          deleteAttachmentPermission: false,
          addCommentPermission: false,
          deleteCommentPermission: false,
        );
      case 'Member':
      default:
        return ProjectPermissions(
          editProjectPermission: false,
          addMemberPermission: false,
          removeMemberPermission: false,
          manageAccessPermission: false,
          createTaskPermission: false,
          editTaskPermission: false,
          deleteTaskPermission: false,
          assignTaskPermission: false,
          markCompleteTaskPermission: false,
          addAttachmentPermission: true,
          deleteAttachmentPermission: false,
          addCommentPermission: true,
          deleteCommentPermission: false,
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'editProjectPermission': editProjectPermission,
      'addMemberPermission': addMemberPermission,
      'removeMemberPermission': removeMemberPermission,
      'manageAccessPermission': manageAccessPermission,
      'createTaskPermission': createTaskPermission,
      'editTaskPermission': editTaskPermission,
      'deleteTaskPermission': deleteTaskPermission,
      'assignTaskPermission': assignTaskPermission,
      'markCompleteTaskPermission': markCompleteTaskPermission,
      'addAttachmentPermission': addAttachmentPermission,
      'deleteAttachmentPermission': deleteAttachmentPermission,
      'addCommentPermission': addCommentPermission,
      'deleteCommentPermission': deleteCommentPermission,
    };
  }

  factory ProjectPermissions.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return ProjectPermissions();
    }

    return ProjectPermissions(
      editProjectPermission: map['editProjectPermission'] == true,
      addMemberPermission: map['addMemberPermission'] == true,
      removeMemberPermission: map['removeMemberPermission'] == true,
      manageAccessPermission: map['manageAccessPermission'] == true,
      createTaskPermission: map['createTaskPermission'] == true,
      editTaskPermission: map['editTaskPermission'] == true,
      deleteTaskPermission: map['deleteTaskPermission'] == true,
      assignTaskPermission: map['assignTaskPermission'] == true,
      markCompleteTaskPermission: map['markCompleteTaskPermission'] == true,
      addAttachmentPermission: map['addAttachmentPermission'] == true,
      deleteAttachmentPermission: map['deleteAttachmentPermission'] == true,
      addCommentPermission: map['addCommentPermission'] == true,
      deleteCommentPermission: map['deleteCommentPermission'] == true,
    );
  }

  ProjectPermissions copyWith({
    bool? editProjectPermission,
    bool? addMemberPermission,
    bool? removeMemberPermission,
    bool? manageAccessPermission,
    bool? createTaskPermission,
    bool? editTaskPermission,
    bool? deleteTaskPermission,
    bool? assignTaskPermission,
    bool? markCompleteTaskPermission,
    bool? addAttachmentPermission,
    bool? deleteAttachmentPermission,
    bool? addCommentPermission,
    bool? deleteCommentPermission,
  }) {
    return ProjectPermissions(
      editProjectPermission:
          editProjectPermission ?? this.editProjectPermission,
      addMemberPermission: addMemberPermission ?? this.addMemberPermission,
      removeMemberPermission:
          removeMemberPermission ?? this.removeMemberPermission,
      manageAccessPermission:
          manageAccessPermission ?? this.manageAccessPermission,
      createTaskPermission: createTaskPermission ?? this.createTaskPermission,
      editTaskPermission: editTaskPermission ?? this.editTaskPermission,
      deleteTaskPermission: deleteTaskPermission ?? this.deleteTaskPermission,
      assignTaskPermission: assignTaskPermission ?? this.assignTaskPermission,
      markCompleteTaskPermission:
          markCompleteTaskPermission ?? this.markCompleteTaskPermission,
      addAttachmentPermission:
          addAttachmentPermission ?? this.addAttachmentPermission,
      deleteAttachmentPermission:
          deleteAttachmentPermission ?? this.deleteAttachmentPermission,
      addCommentPermission: addCommentPermission ?? this.addCommentPermission,
      deleteCommentPermission:
          deleteCommentPermission ?? this.deleteCommentPermission,
    );
  }

  // Utility getters
  bool get hasAnyPermission =>
      editProjectPermission ||
      addMemberPermission ||
      removeMemberPermission ||
      manageAccessPermission ||
      createTaskPermission ||
      editTaskPermission ||
      deleteTaskPermission ||
      assignTaskPermission ||
      markCompleteTaskPermission ||
      addAttachmentPermission ||
      deleteAttachmentPermission ||
      addCommentPermission ||
      deleteCommentPermission;

  List<String> get permissionsList {
    List<String> permissions = [];
    if (editProjectPermission) permissions.add(tr('edit_project'));
    if (addMemberPermission) permissions.add(tr('add_member'));
    if (removeMemberPermission) permissions.add(tr('remove_member'));
    if (manageAccessPermission) permissions.add(tr('manage_access'));
    if (createTaskPermission) permissions.add(tr('create_task'));
    if (editTaskPermission) permissions.add(tr('edit_task'));
    if (deleteTaskPermission) permissions.add(tr('delete_task'));
    if (assignTaskPermission) permissions.add(tr('assign_task'));
    if (markCompleteTaskPermission) permissions.add(tr('mark_complete_task'));
    if (addAttachmentPermission) permissions.add(tr('add_attachment'));
    if (deleteAttachmentPermission) permissions.add(tr('delete_attachment'));
    if (addCommentPermission) permissions.add(tr('add_comment'));
    if (deleteCommentPermission) permissions.add(tr('delete_comment'));
    return permissions;
  }
}
