import 'dart:convert';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:frontend/models/feedback_item.dart';
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
  Future<List<User>> searchUsers(
    BuildContext context,
    String query, {
    bool showErrorSnackBar = true,
  }) async {
    List<User> results = [];
    try {
      final response = await ApiClient.get(
        url: '$uri/account/search',
        queryParams: {'q': query},
      );

      if (!context.mounted) return [];

      if (showErrorSnackBar) {
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
      } else {
        if (response.statusCode == 200) {
          final List<dynamic> usersData = json.decode(response.body);
          results = usersData
              .map((userData) => User.fromMap(userData))
              .toList();
        } else {
          return [];
        }
      }
    } catch (e) {
      if (context.mounted && showErrorSnackBar) {
        showSnackBar(context, e.toString());
      }
      return [];
    }
    return results;
  }

  // Gửi feedback cho admin
  Future<bool> submitFeedback({
    required BuildContext context,
    required String type,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await ApiClient.post(
        url: '$uri/feedback',
        body: json.encode({
          'type': type,
          'subject': subject.trim(),
          'message': message.trim(),
        }),
      );

      if (!context.mounted) return false;

      bool isSuccess = false;
      httpResponseHandle(
        response: response,
        context: context,
        onSuccess: () {
          isSuccess = true;
        },
      );

      return isSuccess;
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi gửi feedback: $e');
      }
      return false;
    }
  }

  // Lấy lịch sử feedback của user hiện tại
  Future<Map<String, dynamic>> getMyFeedbacks({
    required BuildContext context,
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
    bool showErrorSnackBar = true,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      if (type != null && type.isNotEmpty && type != 'all') {
        queryParams['type'] = type;
      }

      if (status != null && status.isNotEmpty && status != 'all') {
        queryParams['status'] = status;
      }

      final response = await ApiClient.get(
        url: '$uri/feedback/my',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final feedbacksData = (data['feedbacks'] as List?) ?? const [];
        final feedbacks = feedbacksData
            .map((item) => FeedbackItem.fromMap(item as Map<String, dynamic>))
            .toList();

        final pagination =
            (data['pagination'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};

        return {'feedbacks': feedbacks, 'pagination': pagination};
      }

      if (showErrorSnackBar && context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {},
        );
      }
      return {
        'feedbacks': <FeedbackItem>[],
        'pagination': const <String, dynamic>{},
      };
    } catch (e) {
      if (showErrorSnackBar && context.mounted) {
        showSnackBar(context, 'Lỗi tải lịch sử feedback: $e');
      }
      return {
        'feedbacks': <FeedbackItem>[],
        'pagination': const <String, dynamic>{},
      };
    }
  }
}
