import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Class để quản lý token một cách tập trung
class TokenManager {
  static const String ACCESS_TOKEN_KEY = 'access_token';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';

  // Singleton pattern
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  // Lấy access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ACCESS_TOKEN_KEY);
  }

  // Lấy refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(REFRESH_TOKEN_KEY);
  }

  // Lưu tokens
  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ACCESS_TOKEN_KEY, accessToken);
    await prefs.setString(REFRESH_TOKEN_KEY, refreshToken);
  }

  // Xóa tokens
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ACCESS_TOKEN_KEY);
    await prefs.remove(REFRESH_TOKEN_KEY);
  }

  // Refresh access token
  static Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$uri/auth/refresh-token'),
        body: jsonEncode({'refreshToken': refreshToken}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final newAccessToken = json.decode(response.body)['accessToken'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ACCESS_TOKEN_KEY, newAccessToken);
        return newAccessToken;
      }

      // Nếu refresh token không hợp lệ, xóa cả 2 token
      await clearTokens();
      return null;
    } catch (e) {
      await clearTokens();
      return null;
    }
  }
}

// HTTP Response Handler với auto-refresh token
void httpResponseHandle({
  required http.Response response,
  required BuildContext context,
  required VoidCallback onSuccess,
  VoidCallback? onUnauthorized,
}) {
  switch (response.statusCode) {
    case 200:
      onSuccess();
      break;
    case 401:
      // Token hết hạn hoặc không hợp lệ
      if (onUnauthorized != null) {
        onUnauthorized();
      } else {
        _handleUnauthorized(context);
      }
      break;
    case 400:
      showSnackBar(context, jsonDecode(response.body)['msg']);
      break;
    case 500:
      showSnackBar(context, jsonDecode(response.body)['error']);
      break;
    default:
      showSnackBar(context, response.body);
      break;
  }
}

// Xử lý khi unauthorized - chuyển về màn hình login
void _handleUnauthorized(BuildContext context) {
  if (context.mounted) {
    showSnackBar(
      context,
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
      (route) => false,
    );
  }
}

// HTTP Helper với auto-retry khi token hết hạn
class ApiClient {
  // GET request với auto-retry
  static Future<http.Response> get({
    required String url,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    final uri = queryParams != null
        ? Uri.parse(url).replace(queryParameters: queryParams)
        : Uri.parse(url);

    String? accessToken = await TokenManager.getAccessToken();

    if (accessToken == null) {
      // Thử refresh token trước
      accessToken = await TokenManager.refreshAccessToken();
      if (accessToken == null) {
        throw Exception('No valid token available');
      }
    }

    final requestHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'x-auth-token': accessToken,
      ...?headers,
    };

    http.Response response = await http.get(uri, headers: requestHeaders);

    // Nếu unauthorized, thử refresh token và gọi lại
    if (response.statusCode == 401) {
      accessToken = await TokenManager.refreshAccessToken();
      if (accessToken != null) {
        requestHeaders['x-auth-token'] = accessToken;
        response = await http.get(uri, headers: requestHeaders);
      }
    }

    return response;
  }

  // POST request với auto-retry
  static Future<http.Response> post({
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    String? accessToken = await TokenManager.getAccessToken();

    if (accessToken == null) {
      // Thử refresh token trước
      accessToken = await TokenManager.refreshAccessToken();
      if (accessToken == null) {
        throw Exception('No valid token available');
      }
    }

    final requestHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'x-auth-token': accessToken,
      ...?headers,
    };

    http.Response response = await http.post(
      Uri.parse(url),
      headers: requestHeaders,
      body: body,
    );

    // Nếu unauthorized, thử refresh token và gọi lại
    if (response.statusCode == 401) {
      accessToken = await TokenManager.refreshAccessToken();
      if (accessToken != null) {
        requestHeaders['x-auth-token'] = accessToken;
        response = await http.post(
          Uri.parse(url),
          headers: requestHeaders,
          body: body,
        );
      }
    }

    return response;
  }

  // PUT request với auto-retry
  static Future<http.Response> put({
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    String? accessToken = await TokenManager.getAccessToken();

    if (accessToken == null) {
      // Thử refresh token trước
      accessToken = await TokenManager.refreshAccessToken();
      if (accessToken == null) {
        throw Exception('No valid token available');
      }
    }

    final requestHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'x-auth-token': accessToken,
      ...?headers,
    };

    http.Response response = await http.put(
      Uri.parse(url),
      headers: requestHeaders,
      body: body,
    );

    // Nếu unauthorized, thử refresh token và gọi lại
    if (response.statusCode == 401) {
      accessToken = await TokenManager.refreshAccessToken();
      if (accessToken != null) {
        requestHeaders['x-auth-token'] = accessToken;
        response = await http.put(
          Uri.parse(url),
          headers: requestHeaders,
          body: body,
        );
      }
    }

    return response;
  }

  // PATCH request với auto-retry
  static Future<http.Response> patch({
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    String? accessToken = await TokenManager.getAccessToken();

    if (accessToken == null) {
      // Thử refresh token trước
      accessToken = await TokenManager.refreshAccessToken();
      if (accessToken == null) {
        throw Exception('No valid token available');
      }
    }

    final requestHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'x-auth-token': accessToken,
      ...?headers,
    };

    http.Response response = await http.patch(
      Uri.parse(url),
      headers: requestHeaders,
      body: body,
    );

    // Nếu unauthorized, thử refresh token và gọi lại
    if (response.statusCode == 401) {
      accessToken = await TokenManager.refreshAccessToken();
      if (accessToken != null) {
        requestHeaders['x-auth-token'] = accessToken;
        response = await http.patch(
          Uri.parse(url),
          headers: requestHeaders,
          body: body,
        );
      }
    }

    return response;
  }

  // DELETE request với auto-retry
  static Future<http.Response> delete({
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    String? accessToken = await TokenManager.getAccessToken();

    if (accessToken == null) {
      // Thử refresh token trước
      accessToken = await TokenManager.refreshAccessToken();
      if (accessToken == null) {
        throw Exception('No valid token available');
      }
    }

    final requestHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'x-auth-token': accessToken,
      ...?headers,
    };

    http.Response response = await http.delete(
      Uri.parse(url),
      headers: requestHeaders,
      body: body,
    );

    // Nếu unauthorized, thử refresh token và gọi lại
    if (response.statusCode == 401) {
      accessToken = await TokenManager.refreshAccessToken();
      if (accessToken != null) {
        requestHeaders['x-auth-token'] = accessToken;
        response = await http.delete(Uri.parse(url), headers: requestHeaders);
      }
    }

    return response;
  }
}
