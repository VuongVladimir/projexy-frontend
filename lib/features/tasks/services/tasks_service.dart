import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/models/task.dart';

class TasksService {
  // Không cần _getAccessToken nữa vì ApiClient tự xử lý

  // Lấy danh sách tasks của project
  static Future<void> getProjectTasks({
    required BuildContext context,
    required String projectId,
    String? parentTaskId,
    bool includeSubtasks = false,
    String? status,
    String? assignedTo,
    required Function(List<Task>) onSuccess,
  }) async {
    try {
      // Xây dựng query parameters
      Map<String, String> queryParams = {
        'includeSubtasks': includeSubtasks.toString(),
      };
      
      // Luôn gửi parentTaskId, dùng 'null' nếu không có để lấy root tasks
      queryParams['parentTaskId'] = parentTaskId ?? 'null';
      if (status != null) queryParams['status'] = status;
      if (assignedTo != null) queryParams['assignedTo'] = assignedTo;

      final response = await ApiClient.get(
        url: '$uri/api/project/$projectId/tasks',
        queryParams: queryParams,
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final responseBody = response.body;
            if (responseBody.isEmpty) {
              onSuccess([]);
              return;
            }
            
            final List<dynamic> taskData = json.decode(responseBody);
            final tasks = taskData.map((json) {
              if (json == null) return null;
              return Task.fromMap(json as Map<String, dynamic>);
            }).where((task) => task != null).cast<Task>().toList();
            onSuccess(tasks);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Lấy chi tiết task
  static Future<void> getTaskDetails({
    required BuildContext context,
    required String taskId,
    required Function(Task) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/task/$taskId',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final responseBody = response.body;
            if (responseBody.isEmpty) {
              throw Exception('Empty response body');
            }
            
            final taskData = json.decode(responseBody);
            if (taskData == null) {
              throw Exception('Task data is null');
            }
            
            final task = Task.fromMap(taskData as Map<String, dynamic>);
            onSuccess(task);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Tạo task mới (không bao gồm assignedTo - dùng API riêng)
  static Future<void> createTask({
    required BuildContext context,
    required String title,
    String? description,
    required String projectId,
    String? parentTaskId,
    String priority = 'medium',
    int weight = 1,
    DateTime? dueDate,
    required Function(Task) onSuccess,
  }) async {
    try {
      final body = {
        'title': title,
        'description': description,
        'projectId': projectId,
        'parentTaskId': parentTaskId,
        'priority': priority,
        'weight': weight,
        'dueDate': dueDate?.toIso8601String(),
      };

      final response = await ApiClient.post(
        url: '$uri/api/task/create',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final responseBody = response.body;
            if (responseBody.isEmpty) {
              throw Exception('Empty response body');
            }
            
            final taskData = json.decode(responseBody);
            if (taskData == null) {
              throw Exception('Task data is null');
            }
            
            final task = Task.fromMap(taskData as Map<String, dynamic>);
            //showSnackBar(context, 'Tạo công việc thành công!');
            onSuccess(task);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Cập nhật task (không bao gồm assignedTo - dùng API riêng)
  static Future<void> updateTask({
    required BuildContext context,
    required String taskId,
    String? title,
    String? description,
    String? status,
    String? priority,
    int? weight,
    DateTime? dueDate,
    required VoidCallback onSuccess,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (status != null) body['status'] = status;
      if (priority != null) body['priority'] = priority;
      if (weight != null) body['weight'] = weight;
      if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();

      final response = await ApiClient.put(
        url: '$uri/api/task/$taskId',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            //showSnackBar(context, 'Cập nhật công việc thành công!');
            onSuccess();
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Xóa task
  static Future<void> deleteTask({
    required BuildContext context,
    required String taskId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.delete(
        url: '$uri/api/task/$taskId',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            //showSnackBar(context, 'Xóa công việc thành công!');
            onSuccess();
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Assign/Unassign users cho task (RBAC)
  static Future<void> assignTask({
    required BuildContext context,
    required String taskId,
    required List<String> assignedTo,
    required VoidCallback onSuccess,
  }) async {
    try {
      final body = {
        'assignedTo': assignedTo,
      };

      final response = await ApiClient.put(
        url: '$uri/api/task/$taskId/assign',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            onSuccess();
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Mark task as complete/incomplete (RBAC)
  static Future<void> markCompleteTask({
    required BuildContext context,
    required String taskId,
    required bool isCompleted,
    required VoidCallback onSuccess,
  }) async {
    try {
      final body = {
        'isCompleted': isCompleted,
      };

      final response = await ApiClient.put(
        url: '$uri/api/task/$taskId/mark-complete',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            onSuccess();
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Lấy tasks được assign cho user hiện tại
  static Future<void> getMyTasks({
    required BuildContext context,
    String? status,
    String? priority,
    String? projectId,
    required Function(List<Task>) onSuccess,
  }) async {
    try {
      // Xây dựng query parameters
      Map<String, String> queryParams = {};
      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;
      if (projectId != null) queryParams['projectId'] = projectId;

      final response = await ApiClient.get(
        url: '$uri/api/my-tasks',
        queryParams: queryParams,
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final responseBody = response.body;
            if (responseBody.isEmpty) {
              onSuccess([]);
              return;
            }
            
            final List<dynamic> taskData = json.decode(responseBody);
            final tasks = taskData.map((json) {
              if (json == null) return null;
              return Task.fromMap(json as Map<String, dynamic>);
            }).where((task) => task != null).cast<Task>().toList();
            onSuccess(tasks);
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