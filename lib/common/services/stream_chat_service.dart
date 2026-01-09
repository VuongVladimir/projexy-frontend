import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class StreamChatService {
  static StreamChatClient? _client;
  static String? _currentUserId;
  static bool _isInitializing = false;
  static final ValueNotifier<StreamChatClient?> clientNotifier =
      ValueNotifier<StreamChatClient?>(null);

  // Singleton instance
  static StreamChatClient? get client => _client;

  /// Khởi tạo Stream Chat client và connect user
  static Future<void> initialize({
    required BuildContext context,
    required String userId,
  }) async {
    // Nếu đang khởi tạo, bỏ qua
    if (_isInitializing) {
      return;
    }

    try {
      _isInitializing = true;

      // Nếu có client nhưng user khác, disconnect trước
      if (_client != null &&
          _currentUserId != null &&
          _currentUserId != userId) {
        debugPrint('Disconnecting previous user: $_currentUserId');
        await disconnect();
        // Dispose client cũ để tạo client mới
        _client?.dispose();
        _client = null;
      }

      // Nếu đã có client và user đã connect với cùng userId
      if (_client != null && _currentUserId == userId) {
        // Kiểm tra connection status
        if (_client!.wsConnectionStatus == ConnectionStatus.connected) {
          _isInitializing = false;
          return;
        }
      }

      // Lấy Stream Chat token từ backend
      final response = await ApiClient.get(url: '$uri/api/stream-chat/token');

      if (response.statusCode != 200) {
        throw Exception('Failed to get Stream Chat token');
      }

      final data = json.decode(response.body);
      final apiKey = data['apiKey'] as String;
      final token = data['token'] as String;

      // Khởi tạo client mới
      _client = StreamChatClient(apiKey, logLevel: Level.INFO);
      clientNotifier.value = _client;

      // Connect user
      await _client!.connectUser(User(id: userId), token);
      _currentUserId = userId;
      debugPrint('✅ Stream Chat initialized successfully for user: $userId');
      clientNotifier.value = _client;

      _isInitializing = false;
    } catch (e) {
      _isInitializing = false;
      debugPrint('❌ Error initializing Stream Chat: $e');
      // Không hiển thị snackbar vì có thể gây phiền nhiễu
      // if (context.mounted) {
      //   showSnackBar(context, 'Lỗi khởi tạo chat: ${e.toString()}');
      // }
    }
  }

  /// Disconnect user khỏi Stream Chat
  static Future<void> disconnect() async {
    try {
      if (_client != null &&
          _client!.wsConnectionStatus == ConnectionStatus.connected) {
        await _client!.disconnectUser();
        _currentUserId = null;
        debugPrint('Stream Chat disconnected successfully');
      } else {
        _currentUserId = null;
        debugPrint('Stream Chat already disconnected');
      }
      clientNotifier.value = _client;
    } catch (e) {
      debugPrint('Error disconnecting Stream Chat: $e');
      _currentUserId = null;
      clientNotifier.value = _client;
    }
  }

  /// Dispose client (khi logout hoàn toàn)
  static Future<void> dispose() async {
    try {
      _isInitializing = false;
      await disconnect();
      _client?.dispose();
      _client = null;
      _currentUserId = null;
      debugPrint('Stream Chat disposed successfully');
      clientNotifier.value = _client;
    } catch (e) {
      debugPrint('Error disposing Stream Chat: $e');
      _isInitializing = false;
    }
  }

  /// Lấy channel cho project
  static Channel? getProjectChannel(String projectId) {
    if (_client == null) {
      debugPrint('Stream Chat client is not initialized');
      return null;
    }

    return _client!.channel('team', id: projectId);
  }

  /// Watch channel (subscribe to updates)
  static Future<Channel?> watchProjectChannel(String projectId) async {
    try {
      // Đảm bảo user hiện tại là member của channel (server-side)
      try {
        await ApiClient.post(
          url: '$uri/api/stream-chat/channel/$projectId/ensure-member',
        );
      } catch (e) {
        debugPrint('ensure-member failed (will try watch anyway): $e');
      }

      final channel = getProjectChannel(projectId);
      if (channel == null) return null;

      await channel.watch();
      return channel;
    } catch (e) {
      debugPrint('Error watching channel: $e');
      return null;
    }
  }

  /// Kiểm tra xem user có đang connect không
  static bool get isConnected {
    return _client?.wsConnectionStatus == ConnectionStatus.connected;
  }

  /// Lấy current user ID
  static String? get currentUserId => _currentUserId;
}
