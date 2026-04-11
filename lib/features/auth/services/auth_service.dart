import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/services/fcm_service.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/auth/screens/otp_verification_screen.dart';
import 'package:frontend/features/auth/screens/reset_password_screen.dart';
import 'package:frontend/features/responsive/mobile_screen_layout.dart';
import 'package:frontend/features/responsive/responsive_screen_layout.dart';
import 'package:frontend/features/responsive/web_screen_layout.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  // Key để lưu token trong SharedPreferences - sử dụng từ TokenManager
  static const String ACCESS_TOKEN_KEY = 'access_token';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';

  // Gửi OTP khi đăng ký
  Future<void> sendSignUpOTP({
    required BuildContext context,
    required String email,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/otp/send-signup'),
        body: jsonEncode({'email': email}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (!context.mounted) return;
      httpResponseHandle(
        response: res,
        context: context,
        onSuccess: () {
          showSnackBar(context, 'Mã OTP đã được gửi đến email của bạn');
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  // Sign up với OTP verification (bước 1: upload avatar và chuẩn bị dữ liệu)
  Future<void> initiateSignUp({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
    required dynamic avatar,
  }) async {
    try {
      final cloudinary = CloudinaryPublic('dkwp4prjj', 'projexy_preset');
      String avatarUrl = '';
      if (avatar != null) {
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

      // Gửi OTP
      http.Response res = await http.post(
        Uri.parse('$uri/otp/send-signup'),
        body: jsonEncode({'email': email}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (!context.mounted) return;
      httpResponseHandle(
        response: res,
        context: context,
        onSuccess: () {
          // Chuyển đến màn hình OTP verification
          Navigator.pushNamed(
            context,
            OTPVerificationScreen.routeName,
            arguments: {
              'email': email,
              'otpType': 'signup',
              'signupData': {
                'name': name,
                'email': email,
                'password': password,
                'avatar': avatarUrl,
              },
            },
          );
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  // Complete signup sau khi verify OTP
  Future<void> completeSignUp({
    required BuildContext context,
    required Map<String, dynamic> signupData,
    required String otpId,
  }) async {
    try {
      final body = {...signupData, 'otpId': otpId};

      http.Response res = await http.post(
        Uri.parse('$uri/auth/signup'),
        body: jsonEncode(body),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (!context.mounted) return;
      httpResponseHandle(
        response: res,
        context: context,
        onSuccess: () {
          showSnackBar(context, 'Tài khoản đã được tạo thành công!');
          // Quay về login screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginScreen.routeName,
            (route) => false,
          );
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> logIn({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/auth/login'),
        body: jsonEncode({'email': email, 'password': password}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (!context.mounted) return;
      httpResponseHandle(
        response: res,
        context: context,
        onSuccess: () async {
          final data = json.decode(res.body);
          await TokenManager.saveTokens(
            data['accessToken'],
            data['refreshToken'],
          );
          await getUserData(context);
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            ResponsiveLayout.routeName,
            arguments: {
              'mobile': MobileScreenLayout(),
              'web': WebScreenLayout(),
            },
            (route) => false,
          );
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  static bool _servicesInitialized = false;
  static String? _currentUserId;

  Future<void> signInWithGoogle({required BuildContext context}) async {
    try {
      // Đăng xuất phiên cũ để người dùng có thể chọn tài khoản mới
      await GoogleSignIn.instance.signOut();

      // Hiển thị màn hình chọn tài khoản Google
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      // Lấy Google idToken (synchronous trong v7)
      final String? googleIdToken = googleUser.authentication.idToken;

      if (googleIdToken == null) {
        if (context.mounted) {
          showSnackBar(
            context,
            'Không thể lấy token từ Google. Vui lòng thử lại.',
          );
        }
        return;
      }

      // Tạo Firebase credential từ Google idToken
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleIdToken,
      );

      // Đăng nhập vào Firebase
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);

      // Lấy Firebase ID token để gửi lên backend
      final firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null) {
        if (context.mounted) {
          showSnackBar(
            context,
            'Không thể xác thực với server. Vui lòng thử lại.',
          );
        }
        return;
      }

      // Gửi Firebase ID token lên backend
      final http.Response res = await http.post(
        Uri.parse('$uri/auth/google'),
        body: jsonEncode({'idToken': firebaseIdToken}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (!context.mounted) return;
      httpResponseHandle(
        response: res,
        context: context,
        onSuccess: () async {
          final data = json.decode(res.body);
          await TokenManager.saveTokens(
            data['accessToken'],
            data['refreshToken'],
          );
          await getUserData(context);
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            ResponsiveLayout.routeName,
            arguments: {
              'mobile': MobileScreenLayout(),
              'web': WebScreenLayout(),
            },
            (route) => false,
          );
        },
        onError: () async {
          // Đăng xuất khỏi Firebase nếu backend từ chối
          await firebase_auth.FirebaseAuth.instance.signOut();
          await GoogleSignIn.instance.signOut();
        },
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      await firebase_auth.FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
      if (context.mounted) showSnackBar(context, e.message ?? e.code);
    } catch (e) {
      await firebase_auth.FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
      if (context.mounted) showSnackBar(context, e.toString());
    }
  }

  // get user data - sử dụng ApiClient với auto-retry
  Future<void> getUserData(BuildContext context) async {
    try {
      final userRes = await ApiClient.get(url: '$uri/auth/me');

      if (!context.mounted) return;
      httpResponseHandle(
        response: userRes,
        context: context,
        onSuccess: () async {
          var userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setUser(userRes.body);

          final user = userProvider.user;
          // Chỉ initialize services một lần CHO USER HIỆN TẠI
          // Reset flag nếu user ID thay đổi
          if (!_servicesInitialized || _currentUserId != user.id) {
            _servicesInitialized = true;
            _currentUserId = user.id;

            // Initialize FCM after successful login với userId
            FCMService.initialize(context, userId: user.id);

            // Initialize Stream Chat after successful login
            if (user.id.isNotEmpty) {
              await StreamChatService.initialize(
                context: context,
                userId: user.id,
              );
            }
          }
        },
        onUnauthorized: () async {
          // Khi token không hợp lệ hoặc hết hạn
          // Clear tokens và reset state
          await TokenManager.clearTokens();
          _servicesInitialized = false;
          _currentUserId = null;

          if (context.mounted) {
            Provider.of<UserProvider>(context, listen: false).clearUser();
            Navigator.pushNamedAndRemoveUntil(
              context,
              LoginScreen.routeName,
              (route) => false,
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Error in getUserData: $e');
      if (context.mounted) {
        if (e.toString().contains('No valid token available')) {
          // Clear tokens và reset state
          await TokenManager.clearTokens();
          _servicesInitialized = false;
          _currentUserId = null;
          Provider.of<UserProvider>(context, listen: false).clearUser();

          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginScreen.routeName,
            (route) => false,
          );
        } else {
          showSnackBar(context, e.toString());
        }
      }
    }
  }

  // Lấy thông tin user theo ID - sử dụng ApiClient với auto-retry
  static Future<User?> getUserById({
    required BuildContext context,
    required String userId,
  }) async {
    User? userResult;
    try {
      final response = await ApiClient.get(url: '$uri/auth/user/$userId');

      httpResponseHandle(
        response: response,
        context: context,
        onSuccess: () {
          final userData = json.decode(response.body);
          userResult = User.fromMap(userData);
        },
      );
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi khi lấy thông tin user: ${e.toString()}');
      }
      return null;
    }
    return userResult;
  }

  Future<void> logOut(BuildContext context) async {
    try {
      // Store UserProvider reference before any async operations
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Unregister FCM token before logout
      await FCMService.unregister(context);

      // Disconnect Stream Chat before logout
      await StreamChatService.dispose();

      // Call logout API sử dụng ApiClient
      try {
        await ApiClient.post(url: '$uri/auth/logout');
      } catch (e) {
        // Ignore logout API errors, vẫn clear tokens local
        debugPrint('Logout API error: $e');
      }

      // Sign out khỏi Firebase và Google (cho trường hợp Google Sign-In)
      try {
        await firebase_auth.FirebaseAuth.instance.signOut();
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Firebase/Google sign out error: $e');
      }

      // Clear stored tokens sử dụng TokenManager
      await TokenManager.clearTokens();

      // Reset services initialization flag
      _servicesInitialized = false;
      _currentUserId = null;

      // Clear UserProvider TRƯỚC KHI navigate để đảm bảo state được reset
      userProvider.clearUser();

      // Navigate to login
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (route) => false,
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  // Verify OTP
  Future<void> verifyOTP({
    required BuildContext context,
    required String email,
    required String otp,
    required String otpType,
    Map<String, dynamic>? signupData,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/otp/verify'),
        body: jsonEncode({'email': email, 'otp': otp, 'type': otpType}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (!context.mounted) return;
      httpResponseHandle(
        response: res,
        context: context,
        onSuccess: () async {
          final data = json.decode(res.body);
          final otpId = data['otpId'];

          if (otpType == 'signup' && signupData != null) {
            // Complete signup
            await completeSignUp(
              context: context,
              signupData: signupData,
              otpId: otpId,
            );
          } else if (otpType == 'forgot_password') {
            // Navigate to reset password screen
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(
              context,
              ResetPasswordScreen.routeName,
              arguments: {'email': email, 'otpId': otpId},
            );
          }
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  // Resend OTP
  Future<void> resendOTP({
    required BuildContext context,
    required String email,
    required String otpType,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/otp/resend'),
        body: jsonEncode({'email': email, 'type': otpType}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (!context.mounted) return;
      httpResponseHandle(
        response: res,
        context: context,
        onSuccess: () {
          showSnackBar(context, 'Mã OTP mới đã được gửi đến email của bạn');
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  // Send OTP for forgot password
  Future<void> sendForgotPasswordOTP({
    required BuildContext context,
    required String email,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/otp/send-forgot-password'),
        body: jsonEncode({'email': email}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (!context.mounted) return;
      httpResponseHandle(
        response: res,
        context: context,
        onSuccess: () {
          // Navigate to OTP verification screen
          Navigator.pushNamed(
            context,
            OTPVerificationScreen.routeName,
            arguments: {'email': email, 'otpType': 'forgot_password'},
          );
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  // Reset password
  Future<void> resetPassword({
    required BuildContext context,
    required String email,
    required String newPassword,
    required String otpId,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$uri/auth/reset-password'),
        body: jsonEncode({
          'email': email,
          'newPassword': newPassword,
          'otpId': otpId,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (!context.mounted) return;
      httpResponseHandle(
        response: res,
        context: context,
        onSuccess: () {
          showSnackBar(context, 'Mật khẩu đã được đặt lại thành công!');
          // Navigate back to login
          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginScreen.routeName,
            (route) => false,
          );
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }
}
