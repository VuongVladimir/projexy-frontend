import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/models/activity_log.dart';

class ActivityLogService {
  /// Lấy activity logs của một Task (hiển thị trong Task Detail)
  /// Hỗ trợ pagination: page, limit (mặc định 5)
  static Future<void> getTaskActivity({
    required BuildContext context,
    required String taskId,
    int page = 1,
    int limit = 5,
    String sort = 'newest',
    required Function(List<ActivityLog> logs, bool hasMore) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/task/$taskId/activity',
        queryParams: {
          'page': page.toString(),
          'limit': limit.toString(),
          'sort': sort,
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

            final Map<String, dynamic> data = json.decode(responseBody);
            final List<dynamic> logsData = data['logs'] ?? [];
            final bool hasMore = data['hasMore'] ?? false;

            final logs = logsData
                .map((json) {
                  if (json == null) return null;
                  return ActivityLog.fromMap(json as Map<String, dynamic>);
                })
                .where((log) => log != null)
                .cast<ActivityLog>()
                .toList();

            onSuccess(logs, hasMore);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Error: ${e.toString()}');
      }
    }
  }

  /// Lấy activity logs của một Project (hiển thị trong Project Detail)
  /// Chỉ trả về project-level actions
  /// Hỗ trợ pagination: page, limit (mặc định 5)
  static Future<void> getProjectActivity({
    required BuildContext context,
    required String projectId,
    int page = 1,
    int limit = 5,
    String sort = 'newest',
    required Function(List<ActivityLog> logs, bool hasMore) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/project/$projectId/activity',
        queryParams: {
          'page': page.toString(),
          'limit': limit.toString(),
          'sort': sort,
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

            final Map<String, dynamic> data = json.decode(responseBody);
            final List<dynamic> logsData = data['logs'] ?? [];
            final bool hasMore = data['hasMore'] ?? false;

            final logs = logsData
                .map((json) {
                  if (json == null) return null;
                  return ActivityLog.fromMap(json as Map<String, dynamic>);
                })
                .where((log) => log != null)
                .cast<ActivityLog>()
                .toList();

            onSuccess(logs, hasMore);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Error: ${e.toString()}');
      }
    }
  }
}
