import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/features/account/screens/payment_history_screen.dart';
import 'package:frontend/features/notifications/services/notification_service.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _isInitializing = false;
  static String? _currentUserId;

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  static StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  static BuildContext? _navigatorContext;

  /// Initialize FCM
  static Future<void> initialize(BuildContext context, {String? userId}) async {
    debugPrint(
      '🔔 [FCMService] initialize called, userId=$userId, _initialized=$_initialized, _isInitializing=$_isInitializing',
    );

    if (_isInitializing) {
      debugPrint('⚠️ FCM is already initializing. Skipping duplicate call.');
      return;
    }

    if (_currentUserId != null && userId != null && _currentUserId != userId) {
      debugPrint(
        '⚠️ User changed from $_currentUserId to $userId. Resetting FCM.',
      );
      _initialized = false;
      _currentUserId = userId;
    }

    if (_initialized) {
      debugPrint(
        '🔔 [FCMService] Already initialized for user $_currentUserId, skipping',
      );
      return;
    }

    _isInitializing = true;
    _initialized = true;
    _navigatorContext = context;
    if (userId != null) {
      _currentUserId = userId;
    }

    try {
      // Initialize local notifications for foreground display
      await _initLocalNotifications();

      // Request permission
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('✅ User granted provisional permission');
      } else {
        debugPrint('❌ User declined notification permission');
        _isInitializing = false;
        return;
      }

      // Get and save FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint(
          '✅ FCM Token obtained: ${token.substring(0, 20)}...',
        );
        await NotificationService.saveFCMToken(
          token: token,
          deviceId: await _getDeviceId(),
          platform: _getPlatform(),
        );
      } else {
        debugPrint('❌ FCM Token is null!');
      }

      // Listen for token refresh
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((
        newToken,
      ) async {
        debugPrint('🔄 FCM Token refreshed');
        await NotificationService.saveFCMToken(
          token: newToken,
          deviceId: await _getDeviceId(),
          platform: _getPlatform(),
        );
      });

      // Handle foreground messages - show system notification
      _foregroundMessageSubscription?.cancel();
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
        RemoteMessage message,
      ) {
        debugPrint('📬 FCM: Foreground message received: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      // Handle notification tap when app is in background
      _messageOpenedSubscription?.cancel();
      _messageOpenedSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen((
            RemoteMessage message,
          ) {
        debugPrint('📱 FCM: App opened from notification');
        _handleNotificationTap(context, message);
      });

      // Check if app was launched from a notification
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(context, initialMessage);
      }

      _isInitializing = false;
      debugPrint('✅ [FCMService] Initialization complete');
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
      _initialized = false;
      _isInitializing = false;
    }
  }

  /// Initialize flutter_local_notifications
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('📱 Local notification tapped: ${response.payload}');
        if (_navigatorContext != null && _navigatorContext!.mounted) {
          _handleNotificationTapFromPayload(_navigatorContext!, response.payload);
        }
      },
    );

    // Create Android notification channel
    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'projexy_notifications',
        'Projexy Notifications',
        description: 'Notifications from Projexy app',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      debugPrint('✅ Android notification channel created: projexy_notifications');
    }
  }

  /// Show local system notification when app is in foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'projexy_notifications',
      'Projexy Notifications',
      channelDescription: 'Notifications from Projexy app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Encode type into payload for navigation on tap
    final payload = message.data['type'] ?? '';

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: payload,
    );

    debugPrint('✅ Local notification shown: ${notification.title}');
  }

  /// Handle notification tap from local notification payload
  static void _handleNotificationTapFromPayload(
    BuildContext context,
    String? payload,
  ) {
    if (payload == null || payload.isEmpty) {
      Navigator.pushNamed(context, '/notifications');
      return;
    }

    switch (payload) {
      case 'project_invitation':
      case 'project_overdue':
      case 'project_completed':
        Navigator.pushNamed(context, '/notifications');
        break;
      case 'premium_upgraded':
      case 'premium_expired':
        Navigator.pushNamed(context, PaymentHistoryScreen.routeName);
        break;
      default:
        Navigator.pushNamed(context, '/notifications');
    }
  }

  static Future<String> _getDeviceId() async {
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

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

  /// Handle notification tap from FCM RemoteMessage
  static void _handleNotificationTap(
    BuildContext context,
    RemoteMessage message,
  ) {
    debugPrint('Notification tapped: ${message.data}');

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
  static Future<void> unregister() async {
    try {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      await _foregroundMessageSubscription?.cancel();
      _foregroundMessageSubscription = null;
      await _messageOpenedSubscription?.cancel();
      _messageOpenedSubscription = null;

      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await NotificationService.deleteFCMToken(token: token);
      }
      await _firebaseMessaging.deleteToken();

      _initialized = false;
      _isInitializing = false;
      _currentUserId = null;
      _navigatorContext = null;

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
