import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';

/// Model cho tệp đính kèm của Task
class TaskAttachment {
  final String id;
  final String url;
  final String fileName;
  final String fileType; // 'image', 'document', 'video'
  final int fileSize;
  final Map<String, dynamic>? uploadedBy;
  final DateTime uploadedAt;

  TaskAttachment({
    required this.id,
    required this.url,
    required this.fileName,
    required this.fileType,
    this.fileSize = 0,
    this.uploadedBy,
    required this.uploadedAt,
  });

  factory TaskAttachment.fromMap(Map<String, dynamic> map) {
    return TaskAttachment(
      id: map['_id']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      fileName: map['fileName']?.toString() ?? '',
      fileType: map['fileType']?.toString() ?? 'document',
      fileSize: map['fileSize']?.toInt() ?? 0,
      uploadedBy: map['uploadedBy'] is Map
          ? {
              '_id': map['uploadedBy']['_id']?.toString() ?? '',
              'name': map['uploadedBy']['name']?.toString() ?? '',
              'email': map['uploadedBy']['email']?.toString() ?? '',
              'avatar': map['uploadedBy']['avatar']?.toString() ?? '',
              'avatarColor': map['uploadedBy']['avatarColor']?.toString() ?? '',
            }
          : null,
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.parse(map['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'url': url,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  bool get isImage => fileType == 'image';
  bool get isDocument => fileType == 'document';
  bool get isVideo => fileType == 'video';

  /// Lấy kích thước file dạng đọc được (KB, MB, GB)
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Lấy extension của file
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String projectId;
  final List<Map<String, dynamic>> assignedTo;
  final String createdBy;
  final DateTime? startDate;
  final DateTime? endDate;
  final String schedulingMode;
  final int weight;
  final String? parentTaskId;
  final String path;
  final int level;
  final int order;
  final int progress;
  final int subTaskCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Task>? subtasks;
  final List<TaskAttachment> attachments;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.projectId,
    this.assignedTo = const [],
    required this.createdBy,
    this.startDate,
    this.endDate,
    this.schedulingMode = 'AUTO',
    this.weight = 1,
    this.parentTaskId,
    required this.path,
    required this.level,
    required this.order,
    required this.progress,
    required this.subTaskCount,
    required this.createdAt,
    required this.updatedAt,
    this.subtasks,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'projectId': projectId,
      'assignedTo': assignedTo.map((user) => user['_id']).toList(),
      'createdBy': createdBy,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'schedulingMode': schedulingMode,
      'weight': weight,
      'parentTaskId': parentTaskId,
      'path': path,
      'level': level,
      'order': order,
      'progress': progress,
      'subTaskCount': subTaskCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'subtasks': subtasks?.map((x) => x.toMap()).toList(),
      'attachments': attachments.map((x) => x.toMap()).toList(),
    };
  }

  factory Task.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('Task.fromMap: map cannot be null');
    }
    
    // Parse assignedTo array
    List<Map<String, dynamic>> assignedToList = [];
    if (map['assignedTo'] != null) {
      if (map['assignedTo'] is List) {
        assignedToList = (map['assignedTo'] as List).map((item) {
          if (item is String) {
            return {'_id': item, 'name': '', 'email': '', 'avatar': '', 'avatarColor': ''};
          } else if (item is Map) {
            return {
              '_id': item['_id']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'email': item['email']?.toString() ?? '',
              'avatar': item['avatar']?.toString() ?? '',
              'avatarColor': item['avatarColor']?.toString() ?? '',
            };
          }
          return {'_id': '', 'name': '', 'email': '', 'avatar': '', 'avatarColor': ''};
        }).toList();
      }
    }
    
    return Task(
      id: map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      status: map['status']?.toString() ?? 'todo',
      priority: map['priority']?.toString() ?? 'medium',
      projectId: map['projectId'] is String 
          ? map['projectId'] 
          : (map['projectId'] is Map ? map['projectId']['_id']?.toString() ?? '' : ''),
      assignedTo: assignedToList,
      createdBy: map['createdBy'] is String 
          ? map['createdBy'] 
          : (map['createdBy'] is Map ? map['createdBy']['_id']?.toString() ?? '' : ''),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      schedulingMode: map['schedulingMode']?.toString() ?? 'AUTO',
      weight: map['weight']?.toInt() ?? 1,
      parentTaskId: map['parentTaskId'] is String 
          ? map['parentTaskId'] 
          : (map['parentTaskId'] is Map ? map['parentTaskId']['_id']?.toString() : null),
      path: map['path']?.toString() ?? '',
      level: map['level']?.toInt() ?? 0,
      order: map['order']?.toInt() ?? 0,
      progress: map['progress']?.toInt() ?? 0,
      subTaskCount: map['subTaskCount']?.toInt() ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      subtasks: map['subtasks'] != null 
          ? List<Task>.from((map['subtasks'] as List).map((x) => Task.fromMap(x)))
          : null,
      attachments: map['attachments'] != null
          ? List<TaskAttachment>.from(
              (map['attachments'] as List).map((x) => TaskAttachment.fromMap(x)))
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? projectId,
    List<Map<String, dynamic>>? assignedTo,
    String? createdBy,
    DateTime? startDate,
    DateTime? endDate,
    String? schedulingMode,
    int? weight,
    String? parentTaskId,
    String? path,
    int? level,
    int? order,
    int? progress,
    int? subTaskCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Task>? subtasks,
    List<TaskAttachment>? attachments,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      projectId: projectId ?? this.projectId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      schedulingMode: schedulingMode ?? this.schedulingMode,
      weight: weight ?? this.weight,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      path: path ?? this.path,
      level: level ?? this.level,
      order: order ?? this.order,
      progress: progress ?? this.progress,
      subTaskCount: subTaskCount ?? this.subTaskCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtasks: subtasks ?? this.subtasks,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, description: $description, status: $status, priority: $priority, projectId: $projectId, assignedTo: $assignedTo, createdBy: $createdBy, startDate: $startDate, endDate: $endDate, schedulingMode: $schedulingMode, parentTaskId: $parentTaskId, path: $path, level: $level, order: $order, progress: $progress, subTaskCount: $subTaskCount, createdAt: $createdAt, updatedAt: $updatedAt, subtasks: $subtasks)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Task && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  // Utility getters
  String get statusDisplayName {
    switch (status) {
      case 'todo':
        return tr('todo');
      case 'in-progress':
        return tr('in_progress');
      case 'review':
        return tr('review');
      case 'completed':
        return tr('completed');
      default:
        return status;
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'low':
        return tr('low');
      case 'medium':
        return tr('medium');
      case 'high':
        return tr('high');
      default:
        return priority;
    }
  }

  String get priorityDisplayFullName {
    switch (priority) {
      case 'low':
        return tr('low_priority');
      case 'medium':
        return tr('medium_priority');
      case 'high':
        return tr('high_priority');
      default:
        return priority;
    }
  }

  // Kiểm tra trạng thái
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in-progress';
  bool get isTodo => status == 'todo';
  bool get isInReview => status == 'review';

  // Kiểm tra thời hạn
  bool get isOverdue {
    if (endDate == null || isCompleted) return false;
    return DateTime.now().isAfter(endDate!);
  }
  
  int get daysRemaining {
    if (endDate == null || isCompleted) return 0;
    final now = DateTime.now();
    final difference = endDate!.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }
  
  // Scheduling helpers
  bool get hasValidDates => startDate != null && endDate != null;
  
  int get durationDays {
    if (!hasValidDates) return 0;
    return endDate!.difference(startDate!).inDays;
  }
  
  bool get isAutoScheduled => schedulingMode == 'AUTO';
  bool get isManualScheduled => schedulingMode == 'MANUAL';

  // Kiểm tra phân cấp
  bool get isRootTask => parentTaskId == null;
  bool get isSubtask => parentTaskId != null;
  bool get hasSubtasks => subtasks != null && subtasks!.isNotEmpty;
  
  // Progress percentage
  double get progressPercentage => progress / 100.0;

  // Utility methods cho hierarchy
  String get indentedTitle {
    return '${'  ' * level}$title';
  }

  List<String> get pathIds {
    if (path.isEmpty) return [];
    return path.split('/');
  }

  // Lấy tất cả subtasks (flat list)
  List<Task> get allSubtasks {
    if (!hasSubtasks) return [];
    
    List<Task> allSubs = [];
    for (Task subtask in subtasks!) {
      allSubs.add(subtask);
      allSubs.addAll(subtask.allSubtasks);
    }
    return allSubs;
  }

  // Đếm tổng số subtasks
  int get totalSubtasksCount {
    return allSubtasks.length;
  }

  // Đếm số subtasks đã hoàn thành
  int get completedSubtasksCount {
    return allSubtasks.where((task) => task.isCompleted).length;
  }

  // Tính phần trăm hoàn thành của subtasks
  double get subtasksCompletionPercentage {
    if (totalSubtasksCount == 0) return 0.0;
    return completedSubtasksCount / totalSubtasksCount;
  }

  // Kiểm tra xem có thể xóa được không (phải xóa tất cả subtasks trước)
  bool get canBeDeleted => !hasSubtasks;

  // Attachment helpers
  bool get hasAttachments => attachments.isNotEmpty;
  int get attachmentCount => attachments.length;
  List<TaskAttachment> get imageAttachments => 
      attachments.where((a) => a.isImage).toList();
  List<TaskAttachment> get documentAttachments => 
      attachments.where((a) => a.isDocument).toList();
  List<TaskAttachment> get videoAttachments => 
      attachments.where((a) => a.isVideo).toList();

  // So sánh để sắp xếp
  int compareTo(Task other) {
    // Sắp xếp theo level trước, sau đó theo order
    if (level != other.level) {
      return level.compareTo(other.level);
    }
    return order.compareTo(other.order);
  }
}
