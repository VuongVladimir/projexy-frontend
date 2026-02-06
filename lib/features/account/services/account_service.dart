import 'dart:convert';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream_chat;

class AccountService {
  // Lấy thông tin profile của user theo ID
  Future<User?> getUserProfile(BuildContext context, String userId) async {
    User? userProfile;
    try {
      final response = await ApiClient.get(url: '$uri/account/profile/$userId');

      if (!context.mounted) return null;
      httpResponseHandle(
        response: response,
        context: context,
        onSuccess: () {
          userProfile = User.fromJson(response.body);
        },
      );
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, e.toString());
      }
    }
    return userProfile;
  }

  // Cập nhật profile user
  Future<void> updateProfile({
    required BuildContext context,
    required String name,
    required String bio,
    required List<String> skills,
    dynamic avatar,
  }) async {
    try {
      String? avatarUrl;

      // Upload avatar nếu có thay đổi
      if (avatar != null) {
        final cloudinary = CloudinaryPublic('dkwp4prjj', 'projexy_preset');
        CloudinaryResponse response;

        if (kIsWeb) {
          response = await cloudinary.uploadFile(
            CloudinaryFile.fromBytesData(
              avatar,
              identifier: 'avatar_${DateTime.now().millisecondsSinceEpoch}',
              folder: 'avatars',
            ),
          );
        } else {
          response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(avatar.path, folder: 'avatars'),
          );
        }
        avatarUrl = response.secureUrl;
      }

      // Chuẩn bị dữ liệu gửi lên server
      final Map<String, dynamic> updateData = {
        'name': name,
        'bio': bio,
        'skills': skills,
      };

      if (avatarUrl != null) {
        updateData['avatar'] = avatarUrl;
      }

      final response = await ApiClient.put(
        url: '$uri/account/profile',
        body: json.encode(updateData),
      );

      if (!context.mounted) return;

      httpResponseHandle(
        response: response,
        context: context,
        onSuccess: () async {
          // Cập nhật UserProvider với thông tin mới
          final userData = json.decode(response.body);
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );

          // Preserve token và password hiện tại (vì backend không trả về)
          final currentUser = userProvider.user;
          userData['token'] = currentUser.token;
          userData['password'] = currentUser.password;

          userProvider.setUser(json.encode(userData));

          // Cập nhật Stream Chat user info nếu có thay đổi avatar hoặc name
          try {
            final client = StreamChatService.client;
            if (client != null && StreamChatService.isConnected) {
              final updateData = <String, dynamic>{};

              // Cập nhật name nếu khác
              if (name.trim() != currentUser.name) {
                updateData['name'] = name.trim();
              }

              // Cập nhật avatar nếu có
              if (avatarUrl != null) {
                updateData['image'] = avatarUrl;
              }

              // Chỉ update nếu có thay đổi
              if (updateData.isNotEmpty) {
                await client.updateUser(
                  stream_chat.User(id: currentUser.id, extraData: updateData),
                );
                debugPrint('✅ Stream Chat user info updated successfully');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Failed to update Stream Chat user info: $e');
            // Không throw error vì đây không phải critical operation
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi cập nhật profile: $e');
      }
      rethrow;
    }
  }

  // Tìm kiếm users
  Future<List<User>> searchUsers(BuildContext context, String query) async {
    List<User> results = [];
    try {
      final response = await ApiClient.get(
        url: '$uri/account/search',
        queryParams: {'q': query},
      );

      if (!context.mounted) return [];
      httpResponseHandle(
        response: response,
        context: context,
        onSuccess: () {
          List<dynamic> usersData = json.decode(response.body);
          results = usersData
              .map((userData) => User.fromMap(userData))
              .toList();
        },
      );
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, e.toString());
      }
      return [];
    }
    return results;
  }
}
