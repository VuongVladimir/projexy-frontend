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
  /// Nếu channel chưa tồn tại, cung cấp projectTitle để tạo channel đúng dữ liệu
  static Future<Channel?> watchProjectChannel(
    String projectId, {
    String? projectTitle,
  }) async {
    try {
      // Đảm bảo user hiện tại là member của channel (server-side)
      try {
        await ApiClient.post(
          url: '$uri/api/stream-chat/channel/$projectId/ensure-member',
        );
      } catch (e) {
        debugPrint('ensure-member failed (will try watch anyway): $e');
      }

      final normalizedTitle = projectTitle?.trim();
      final hasTitle = normalizedTitle != null && normalizedTitle.isNotEmpty;
      final channel = hasTitle
          ? _client!.channel(
              'team',
              id: projectId,
              extraData: {
                'name': normalizedTitle,
                'category': 'project',
                'project_id': projectId,
                'project_title': normalizedTitle,
                if (_currentUserId != null) 'members': [_currentUserId!],
              },
            )
          : getProjectChannel(projectId);
      if (channel == null) return null;

      await channel.watch();

      if (hasTitle) {
        final currentName = channel.name?.trim() ?? '';
        final category = channel.extraData['category'];
        final projectIdValue = channel.extraData['project_id'];
        final projectTitleValue = channel.extraData['project_title'];
        final needsUpdate = currentName.isEmpty ||
            category != 'project' ||
            projectIdValue == null ||
            (projectTitleValue is! String || projectTitleValue.trim().isEmpty);

        if (needsUpdate) {
          try {
            await channel.update({
              'name': normalizedTitle,
              'category': 'project',
              'project_id': projectId,
              'project_title': normalizedTitle,
            });
          } catch (e) {
            debugPrint('Failed to normalize project channel data: $e');
          }
        }
      }

      return channel;
    } catch (e) {
      debugPrint('Error watching channel: $e');
      return null;
    }
  }

  /// Watch generic channel by ID and Type
  static Future<Channel?> watchChannel({
    required String channelId,
    required String channelType,
    String? category, // 'project', 'team', 'direct'
  }) async {
    try {
      // Ensure member endpoint supports type now
      try {
        await ApiClient.post(
          url:
              '$uri/api/stream-chat/channel/$channelId/ensure-member?type=$channelType',
        );
      } catch (e) {
        debugPrint(
            'ensure-member failed for $channelType (will try watch anyway): $e');
      }

      final channel = _client!.channel(channelType, id: channelId);
      await channel.watch();
      return channel;
    } catch (e) {
      debugPrint('Error watching channel $channelId ($channelType): $e');
      return null;
    }
  }

  /// Helper for Team Channel
  static Future<Channel?> watchTeamChannel(String teamId) {
    return watchChannel(
      channelId: teamId,
      channelType: 'team',
      category: 'team',
    );
  }

  /// Create and Watch Direct Chat
  static Future<Channel?> createAndWatchDirectChat(String otherUserId) async {
    if (_client == null) {
      debugPrint('createAndWatchDirectChat aborted: client is null');
      return null;
    }

    if (_currentUserId == null) {
      _currentUserId = _client!.state.currentUser?.id;
      debugPrint(
        'createAndWatchDirectChat: currentUserId fallback from client state = $_currentUserId',
      );
    }

    if (_currentUserId == null) {
      debugPrint('createAndWatchDirectChat aborted: currentUserId is null');
      return null;
    }

    try {
      debugPrint(
        'createAndWatchDirectChat: currentUserId=$_currentUserId, otherUserId=$otherUserId, connection=${_client!.wsConnectionStatus}',
      );
      final response = await ApiClient.post(
        url: '$uri/api/stream-chat/direct-channel',
        body: json.encode({'otherUserId': otherUserId}),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'direct-channel API failed: status=${response.statusCode}, body=${response.body}',
        );
        throw Exception('Failed to create direct channel');
      }

      debugPrint('direct-channel API success: body=${response.body}');
      final data = json.decode(response.body) as Map<String, dynamic>;
      final channelId = data['channelId'] as String?;

      if (channelId == null || channelId.isEmpty) {
        debugPrint('direct-channel API returned invalid channelId');
        throw Exception('Invalid channelId returned from server');
      }

      final channel = await watchChannel(
        channelId: channelId,
        channelType: 'messaging',
        category: 'direct',
      );
      debugPrint('watchChannel result: ${channel?.id}');
      return channel;
    } catch (e) {
      debugPrint('Error creating direct chat: $e');
      return null;
    }
  }

  /// Xóa channel (chỉ nên dùng cho direct channel)
  static Future<bool> deleteChannel(Channel channel) async {
    try {
      await channel.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting channel ${channel.id}: $e');
      return false;
    }
  }

  /// Kiểm tra xem user có đang connect không
  static bool get isConnected {
    return _client?.wsConnectionStatus == ConnectionStatus.connected;
  }

  /// Lấy current user ID
  static String? get currentUserId => _currentUserId;

  /// Cập nhật avatar cho channel (project/team channel only)
  /// Upload ảnh lên Cloudinary trước, sau đó gọi API này với URL
  /// @param channelId - ID của channel
  /// @param channelType - Loại channel (team, messaging)
  /// @param avatarUrl - URL ảnh avatar (từ Cloudinary)
  /// @param avatarColor - Màu avatar (hex color)
  /// @returns true nếu thành công, false nếu thất bại
  static Future<bool> updateChannelAvatar({
    required String channelId,
    String channelType = 'team',
    String? avatarUrl,
    String? avatarColor,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (avatarUrl != null) {
        body['avatarUrl'] = avatarUrl;
      }
      if (avatarColor != null) {
        body['avatarColor'] = avatarColor;
      }

      final response = await ApiClient.put(
        url: '$uri/api/stream-chat/channel/$channelId/avatar?type=$channelType',
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Channel avatar updated successfully');
        return true;
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ Failed to update channel avatar: ${errorData['msg'] ?? errorData['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating channel avatar: $e');
      return false;
    }
  }

  /// Cập nhật avatar cho channel trực tiếp qua Stream SDK (client-side)
  /// Sử dụng khi cần cập nhật nhanh mà không cần qua backend
  static Future<bool> updateChannelAvatarDirect({
    required Channel channel,
    String? avatarUrl,
    String? avatarColor,
    bool clearImage = false,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      final unsetFields = <String>[];
      if (avatarUrl != null) {
        updateData['image'] = avatarUrl;
      } else if (clearImage) {
        unsetFields.add('image');
      }
      if (avatarColor != null) {
        updateData['avatarColor'] = avatarColor;
      }

      if (updateData.isEmpty && unsetFields.isEmpty) return true;

      await channel.updatePartial(set: updateData, unset: unsetFields);
      debugPrint('✅ Channel avatar updated directly via Stream SDK');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating channel avatar directly: $e');
      return false;
    }
  }
}
