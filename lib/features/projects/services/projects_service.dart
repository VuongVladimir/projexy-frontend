import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/models/project.dart';

class ProjectsService {
  // Không cần _getAccessToken nữa vì ApiClient tự xử lý

  // Lấy danh sách projects
  static Future<void> getProjects({
    required BuildContext context,
    required Function(Map<String, dynamic>) onSuccess,
    int page = 1,
    int limit = 10,
    String? status,
    String? priority,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      // Xây dựng query parameters
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (priority != null && priority.isNotEmpty) queryParams['priority'] = priority;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
      if (sortOrder != null && sortOrder.isNotEmpty) queryParams['sortOrder'] = sortOrder;

      final response = await ApiClient.get(
        url: '$uri/api/projects',
        queryParams: queryParams,
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final responseBody = response.body;
            if (responseBody.isEmpty) {
              onSuccess({'projects': [], 'total': 0, 'totalPages': 0, 'currentPage': 1});
              return;
            }
            
            final data = json.decode(responseBody);
            if (data == null) {
              throw Exception('Response data is null');
            }
            
            onSuccess(data);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Tạo project mới
  static Future<void> createProject({
    required BuildContext context,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String priority,
    required List<String> tags,
    required List<String> members,
    required Function(String projectId) onSuccess,
  }) async {
    try {
      final body = {
        'title': title,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'priority': priority,
        'tags': tags,
        'members': members,
      };

      final response = await ApiClient.post(
        url: '$uri/api/project/create',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final projectId = data['_id'] ?? '';
            //showSnackBar(context, 'Tạo dự án thành công!');
            onSuccess(projectId);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Cập nhật project
  static Future<void> updateProject({
    required BuildContext context,
    required String projectId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? priority,
    List<String>? tags,
    List<String>? members,
    int? progress,
    required VoidCallback onSuccess,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (startDate != null) body['startDate'] = startDate.toIso8601String();
      if (endDate != null) body['endDate'] = endDate.toIso8601String();
      if (status != null) body['status'] = status;
      if (priority != null) body['priority'] = priority;
      if (tags != null) body['tags'] = tags;
      if (members != null) body['members'] = members;
      if (progress != null) body['progress'] = progress;

      final response = await ApiClient.put(
        url: '$uri/api/project/$projectId',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            //showSnackBar(context, 'Cập nhật dự án thành công!');
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

  // Xóa project
  static Future<void> deleteProject({
    required BuildContext context,
    required String projectId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.delete(
        url: '${uri}/api/project/$projectId',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            //showSnackBar(context, 'Xóa dự án thành công!');
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

  // Rời khỏi project
  static Future<void> leaveProject({
    required BuildContext context,
    required String projectId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.post(
        url: '${uri}/api/project/$projectId/leave',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            showSnackBar(context, tr('left_project'));
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

  // Lấy chi tiết project
  static Future<void> getProjectDetails({
    required BuildContext context,
    required String projectId,
    required Function(Project) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '${uri}/api/project/$projectId',
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
            
            final projectData = json.decode(responseBody);
            if (projectData == null) {
              throw Exception('Project data is null');
            }
            
            final project = Project.fromMap(projectData as Map<String, dynamic>);
            onSuccess(project);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Thêm member vào project
  static Future<void> addMemberToProject({
    required BuildContext context,
    required String projectId,
    required String userId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.post(
        url: '${uri}/api/project/$projectId/add-member',
        body: json.encode({'userId': userId}),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            //showSnackBar(context, 'Thêm thành viên thành công!');
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

  // Xóa member khỏi project
  static Future<void> removeMemberFromProject({
    required BuildContext context,
    required String projectId,
    required String userId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.delete(
        url: '${uri}/api/project/$projectId/remove-member/$userId',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            //showSnackBar(context, 'Xóa thành viên thành công!');
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

  // Cập nhật role cho member (RBAC)
  static Future<void> updateMemberRole({
    required BuildContext context,
    required String projectId,
    required String userId,
    required String role,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.put(
        url: '${uri}/api/project/$projectId/member/$userId/role',
        body: json.encode({'role': role}),
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

  // Cập nhật permissions thủ công cho member (chuyển sang Custom Role)
  static Future<void> updateMemberPermissions({
    required BuildContext context,
    required String projectId,
    required String userId,
    required Map<String, bool> permissions,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.put(
        url: '${uri}/api/project/$projectId/member/$userId/permissions',
        body: json.encode({'permissions': permissions}),
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

  // Shift project
  static Future<void> shiftProject({
    required BuildContext context,
    required String projectId,
    required int deltaDays,
    required VoidCallback onSuccess,
  }) async {
    try {
      final body = {'deltaDays': deltaDays};
      
      final response = await ApiClient.post(
        url: '$uri/api/project/$projectId/shift',
        body: json.encode(body),
      );
      
      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: onSuccess,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }
}