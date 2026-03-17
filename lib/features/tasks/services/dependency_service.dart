import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/models/dependency.dart';
import 'package:frontend/models/task.dart';

class DependencyService {
  // Tạo dependency
  static Future<void> createDependency({
    required BuildContext context,
    required String predecessorId,
    required String successorId,
    required String projectId,
    required Function(Dependency, DependencyViolation?) onSuccess,
  }) async {
    try {
      final body = {
        'predecessorId': predecessorId,
        'successorId': successorId,
        'projectId': projectId,
      };

      final response = await ApiClient.post(
        url: '$uri/api/dependency/create',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final dependency = Dependency.fromMap(data['dependency']);
            final violation = data['violation'] != null
                ? DependencyViolation.fromMap(data['violation'])
                : null;
            onSuccess(dependency, violation);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Xóa dependency
  static Future<void> deleteDependency({
    required BuildContext context,
    required String dependencyId,
    required VoidCallback onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      final response = await ApiClient.delete(
        url: '$uri/api/dependency/$dependencyId',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: onSuccess,
          onError: onError,
        );
      }
    } catch (e) {
      onError?.call();
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Lấy dependencies của task
  static Future<void> getTaskDependencies({
    required BuildContext context,
    required String taskId,
    required Function(
      List<Dependency> predecessors,
      List<Dependency> successors,
    )
    onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/task/$taskId/dependencies',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final predecessors = List<Dependency>.from(
              (data['predecessors'] as List? ?? []).map(
                (d) => Dependency.fromMap(d),
              ),
            );
            final successors = List<Dependency>.from(
              (data['successors'] as List? ?? []).map(
                (d) => Dependency.fromMap(d),
              ),
            );
            onSuccess(predecessors, successors);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Preview dependency impact
  static Future<void> previewDependencyImpact({
    required BuildContext context,
    required String predecessorId,
    required String successorId,
    required String projectId,
    required Function(List<Map<String, dynamic>>) onSuccess,
  }) async {
    try {
      final body = {
        'predecessorId': predecessorId,
        'successorId': successorId,
        'projectId': projectId,
      };

      final response = await ApiClient.post(
        url: '$uri/api/dependency/preview',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final impactedTasks = List<Map<String, dynamic>>.from(
              (data['impactedTasks'] as List? ?? []).map(
                (t) => {
                  'taskId': t['taskId']?.toString() ?? '',
                  'taskTitle': t['taskTitle']?.toString() ?? '',
                  'shiftDays': t['shiftDays']?.toInt() ?? 0,
                },
              ),
            );
            onSuccess(impactedTasks);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Lấy violations của task
  static Future<void> getTaskViolations({
    required BuildContext context,
    required String taskId,
    required Function(DependencyViolation?, List<Task>) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/task/$taskId/violations',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final parsedViolation = data['violation'] != null
                ? DependencyViolation.fromMap(data['violation'])
                : null;
            final criticalPredecessors = data['criticalPredecessors'] != null
                ? List<Task>.from(
                    (data['criticalPredecessors'] as List).map(
                      (t) => Task.fromMap(t as Map<String, dynamic>),
                    ),
                  )
                : <Task>[];
            final violation = parsedViolation != null
                ? DependencyViolation(
                    taskId: parsedViolation.taskId,
                    currentStart: parsedViolation.currentStart,
                    requiredStart: parsedViolation.requiredStart,
                    gap: parsedViolation.gap,
                    criticalPredecessors:
                        parsedViolation.criticalPredecessors.isNotEmpty
                        ? parsedViolation.criticalPredecessors
                        : criticalPredecessors,
                  )
                : null;
            final unfinishedPredecessors =
                data['unfinishedPredecessors'] != null
                ? List<Task>.from(
                    (data['unfinishedPredecessors'] as List).map(
                      (t) => Task.fromMap(t as Map<String, dynamic>),
                    ),
                  )
                : <Task>[];
            onSuccess(violation, unfinishedPredecessors);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }
}
