import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/features/tasks/screens/list_tasks_filter.dart';
import 'package:frontend/features/tasks/screens/task_detail_screen.dart';
import 'package:frontend/models/task.dart';

class TaskWidgetsService {
  static const String _calendarWidgetProvider = 'TaskCalendarWidgetProvider';
  static const String _myTasksWidgetProvider = 'MyTasksWidgetProvider';

  static const String _keyTasksJson = 'widget_tasks_json';
  static const String _keySelectedDate = 'widget_selected_date';
  static const String _keyFocusedMonth = 'widget_focused_month';
  static const String _keyWindowStart = 'widget_window_start';
  static const String _keyCountersJson = 'widget_counters_json';
  static const String _keyLastUpdatedText = 'widget_last_updated_text';

  static GlobalKey<NavigatorState>? _navigatorKey;
  static StreamSubscription<Uri?>? _widgetClickSubscription;
  static bool _initialized = false;
  static String? _lastHandledUri;

  static Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _navigatorKey = navigatorKey;

    HomeWidget.registerInteractivityCallback(taskWidgetInteractivityCallback);

    _widgetClickSubscription = HomeWidget.widgetClicked.listen(
      _handleLaunchUri,
    );

    try {
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialUri != null) {
        _handleLaunchUri(initialUri);
      }
    } catch (_) {}
  }

  static Future<void> dispose() async {
    await _widgetClickSubscription?.cancel();
    _widgetClickSubscription = null;
    _initialized = false;
  }

  static Future<void> refreshWidgetsData() async {
    final accessToken = await TokenManager.getValidAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$uri/api/my-tasks'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': accessToken,
        },
      );
      if (response.statusCode != 200 || response.body.isEmpty) {
        return;
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) return;

      final tasks = decoded
          .whereType<Map<String, dynamic>>()
          .map(Task.fromMap)
          .toList(growable: false);
      await syncFromTasks(tasks);
    } catch (_) {
      // Widget sync lỗi không nên làm crash luồng chính của app.
    }
  }

  static Future<void> syncFromTasks(List<Task> tasks) async {
    final now = DateTime.now();
    final normalizedToday = _normalizeDate(now);
    final weekStart = _startOfWeek(now);
    final weekEnd = weekStart.add(const Duration(days: 6));

    final assignedRecently = tasks.where((task) {
      if (task.assignedRecently) return true;
      return !task.createdAt.isBefore(now.subtract(const Duration(days: 7)));
    }).length;

    final dueToday = tasks.where((task) {
      final due = task.endDate;
      return due != null && _isSameDay(due, now);
    }).length;

    final dueThisWeek = tasks.where((task) {
      final due = task.endDate;
      if (due == null) return false;
      final dueDate = _normalizeDate(due);
      return !dueDate.isBefore(weekStart) && !dueDate.isAfter(weekEnd);
    }).length;

    final updatedRecently = tasks.where((task) {
      return !task.updatedAt.isBefore(now.subtract(const Duration(days: 3)));
    }).length;

    final sanitizedTasks = tasks
        .map(
          (task) => <String, dynamic>{
            'id': task.id,
            'title': task.title,
            'projectTitle': task.projectTitle ?? '',
            'status': task.status,
            'priority': task.priority,
            'endDate': task.endDate?.toIso8601String(),
            'createdAt': task.createdAt.toIso8601String(),
            'updatedAt': task.updatedAt.toIso8601String(),
          },
        )
        .toList(growable: false);

    final counters = <String, dynamic>{
      'assigned_recently': assignedRecently,
      'due_today': dueToday,
      'due_this_week': dueThisWeek,
      'updated_recently': updatedRecently,
    };

    await Future.wait([
      HomeWidget.saveWidgetData<String>(
        _keyTasksJson,
        json.encode(sanitizedTasks),
      ),
      HomeWidget.saveWidgetData<String>(
        _keyCountersJson,
        json.encode(counters),
      ),
      HomeWidget.saveWidgetData<String>(
        _keySelectedDate,
        _formatDate(normalizedToday),
      ),
      HomeWidget.saveWidgetData<String>(
        _keyFocusedMonth,
        _formatMonth(normalizedToday),
      ),
      HomeWidget.saveWidgetData<String>(
        _keyWindowStart,
        _formatWindowStart(normalizedToday),
      ),
      HomeWidget.saveWidgetData<String>(_keyLastUpdatedText, _formatTime(now)),
    ]);

    await _triggerWidgetsUpdate();
  }

  static Future<void> _triggerWidgetsUpdate() async {
    await Future.wait([
      HomeWidget.updateWidget(name: _calendarWidgetProvider),
      HomeWidget.updateWidget(name: _myTasksWidgetProvider),
    ]);
  }

  static void _handleLaunchUri(Uri? launchUri) {
    if (launchUri == null) return;
    final uriKey = launchUri.toString();
    if (_lastHandledUri == uriKey) return;
    _lastHandledUri = uriKey;

    Future.delayed(const Duration(seconds: 2), () {
      if (_lastHandledUri == uriKey) _lastHandledUri = null;
    });

    _performNavigation(launchUri);
  }

  static void _performNavigation(Uri launchUri, [int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey?.currentState;
      if (navigator == null) {
        if (attempt < 20) {
          Future.delayed(const Duration(milliseconds: 150), () {
            _performNavigation(launchUri, attempt + 1);
          });
        }
        return;
      }

      switch (launchUri.host) {
        case 'task-detail':
          final taskId = launchUri.queryParameters['taskId'];
          if (taskId == null || taskId.isEmpty) return;
          navigator.pushNamedAndRemoveUntil(
            TaskDetailScreen.routeName,
            (route) => route.isFirst,
            arguments: {'taskId': taskId},
          );
          break;
        case 'list-filter':
          final filter = launchUri.queryParameters['filter'];
          final title = launchUri.queryParameters['title'] ?? 'My Tasks';
          navigator.pushNamedAndRemoveUntil(
            ListTasksFilterScreen.routeName,
            (route) => route.isFirst,
            arguments: {
              'title': title,
              'taskIds': const <String>[],
              'widgetFilter': filter,
            },
          );
          break;
        default:
          break;
      }
    });
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime _startOfWeek(DateTime date) {
    final normalized = _normalizeDate(date);
    final diff = normalized.weekday - DateTime.monday;
    return normalized.subtract(Duration(days: diff));
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatMonth(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  static String _formatWindowStart(DateTime date) {
    // Go to Sunday of the previous week so today falls in the 2nd week
    final weekday = date.weekday % 7; // 0=Sun, 6=Sat
    final sunday = date.subtract(Duration(days: weekday));
    final start = sunday.subtract(const Duration(days: 7));
    return _formatDate(start);
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

@pragma('vm:entry-point')
Future<void> taskWidgetInteractivityCallback(Uri? uri) async {
  if (uri == null) return;
  if (uri.host != 'refresh') return;
  await TaskWidgetsService.refreshWidgetsData();
}
