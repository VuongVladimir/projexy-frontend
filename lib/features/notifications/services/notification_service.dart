import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/models/notification.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  // Lấy danh sách notifications
  static Future<void> getNotifications({
    required BuildContext context,
    String? type,
    bool? isRead,
    int limit = 50,
    int skip = 0,
    required Function(List<AppNotification>, int, int, bool) onSuccess,
  }) async {
    try {
      Map<String, String> queryParams = {
        'limit': limit.toString(),
        'skip': skip.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (isRead != null) queryParams['isRead'] = isRead.toString();

      final response = await ApiClient.get(
        url: '$uri/api/notifications',
        queryParams: queryParams,
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final List<AppNotification> notifications =
                (data['notifications'] as List)
                    .map((n) => AppNotification.fromMap(n))
                    .toList();
            final int total = data['total'];
            final int unreadCount = data['unreadCount'];
            final bool hasMore = data['hasMore'];

            onSuccess(notifications, total, unreadCount, hasMore);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Lấy số lượng thông báo chưa đọc
  static Future<int> getUnreadCount({required BuildContext context}) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/notifications/unread-count',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unreadCount'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error getting unread count: $e');
    }
    return 0;
  }

  // Đánh dấu notification là đã đọc
  static Future<void> markAsRead({
    required BuildContext context,
    required String notificationId,
    required Function(int) onSuccess,
  }) async {
    try {
      final response = await ApiClient.patch(
        url: '$uri/api/notifications/$notificationId/read',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final int unreadCount = data['unreadCount'];
            onSuccess(unreadCount);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Đánh dấu tất cả là đã đọc
  static Future<void> markAllAsRead({
    required BuildContext context,
    required Function() onSuccess,
  }) async {
    try {
      final response = await ApiClient.patch(
        url: '$uri/api/notifications/read-all',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            showSnackBar(context, 'Đã đánh dấu tất cả thông báo là đã đọc!');
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

  // Xóa notification
  static Future<void> deleteNotification({
    required BuildContext context,
    required String notificationId,
    required Function(int) onSuccess,
  }) async {
    try {
      final response = await ApiClient.delete(
        url: '$uri/api/notifications/$notificationId',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final int unreadCount = data['unreadCount'];
            showSnackBar(context, 'Đã xóa thông báo!');
            onSuccess(unreadCount);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Xóa tất cả notifications đã đọc
  static Future<void> clearReadNotifications({
    required BuildContext context,
    required Function() onSuccess,
  }) async {
    try {
      final response = await ApiClient.delete(
        url: '$uri/api/notifications/clear-read',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            showSnackBar(context, 'Đã xóa tất cả thông báo đã đọc!');
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

  // Gửi lời mời vào project (đã gộp vào notification API)
  static Future<void> sendProjectInvitation({
    required BuildContext context,
    required String email,
    required String projectId,
    String? message,
    required VoidCallback onSuccess,
  }) async {
    final result = await sendProjectInvitationWithResult(
      context: context,
      email: email,
      projectId: projectId,
      message: message,
      showErrorSnackBar: true,
    );

    if (result['success'] == true) {
      onSuccess();
    }
  }

  static Future<Map<String, dynamic>> sendProjectInvitationWithResult({
    required BuildContext context,
    required String email,
    required String projectId,
    String? message,
    bool showErrorSnackBar = false,
  }) async {
    try {
      http.Response? response;
      const int maxRetry = 1;

      for (int attempt = 0; attempt <= maxRetry; attempt++) {
        response = await ApiClient.post(
          url: '$uri/api/notifications/project-invitations/send',
          body: json.encode({
            'email': email,
            'projectId': projectId,
            'message': message ?? '',
          }),
        );

        if (response.statusCode == 200) {
          return {'success': true, 'email': email, 'message': ''};
        }

        final isTransientServerError =
            response.statusCode == 502 ||
            response.statusCode == 503 ||
            response.statusCode == 504;
        if (!isTransientServerError || attempt == maxRetry) {
          break;
        }

        await Future.delayed(const Duration(milliseconds: 700));
      }

      if (response == null) {
        return {
          'success': false,
          'email': email,
          'message': 'Không thể gửi lời mời do lỗi mạng.',
        };
      }

      final errorMessage = _extractInvitationErrorMessage(response);

      if (context.mounted && showErrorSnackBar) {
        showSnackBar(context, errorMessage);
      }

      return {'success': false, 'email': email, 'message': errorMessage};
    } catch (e) {
      if (context.mounted) {
        final errorMessage = 'Lỗi: ${e.toString()}';
        if (showErrorSnackBar) {
          showSnackBar(context, errorMessage);
        }

        return {'success': false, 'email': email, 'message': errorMessage};
      }

      return {
        'success': false,
        'email': email,
        'message': 'Lỗi không xác định',
      };
    }
  }

  static String _extractInvitationErrorMessage(http.Response response) {
    final statusCode = response.statusCode;
    if (statusCode == 504) {
      return 'Máy chủ phản hồi quá chậm khi gửi lời mời. Vui lòng thử lại sau ít phút.';
    }
    if (statusCode == 502 || statusCode == 503) {
      return 'Dịch vụ gửi lời mời đang tạm thời gián đoạn. Vui lòng thử lại sau.';
    }
    if (statusCode >= 500) {
      return 'Hệ thống đang gặp sự cố khi gửi lời mời. Vui lòng thử lại sau.';
    }

    String errorMessage = 'Không thể gửi lời mời';
    try {
      final responseBody = response.body;
      if (responseBody.isNotEmpty) {
        final decoded = json.decode(responseBody);
        if (decoded is Map<String, dynamic>) {
          errorMessage =
              decoded['msg']?.toString() ??
              decoded['error']?.toString() ??
              errorMessage;
        } else {
          errorMessage = responseBody;
        }
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        errorMessage = response.body;
      }
    }

    final lowerError = errorMessage.toLowerCase();
    final isHtmlPayload =
        (response.headers['content-type'] ?? '').contains('text/html') ||
        lowerError.contains('<html') ||
        lowerError.contains('<body');

    if (isHtmlPayload) {
      return 'Không thể gửi lời mời vào lúc này. Vui lòng thử lại sau.';
    }

    return errorMessage.trim();
  }

  static Future<void> acceptProjectInvitation({
    required BuildContext context,
    required String notificationId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.post(
        url: '$uri/api/notifications/$notificationId/project-invitation/accept',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            showSnackBar(context, 'Chấp nhận lời mời thành công!');
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

  static Future<void> declineProjectInvitation({
    required BuildContext context,
    required String notificationId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.post(
        url:
            '$uri/api/notifications/$notificationId/project-invitation/decline',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            showSnackBar(context, 'Đã từ chối lời mời!');
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

  // Lấy notification settings
  static Future<void> getNotificationSettings({
    required BuildContext context,
    required Function(NotificationSettings) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/user/notification-settings',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final settings = NotificationSettings.fromMap(data);
            onSuccess(settings);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Cập nhật notification settings
  static Future<void> updateNotificationSettings({
    required BuildContext context,
    bool? pushNotifications,
    bool? emailNotifications,
    NotificationPreferences? preferences,
    required Function() onSuccess,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (pushNotifications != null) {
        body['pushNotifications'] = pushNotifications;
      }
      if (emailNotifications != null) {
        body['emailNotifications'] = emailNotifications;
      }
      if (preferences != null) {
        body['preferences'] = preferences.toMap();
      }

      final response = await ApiClient.patch(
        url: '$uri/api/user/notification-settings',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            showSnackBar(context, 'Đã cập nhật cài đặt thông báo!');
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

  // Lưu FCM token (không cần context vì ApiClient dùng TokenManager)
  static Future<void> saveFCMToken({
    required String token,
    String? deviceId,
    String? platform,
  }) async {
    try {
      debugPrint(
        '📤 [saveFCMToken] Sending token to backend: ${token.substring(0, 20)}..., platform=$platform',
      );
      final response = await ApiClient.post(
        url: '$uri/api/user/fcm-token',
        body: json.encode({
          'token': token,
          'deviceId': deviceId,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [saveFCMToken] Token saved successfully');
      } else {
        debugPrint(
          '❌ [saveFCMToken] Failed: status=${response.statusCode}, body=${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [saveFCMToken] Error: $e');
    }
  }

  // Xóa FCM token (không cần context vì ApiClient dùng TokenManager)
  static Future<void> deleteFCMToken({
    required String token,
  }) async {
    try {
      await ApiClient.delete(
        url: '$uri/api/user/fcm-token',
        body: json.encode({'token': token}),
      );
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}
