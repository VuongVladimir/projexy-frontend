import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/account/screens/payment_history_screen.dart';
import 'package:frontend/features/notifications/services/notification_service.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static bool _initialized = false;
  static bool _isInitializing = false;
  static String? _currentUserId; // Track current user

  // Stream subscriptions to properly cancel listeners
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  static StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  /// Initialize FCM
  static Future<void> initialize(BuildContext context, {String? userId}) async {
    // Nếu đang khởi tạo, bỏ qua
    if (_isInitializing) {
      debugPrint('⚠️ FCM is already initializing. Skipping duplicate call.');
      return;
    }

    // Nếu user ID thay đổi, reset initialization
    if (_currentUserId != null && userId != null && _currentUserId != userId) {
      debugPrint(
        '⚠️ User changed from $_currentUserId to $userId. Resetting FCM.',
      );
      _initialized = false;
      _currentUserId = userId;
    }

    // Nếu đã khởi tạo cho user hiện tại, bỏ qua
    if (_initialized) {
      return;
    }

    _isInitializing = true;
    _initialized = true;
    if (userId != null) {
      _currentUserId = userId;
    }

    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
        return;
      }

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('✅ FCM initialized successfully. Token obtained.');

        // Send token to backend
        if (context.mounted) {
          await NotificationService.saveFCMToken(
            context: context,
            token: token,
            deviceId: await _getDeviceId(),
            platform: _getPlatform(),
          );
        }
      }

      // Listen for token refresh - store subscription for cleanup
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((
        newToken,
      ) async {
        debugPrint('🔄 FCM Token refreshed');
        if (context.mounted) {
          await NotificationService.saveFCMToken(
            context: context,
            token: newToken,
            deviceId: await _getDeviceId(),
            platform: _getPlatform(),
          );
        }
      });

      // Handle foreground messages - store subscription for cleanup
      _foregroundMessageSubscription?.cancel();
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
        RemoteMessage message,
      ) {
        debugPrint('📬 FCM: Foreground message received');
        if (message.notification != null) {
          // Show in-app notification
          _showInAppNotification(context, message);
        }
      });

      // Handle background messages - store subscription for cleanup
      _messageOpenedSubscription?.cancel();
      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
        RemoteMessage message,
      ) {
        debugPrint('📱 FCM: App opened from notification');
        _handleNotificationTap(context, message);
      });

      // Check if app was launched from a notification
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(context, initialMessage);
      }

      _isInitializing = false;
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
      _initialized = false;
      _isInitializing = false;
    }
  }

  /// Get device ID (simplified version)
  static Future<String> _getDeviceId() async {
    // In a real app, you'd use device_info_plus or similar package
    // For now, return a placeholder
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get platform string
  static String _getPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isAndroid) {
      return 'android';
    }
    return 'unknown';
  }

  /// Show in-app notification when app is in foreground
  static void _showInAppNotification(
    BuildContext context,
    RemoteMessage message,
  ) {
    if (!context.mounted) return;

    final notification = message.notification;
    if (notification == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notification.title ?? 'Thông báo',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(notification.body ?? ''),
          ],
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () {
            _handleNotificationTap(context, message);
          },
        ),
      ),
    );
  }

  /// Handle notification tap
  static void _handleNotificationTap(
    BuildContext context,
    RemoteMessage message,
  ) {
    debugPrint('Notification tapped: ${message.data}');

    // Navigate based on notification type
    final data = message.data;
    final type = data['type'] as String?;

    if (!context.mounted) return;

    switch (type) {
      case 'project_invitation':
      case 'project_overdue':
      case 'project_completed':
        final projectId = data['projectId'] as String?;
        if (projectId != null) {
          Navigator.pushNamed(
            context,
            '/project-detail',
            arguments: {'projectId': projectId},
          );
        }
        break;
      case 'task_assigned':
      case 'task_due_today':
      case 'task_overdue':
      case 'task_completed':
        final taskId = data['taskId'] as String?;
        if (taskId != null) {
          Navigator.pushNamed(
            context,
            '/task-detail',
            arguments: {'taskId': taskId},
          );
        }
        break;
      case 'premium_upgraded':
      case 'premium_expired':
        Navigator.pushNamed(context, PaymentHistoryScreen.routeName);
        break;
      default:
        Navigator.pushNamed(context, '/notifications');
    }
  }

  /// Unregister FCM token (call when user logs out)
  static Future<void> unregister(BuildContext context) async {
    try {
      // Cancel all stream subscriptions first to prevent stale context issues
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      await _foregroundMessageSubscription?.cancel();
      _foregroundMessageSubscription = null;
      await _messageOpenedSubscription?.cancel();
      _messageOpenedSubscription = null;

      String? token = await _firebaseMessaging.getToken();
      if (token != null && context.mounted) {
        await NotificationService.deleteFCMToken(
          context: context,
          token: token,
        );
      }
      await _firebaseMessaging.deleteToken();

      // Reset initialization flags and user ID
      _initialized = false;
      _isInitializing = false;
      _currentUserId = null;

      debugPrint('✅ FCM token unregistered successfully');
    } catch (e) {
      debugPrint('❌ Error unregistering FCM: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
}
