// frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/common/constants/theme_config.dart';
import 'package:frontend/common/services/fcm_service.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import 'package:frontend/features/responsive/mobile_screen_layout.dart';
import 'package:frontend/features/responsive/responsive_screen_layout.dart';
import 'package:frontend/features/responsive/web_screen_layout.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
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
              // Kiểm tra xem user đã đăng nhập chưa
              final user = Provider.of<UserProvider>(context).user;
              final bool isAuthenticated = user.token.isNotEmpty;

              // Chỉ gọi getUserData khi app khởi động VÀ có token
              // Sử dụng WidgetsBinding để đảm bảo context đã sẵn sàng
              if (isAuthenticated) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Chỉ gọi nếu user.id rỗng (chưa load data)
                  if (user.id.isEmpty) {
                    authService.getUserData(context);
                  }
                });
              }

              return isAuthenticated
                  ? const ResponsiveLayout(
                      WebScreenLayout(),
                      MobileScreenLayout(),
                    )
                  : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
