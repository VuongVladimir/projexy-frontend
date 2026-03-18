import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/models/notification.dart';

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
      final response = await ApiClient.post(
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

  // Lưu FCM token
  static Future<void> saveFCMToken({
    required BuildContext context,
    required String token,
    String? deviceId,
    String? platform,
  }) async {
    try {
      final response = await ApiClient.post(
        url: '$uri/api/user/fcm-token',
        body: json.encode({
          'token': token,
          'deviceId': deviceId,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token saved successfully');
      } else {
        debugPrint('Failed to save FCM token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Xóa FCM token
  static Future<void> deleteFCMToken({
    required BuildContext context,
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
