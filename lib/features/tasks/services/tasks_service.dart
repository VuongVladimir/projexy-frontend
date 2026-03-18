import 'dart:convert';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/features/tasks/services/task_widgets_service.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/models/comment.dart';

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
            final tasks = taskData
                .map((json) {
                  if (json == null) return null;
                  return Task.fromMap(json as Map<String, dynamic>);
                })
                .where((task) => task != null)
                .cast<Task>()
                .toList();
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

  static Future<void> getProjectTasksByIds({
    required BuildContext context,
    required String projectId,
    required List<String> taskIds,
    required Function(List<Task>) onSuccess,
  }) async {
    if (taskIds.isEmpty) {
      onSuccess([]);
      return;
    }

    await getProjectTasks(
      context: context,
      projectId: projectId,
      parentTaskId: null,
      includeSubtasks: true,
      onSuccess: (tasks) {
        final idSet = taskIds.toSet();
        final filtered = tasks
            .where((task) => idSet.contains(task.id))
            .toList();
        onSuccess(filtered);
      },
    );
  }

  // Lấy chi tiết task
  static Future<void> getTaskDetails({
    required BuildContext context,
    required String taskId,
    required Function(Task) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(url: '$uri/api/task/$taskId');

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
    DateTime? startDate,
    DateTime? endDate,
    String schedulingMode = 'AUTO',
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
        'startDate': startDate != null ? formatDateForApi(startDate) : null,
        'endDate': endDate != null ? formatDateForApi(endDate) : null,
        'schedulingMode': schedulingMode,
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
            TaskWidgetsService.refreshWidgetsData();
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
    DateTime? startDate,
    DateTime? endDate,
    String? schedulingMode,
    required VoidCallback onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (status != null) body['status'] = status;
      if (priority != null) body['priority'] = priority;
      if (weight != null) body['weight'] = weight;
      if (startDate != null) body['startDate'] = formatDateForApi(startDate);
      if (endDate != null) body['endDate'] = formatDateForApi(endDate);
      if (schedulingMode != null) body['schedulingMode'] = schedulingMode;

      final response = await ApiClient.put(
        url: '$uri/api/task/$taskId',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            onSuccess();
            TaskWidgetsService.refreshWidgetsData();
          },
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

  // Xóa task
  static Future<void> deleteTask({
    required BuildContext context,
    required String taskId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.delete(url: '$uri/api/task/$taskId');

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            //showSnackBar(context, 'Xóa công việc thành công!');
            onSuccess();
            TaskWidgetsService.refreshWidgetsData();
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
    VoidCallback? onError,
  }) async {
    try {
      final body = {'assignedTo': assignedTo};

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
            TaskWidgetsService.refreshWidgetsData();
          },
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

  // Mark task as complete/incomplete (RBAC)
  static Future<void> markCompleteTask({
    required BuildContext context,
    required String taskId,
    required bool isCompleted,
    required VoidCallback onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      final body = {'isCompleted': isCompleted};

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
            TaskWidgetsService.refreshWidgetsData();
          },
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
            final tasks = taskData
                .map((json) {
                  if (json == null) return null;
                  return Task.fromMap(json as Map<String, dynamic>);
                })
                .where((task) => task != null)
                .cast<Task>()
                .toList();
            onSuccess(tasks);
            TaskWidgetsService.syncFromTasks(tasks);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  static Future<void> getMyTasksByIds({
    required BuildContext context,
    required List<String> taskIds,
    required Function(List<Task>) onSuccess,
  }) async {
    if (taskIds.isEmpty) {
      onSuccess([]);
      return;
    }

    await getMyTasks(
      context: context,
      onSuccess: (tasks) {
        final idSet = taskIds.toSet();
        final filtered = tasks
            .where((task) => idSet.contains(task.id))
            .toList();
        onSuccess(filtered);
      },
    );
  }

  // Shift task/subtree
  static Future<void> shiftTask({
    required BuildContext context,
    required String taskId,
    required int deltaDays,
    required VoidCallback onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      final body = {'deltaDays': deltaDays};

      final response = await ApiClient.post(
        url: '$uri/api/task/$taskId/shift',
        body: json.encode(body),
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

  // Upload attachment to Cloudinary and add to task
  static Future<void> addAttachment({
    required BuildContext context,
    required String taskId,
    dynamic fileBytes, // Uint8List for web or when withData is true
    String? filePath, // File path for mobile
    required String fileName,
    required String fileExtension,
    required int fileSize,
    required VoidCallback onSuccess,
  }) async {
    try {
      // Determine file type and folder
      final fileType = getFileTypeFromExtension(fileExtension);
      final folder =
          'task/$taskId/${fileType}s'; // tasks/{taskId}/images, documents, videos

      // Upload to Cloudinary
      final cloudinary = CloudinaryPublic('dkwp4prjj', 'projexy_preset');
      CloudinaryResponse response;

      if (kIsWeb || fileBytes != null) {
        // Web hoặc khi có bytes data
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            fileBytes,
            identifier: '${fileName}_${DateTime.now().millisecondsSinceEpoch}',
            folder: folder,
            resourceType: fileType == 'video'
                ? CloudinaryResourceType.Video
                : CloudinaryResourceType.Auto,
          ),
        );
      } else if (filePath != null) {
        // Mobile với file path
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            filePath,
            folder: folder,
            resourceType: fileType == 'video'
                ? CloudinaryResourceType.Video
                : CloudinaryResourceType.Auto,
          ),
        );
      } else {
        throw Exception('No file data provided');
      }

      final fileUrl = response.secureUrl;

      // Add attachment to task via API
      final body = {
        'url': fileUrl,
        'fileName': fileName,
        'fileType': fileType,
        'fileSize': fileSize,
      };

      final apiResponse = await ApiClient.post(
        url: '$uri/api/task/$taskId/attachments',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: apiResponse,
          context: context,
          onSuccess: () {
            showSnackBar(context, 'Đã thêm tệp đính kèm!');
            onSuccess();
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi khi tải lên: ${e.toString()}');
      }
    }
  }

  // Delete attachment from task
  static Future<void> deleteAttachment({
    required BuildContext context,
    required String taskId,
    required String attachmentId,
    required VoidCallback onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      final response = await ApiClient.delete(
        url: '$uri/api/task/$taskId/attachments/$attachmentId',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            showSnackBar(context, 'Đã xóa tệp đính kèm!');
            onSuccess();
          },
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

  // ==================== COMMENT METHODS ====================

  /// Lấy danh sách comments của task
  static Future<void> getComments({
    required BuildContext context,
    required String taskId,
    String sort = 'newest',
    int page = 1,
    int limit = 5,
    required Function(List<TaskComment>, bool hasMore) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/task/$taskId/comments',
        queryParams: {
          'sort': sort,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final responseBody = response.body;
            if (responseBody.isEmpty) {
              onSuccess([], false);
              return;
            }

            final dynamic payload = json.decode(responseBody);
            final List<dynamic> commentData = payload is Map<String, dynamic>
                ? (payload['comments'] as List<dynamic>? ?? [])
                : (payload as List<dynamic>);
            final comments = commentData
                .map(
                  (data) => TaskComment.fromMap(data as Map<String, dynamic>),
                )
                .toList();
            final hasMore = payload is Map<String, dynamic>
                ? payload['hasMore'] == true
                : false;
            onSuccess(comments, hasMore);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  /// Thêm comment mới
  static Future<void> addComment({
    required BuildContext context,
    required String taskId,
    required String content,
    String? parentCommentId,
    required Function(TaskComment) onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      final body = {
        'content': content,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      };

      final response = await ApiClient.post(
        url: '$uri/api/task/$taskId/comments',
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

            final commentData = json.decode(responseBody);
            final comment = TaskComment.fromMap(
              commentData as Map<String, dynamic>,
            );
            onSuccess(comment);
          },
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

  /// Cập nhật comment
  static Future<void> updateComment({
    required BuildContext context,
    required String taskId,
    required String commentId,
    required String content,
    required Function(TaskComment) onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      final body = {'content': content};

      final response = await ApiClient.put(
        url: '$uri/api/task/$taskId/comments/$commentId',
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

            final commentData = json.decode(responseBody);
            final comment = TaskComment.fromMap(
              commentData as Map<String, dynamic>,
            );
            onSuccess(comment);
          },
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

  /// Xóa comment
  static Future<void> deleteComment({
    required BuildContext context,
    required String taskId,
    required String commentId,
    required VoidCallback onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      final response = await ApiClient.delete(
        url: '$uri/api/task/$taskId/comments/$commentId',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            onSuccess();
          },
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

  /// Toggle reaction trên comment
  static Future<void> toggleReaction({
    required BuildContext context,
    required String taskId,
    required String commentId,
    required String emoji,
    required Function(TaskComment) onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      final body = {'emoji': emoji};

      final response = await ApiClient.post(
        url: '$uri/api/task/$taskId/comments/$commentId/reactions',
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

            final commentData = json.decode(responseBody);
            final comment = TaskComment.fromMap(
              commentData as Map<String, dynamic>,
            );
            onSuccess(comment);
          },
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

  /// Lấy chi tiết reactions của comment (grouped theo emoji)
  static Future<void> getReactionDetails({
    required BuildContext context,
    required String taskId,
    required String commentId,
    required Function(ReactionsByEmoji) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/task/$taskId/comments/$commentId/reactions',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final responseBody = response.body;
            if (responseBody.isEmpty) {
              onSuccess(ReactionsByEmoji(total: 0, byEmoji: {}));
              return;
            }

            final data = json.decode(responseBody);
            final reactions = ReactionsByEmoji.fromMap(
              data as Map<String, dynamic>,
            );
            onSuccess(reactions);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  /// Tìm kiếm members của project để gợi ý mention
  static Future<void> searchMembersForMention({
    required BuildContext context,
    required String projectId,
    required String query,
    int limit = 5,
    required Function(List<Map<String, dynamic>>) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/project/$projectId/members/search',
        queryParams: {'q': query, 'limit': limit.toString()},
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

            final List<dynamic> usersData = json.decode(responseBody);
            final users = usersData
                .map(
                  (u) => {
                    '_id': u['_id']?.toString() ?? '',
                    'name': u['name']?.toString() ?? '',
                    'email': u['email']?.toString() ?? '',
                    'avatar': u['avatar']?.toString() ?? '',
                    'avatarColor': u['avatarColor']?.toString() ?? '',
                  },
                )
                .toList();
            onSuccess(users);
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
