import 'dart:convert';
import 'package:frontend/models/task.dart';

class Dependency {
  final String id;
  final String projectId;
  final String predecessorId;
  final String successorId;
  final String type; // 'FS'
  final int lag;
  final DateTime createdAt;
  
  // Populated fields (khi query từ API)
  final Task? predecessor;
  final Task? successor;
  
  Dependency({
    required this.id,
    required this.projectId,
    required this.predecessorId,
    required this.successorId,
    this.type = 'FS',
    this.lag = 0,
    required this.createdAt,
    this.predecessor,
    this.successor,
  });
  
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'projectId': projectId,
      'predecessorId': predecessorId,
      'successorId': successorId,
      'type': type,
      'lag': lag,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory Dependency.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('Dependency.fromMap: map cannot be null');
    }
    
    return Dependency(
      id: map['_id']?.toString() ?? '',
      projectId: map['projectId']?.toString() ?? '',
      predecessorId: map['predecessorId'] is String 
          ? map['predecessorId'] 
          : (map['predecessorId'] is Map ? map['predecessorId']['_id']?.toString() ?? '' : ''),
      successorId: map['successorId'] is String 
          ? map['successorId'] 
          : (map['successorId'] is Map ? map['successorId']['_id']?.toString() ?? '' : ''),
      type: map['type']?.toString() ?? 'FS',
      lag: map['lag']?.toInt() ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      predecessor: map['predecessorId'] is Map 
          ? Task.fromMap(map['predecessorId'] as Map<String, dynamic>) 
          : null,
      successor: map['successorId'] is Map 
          ? Task.fromMap(map['successorId'] as Map<String, dynamic>) 
          : null,
    );
  }
  
  String toJson() => json.encode(toMap());
  
  factory Dependency.fromJson(String source) => Dependency.fromMap(json.decode(source));
  
  @override
  String toString() {
    return 'Dependency(id: $id, predecessorId: $predecessorId, successorId: $successorId, type: $type)';
  }
}

class DependencyViolation {
  final String taskId;
  final DateTime currentStart;
  final DateTime requiredStart;
  final int gap; // số ngày vi phạm
  final List<Task> criticalPredecessors;
  
  DependencyViolation({
    required this.taskId,
    required this.currentStart,
    required this.requiredStart,
    required this.gap,
    this.criticalPredecessors = const [],
  });
  
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'currentStart': currentStart.toIso8601String(),
      'requiredStart': requiredStart.toIso8601String(),
      'gap': gap,
      'criticalPredecessors': criticalPredecessors.map((t) => t.toMap()).toList(),
    };
  }
  
  factory DependencyViolation.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('DependencyViolation.fromMap: map cannot be null');
    }
    
    return DependencyViolation(
      taskId: map['taskId']?.toString() ?? '',
      currentStart: map['currentStart'] != null 
          ? DateTime.parse(map['currentStart']) 
          : DateTime.now(),
      requiredStart: map['requiredStart'] != null 
          ? DateTime.parse(map['requiredStart']) 
          : DateTime.now(),
      gap: map['gap']?.toInt() ?? 0,
      criticalPredecessors: map['criticalPredecessors'] != null
          ? List<Task>.from((map['criticalPredecessors'] as List)
              .map((t) => Task.fromMap(t as Map<String, dynamic>)))
          : [],
    );
  }
  
  String toJson() => json.encode(toMap());
  
  factory DependencyViolation.fromJson(String source) => 
      DependencyViolation.fromMap(json.decode(source));
  
  @override
  String toString() {
    return 'DependencyViolation(taskId: $taskId, gap: $gap days, requiredStart: $requiredStart)';
  }
}
