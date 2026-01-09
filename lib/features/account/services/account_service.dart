import 'dart:convert';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';

class AccountService {
  // Lấy thông tin profile của user theo ID
  Future<User?> getUserProfile(BuildContext context, String userId) async {
    User? userProfile;
    try {
      final response = await ApiClient.get(
        url: '$uri/account/profile/$userId',
      );

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
        final cloudinary = CloudinaryPublic('dvgeq2l6e', 'xuvwiao4');
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
        onSuccess: () {
          // Cập nhật UserProvider với thông tin mới
          final userData = json.decode(response.body);
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          userProvider.setUser(json.encode(userData));
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