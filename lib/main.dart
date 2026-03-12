import 'dart:async';

// frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/theme_config.dart';
import 'package:frontend/common/services/fcm_service.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import 'package:frontend/features/responsive/mobile_screen_layout.dart';
import 'package:frontend/features/responsive/responsive_screen_layout.dart';
import 'package:frontend/features/responsive/web_screen_layout.dart';
import 'package:frontend/features/tasks/services/task_widgets_service.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => UserProvider()),
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService authService = AuthService();
  final GlobalKey<NavigatorState> _appNavigatorKey =
      GlobalKey<NavigatorState>();
  bool _isCheckingAuth = true;
  bool _hasValidToken = false;
  bool _userDataLoaded = false; // Flag to prevent multiple getUserData calls

  @override
  void initState() {
    super.initState();
    unawaited(TaskWidgetsService.initialize(navigatorKey: _appNavigatorKey));
    unawaited(TaskWidgetsService.refreshWidgetsData());
    _checkAuthStatus();
  }

  @override
  void dispose() {
    unawaited(TaskWidgetsService.dispose());
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Kiểm tra token từ SharedPreferences (không phải UserProvider)
      final hasToken = await TokenManager.hasValidToken();
      if (mounted) {
        setState(() {
          _hasValidToken = hasToken;
          _isCheckingAuth = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      if (mounted) {
        setState(() {
          _hasValidToken = false;
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: _appNavigatorKey,
          title: tr('app_title'),
          debugShowCheckedModeBanner: false,
          theme: ThemeConfig.lightTheme,
          darkTheme: ThemeConfig.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          onGenerateRoute: (settings) => generateRoute(settings),
          builder: (context, child) {
            // Lắng nghe khi client sẵn sàng để bọc toàn bộ app bằng StreamChat (cho overlay, bottom sheets, v.v.)
            return ValueListenableBuilder<StreamChatClient?>(
              valueListenable: StreamChatService.clientNotifier,
              builder: (context, client, _) {
                if (client == null) {
                  return child ?? const SizedBox.shrink();
                }
                return StreamChat(
                  client: client,
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
          home: Builder(
            builder: (context) {
              // Hiển thị loading khi đang kiểm tra trạng thái đăng nhập
              if (_isCheckingAuth) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Nếu có token hợp lệ trong SharedPreferences
              if (_hasValidToken) {
                // Lấy thông tin user từ UserProvider
                final user = Provider.of<UserProvider>(context).user;
                debugPrint(
                  'Main Dart Has Valid Token: $_hasValidToken, User Token: ${user.token}',
                );

                // Gọi getUserData để load thông tin user - chỉ gọi MỘT LẦN
                if (!_userDataLoaded && user.id.isEmpty) {
                  _userDataLoaded =
                      true; // Mark as loading to prevent duplicate calls
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      authService.getUserData(context);
                    }
                  });
                }

                return const ResponsiveLayout(
                  WebScreenLayout(),
                  MobileScreenLayout(),
                );
              }

              // Không có token hợp lệ -> về màn hình đăng nhập
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
