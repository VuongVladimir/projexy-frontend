import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/models/payment_history.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';

class PremiumService {
  static Future<String?> createCheckout({
    required BuildContext context,
    required String planType,
  }) async {
    try {
      final res = await ApiClient.post(
        url: '$uri/api/payment/create-checkout',
        body: jsonEncode({'planType': planType}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['checkoutUrl'];
      } else {
        if (context.mounted) {
          showSnackBar(context, jsonDecode(res.body)['msg'] ?? 'Lỗi tạo thanh toán');
        }
        return null;
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, e.toString());
      }
      return null;
    }
  }

  static Future<void> checkPaymentStatus({
    required BuildContext context,
    required int orderCode,
    required Function(String status) onResult,
  }) async {
    try {
      final res = await ApiClient.post(
        url: '$uri/api/payment/check-status',
        body: jsonEncode({'orderCode': orderCode}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final status = data['status']?.toString() ?? '';
        if (status == 'paid' && context.mounted) {
          await refreshUserPremiumStatus(context);
        }
        onResult(status);
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, e.toString());
      }
    }
  }

  static Future<void> getPremiumStatus({
    required BuildContext context,
    required Function(Map<String, dynamic>) onSuccess,
  }) async {
    try {
      final res = await ApiClient.get(
        url: '$uri/api/payment/premium-status',
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        onSuccess(data);
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, e.toString());
      }
    }
  }

  static Future<void> getPaymentHistory({
    required BuildContext context,
    required int page,
    required Function(List<PaymentHistory> payments, int total) onSuccess,
  }) async {
    try {
      final res = await ApiClient.get(
        url: '$uri/api/payment/history',
        queryParams: {'page': page.toString(), 'limit': '20'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final payments = (data['payments'] as List)
            .map((e) => PaymentHistory.fromMap(e))
            .toList();
        onSuccess(payments, data['total']);
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, e.toString());
      }
    }
  }

  static Future<void> refreshUserPremiumStatus(BuildContext context) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final res = await ApiClient.get(url: '$uri/auth/me');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final currentUser = userProvider.user;
        userProvider.setUserFromModel(
          currentUser.copyWith(
            isPremium: data['isPremium'] == true,
            premiumValidUntil: data['premiumValidUntil'] != null
                ? DateTime.tryParse(data['premiumValidUntil'].toString())
                : null,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error refreshing premium status: $e');
    }
  }
}
