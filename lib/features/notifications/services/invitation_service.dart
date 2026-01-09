import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/models/invitation.dart';

class InvitationService {
  // Gửi lời mời vào project
  static Future<void> sendInvitation({
    required BuildContext context,
    required String email,
    required String projectId,
    String? message,
    required VoidCallback onSuccess,
  }) async {
    try {
      final body = {
        'email': email,
        'projectId': projectId,
        'message': message ?? '',
      };

      final response = await ApiClient.post(
        url: '$uri/api/invitation/send',
        body: json.encode(body),
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: onSuccess,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Lấy danh sách invitations của project
  static Future<void> getProjectInvitations({
    required BuildContext context,
    required String projectId,
    required Function(List<Invitation>) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/project/$projectId/invitations',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final List<dynamic> data = json.decode(response.body);
            final invitations = data.map((json) => Invitation.fromMap(json)).toList();
            onSuccess(invitations);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Lấy chi tiết invitation bằng ID
  static Future<void> getInvitationById({
    required BuildContext context,
    required String invitationId,
    required Function(Invitation) onSuccess,
  }) async {
    try {
      // Sử dụng endpoint của project invitations để lấy thông tin
      final response = await ApiClient.get(
        url: '$uri/api/invitation/by-id/$invitationId',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final invitation = Invitation.fromMap(data);
            onSuccess(invitation);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Lấy chi tiết invitation bằng token
  static Future<void> getInvitationByToken({
    required BuildContext context,
    required String token,
    required Function(Invitation) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/invitation/$token',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final invitation = Invitation.fromMap(data);
            onSuccess(invitation);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  // Chấp nhận invitation
  static Future<void> acceptInvitation({
    required BuildContext context,
    required String token,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.post(
        url: '$uri/api/invitation/$token/accept',
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

  // Từ chối invitation
  static Future<void> declineInvitation({
    required BuildContext context,
    required String token,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.post(
        url: '$uri/api/invitation/$token/decline',
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

  // Hủy invitation
  static Future<void> cancelInvitation({
    required BuildContext context,
    required String invitationId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.delete(
        url: '$uri/api/invitation/$invitationId',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            showSnackBar(context, 'Đã hủy lời mời!');
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

  // Gửi lại invitation
  static Future<void> resendInvitation({
    required BuildContext context,
    required String invitationId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.post(
        url: '$uri/api/invitation/$invitationId/resend',
      );

      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            showSnackBar(context, 'Đã gửi lại lời mời!');
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
}