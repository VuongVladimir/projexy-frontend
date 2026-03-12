import 'package:flutter/material.dart';
import 'package:frontend/features/account/screens/edit_profile_screen.dart';
import 'package:frontend/features/account/screens/notifications_management.dart';
import 'package:frontend/features/chat/screens/channel_messages_screen.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/features/account/screens/profile_screen.dart';
import 'package:frontend/features/account/screens/setting_screen.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/auth/screens/signup_screen.dart';
import 'package:frontend/features/auth/screens/otp_verification_screen.dart';
import 'package:frontend/features/auth/screens/forgot_password_screen.dart';
import 'package:frontend/features/auth/screens/reset_password_screen.dart';
import 'package:frontend/features/home/screens/home_screen.dart';
import 'package:frontend/features/projects/screens/create_project_screen.dart';
import 'package:frontend/features/projects/screens/edit_project_screen.dart';
import 'package:frontend/features/projects/screens/project_detail_screen.dart';
import 'package:frontend/features/projects/screens/projects_screen.dart';
import 'package:frontend/features/tasks/screens/task_detail_screen.dart';
import 'package:frontend/features/tasks/screens/create_task_screen.dart';
import 'package:frontend/features/tasks/screens/edit_task_screen.dart';
import 'package:frontend/features/tasks/screens/list_tasks_filter.dart';
import 'package:frontend/features/notifications/screens/notifications_screen.dart';
import 'package:frontend/features/responsive/responsive_screen_layout.dart';
import 'package:frontend/features/responsive/mobile_screen_layout.dart';
import 'package:frontend/features/responsive/web_screen_layout.dart';
import 'package:frontend/models/task.dart';

Route<dynamic> generateRoute(RouteSettings routeSettings) {
  final name = routeSettings.name ?? '';

  if (name.contains('projexywidget://')) {
    final parsed = Uri.tryParse(name);
    if (parsed != null) {
      switch (parsed.host) {
        case 'task-detail':
          final taskId = parsed.queryParameters['taskId'];
          if (taskId != null && taskId.isNotEmpty) {
            return MaterialPageRoute(
              settings: routeSettings,
              builder: (_) => TaskDetailScreen(taskId: taskId),
            );
          }
          break;
        case 'list-filter':
          final filter = parsed.queryParameters['filter'];
          final title = parsed.queryParameters['title'] ?? 'My Tasks';
          if (filter != null && filter.isNotEmpty) {
            return MaterialPageRoute(
              settings: routeSettings,
              builder: (_) => ListTasksFilterScreen(
                projectId: null,
                title: title,
                taskIds: const [],
                widgetFilter: filter,
              ),
            );
          }
          break;
      }
    }
    return MaterialPageRoute(
      builder: (_) => const ResponsiveLayout(
        WebScreenLayout(),
        MobileScreenLayout(),
      ),
    );
  }

  switch (routeSettings.name) {
    case LoginScreen.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const LoginScreen(),
      );

    case SignUpScreen.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const SignUpScreen(),
      );

    case OTPVerificationScreen.routeName:
      final args = routeSettings.arguments as Map<String, dynamic>;
      final email = args['email'] as String;
      final otpType = args['otpType'] as String;
      final signupData = args['signupData'] as Map<String, dynamic>?;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => OTPVerificationScreen(
          email: email,
          otpType: otpType,
          signupData: signupData,
        ),
      );

    case ForgotPasswordScreen.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const ForgotPasswordScreen(),
      );

    case ResetPasswordScreen.routeName:
      final args = routeSettings.arguments as Map<String, dynamic>;
      final email = args['email'] as String;
      final otpId = args['otpId'] as String;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => ResetPasswordScreen(email: email, otpId: otpId),
      );

    case HomeScreen.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const HomeScreen(),
      );

    case ResponsiveLayout.routeName:
      final args = routeSettings.arguments as Map<String, Widget>;
      final webScreenLayout = args['web']!;
      final mobileScreenLayout = args['mobile']!;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => ResponsiveLayout(webScreenLayout, mobileScreenLayout),
      );

    case ProfileScreen.routeName:
      var userId = routeSettings.arguments as String?;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => ProfileScreen(userId: userId),
      );

    case EditProfileScreen.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const EditProfileScreen(),
      );

    case SettingScreen.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const SettingScreen(),
      );

    case NotificationsManagement.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const NotificationsManagement(),
      );

    case ProjectsScreen.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const ProjectsScreen(),
      );

    case CreateProjectScreen.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const CreateProjectScreen(),
      );

    case EditProjectScreen.routeName:
      final project = routeSettings.arguments as Project;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => EditProjectScreen(project: project),
      );

    case NotificationsScreen.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const NotificationsScreen(),
      );

    case ProjectDetailScreen.routeName:
      final args = routeSettings.arguments as Map<String, dynamic>;
      final projectId = args['projectId'] as String;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => ProjectDetailScreen(projectId: projectId),
      );

    case TaskDetailScreen.routeName:
      final args = routeSettings.arguments as Map<String, dynamic>;
      final taskId = args['taskId'] as String;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => TaskDetailScreen(taskId: taskId),
      );

    case CreateTaskScreen.routeName:
      final args = routeSettings.arguments as Map<String, dynamic>;
      final projectId = args['projectId'] as String;
      final parentTaskId = args['parentTaskId'] as String?;
      final project = args['project'] as Project?;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => CreateTaskScreen(
          projectId: projectId,
          parentTaskId: parentTaskId,
          project: project,
        ),
      );

    case EditTaskScreen.routeName:
      final args = routeSettings.arguments as Map<String, dynamic>;
      final task = args['task'] as Task;
      final project = args['project'] as Project?;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => EditTaskScreen(task: task, project: project),
      );

    case ListTasksFilterScreen.routeName:
      final args = routeSettings.arguments as Map<String, dynamic>;
      final projectId = args['projectId'] as String?;
      final title = (args['title'] as String?) ?? 'My Tasks';
      final taskIds = List<String>.from((args['taskIds'] as List?) ?? const []);
      final widgetFilter = args['widgetFilter'] as String?;
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => ListTasksFilterScreen(
          projectId: projectId,
          title: title,
          taskIds: taskIds,
          widgetFilter: widgetFilter,
        ),
      );

    case ChannelMessagesScreen.routeName:
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const ChannelMessagesScreen(),
      );

    default:
      return MaterialPageRoute(
        builder: (_) => const ResponsiveLayout(
          WebScreenLayout(),
          MobileScreenLayout(),
        ),
      );
  }
}
