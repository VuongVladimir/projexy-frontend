import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/common/widgets/task_card.dart';
import 'package:frontend/features/tasks/screens/task_detail_screen.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/models/task.dart';

class ListTasksFilterScreen extends StatefulWidget {
  static const String routeName = '/list-tasks-filter';

  final String? projectId;
  final String title;
  final List<String> taskIds;
  final String? widgetFilter;

  const ListTasksFilterScreen({
    super.key,
    this.projectId,
    required this.title,
    required this.taskIds,
    this.widgetFilter,
  });

  @override
  State<ListTasksFilterScreen> createState() => _ListTasksFilterScreenState();
}

class _ListTasksFilterScreenState extends State<ListTasksFilterScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    if (widget.widgetFilter != null) {
      await TasksService.getMyTasks(
        context: context,
        onSuccess: (tasks) {
          final filtered = _applyWidgetFilter(tasks, widget.widgetFilter!);
          filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          if (!mounted) return;
          setState(() {
            _tasks = filtered;
            _isLoading = false;
          });
        },
      );
      return;
    }

    if (widget.projectId != null && widget.projectId!.isNotEmpty) {
      await TasksService.getProjectTasksByIds(
        context: context,
        projectId: widget.projectId!,
        taskIds: widget.taskIds,
        onSuccess: (tasks) {
          tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          if (!mounted) return;
          setState(() {
            _tasks = tasks;
            _isLoading = false;
          });
        },
      );
      return;
    }

    await TasksService.getMyTasksByIds(
      context: context,
      taskIds: widget.taskIds,
      onSuccess: (tasks) {
        tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (!mounted) return;
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      },
    );
  }

  List<Task> _applyWidgetFilter(List<Task> source, String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    DateTime normalize(DateTime value) =>
        DateTime(value.year, value.month, value.day);

    switch (filter) {
      case 'assigned_recently':
        return source.where((task) => task.assignedRecently).toList();
      case 'due_today':
        return source.where((task) {
          final due = task.endDate;
          return due != null && isSameDay(due, today);
        }).toList();
      case 'due_this_week':
        return source.where((task) {
          final due = task.endDate;
          if (due == null) return false;
          final dueDate = normalize(due);
          return !dueDate.isBefore(weekStart) && !dueDate.isAfter(weekEnd);
        }).toList();
      case 'updated_recently':
        return source.where((task) {
          return !task.updatedAt.isBefore(
            now.subtract(const Duration(days: 3)),
          );
        }).toList();
      default:
        return source;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      appBar: CustomAppBar(title: widget.title),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tasks.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Icon(
                    Icons.assignment_outlined,
                    size: 58,
                    color: isDarkMode
                        ? GlobalVariables.darkTextTertiary
                        : GlobalVariables.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      tr('no_tasks'),
                      style: TextStyle(
                        color: isDarkMode
                            ? GlobalVariables.darkTextSecondary
                            : GlobalVariables.textSecondary,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return TaskCard(
                    isCheckable: false,
                    task: task,
                    onTap: () => _navigateToTaskDetail(task),
                    onStatusChanged: (isCompleted) =>
                        _updateTaskStatus(task, isCompleted),
                  );
                },
              ),
      ),
    );
  }

  void _navigateToTaskDetail(Task task) {
    Navigator.pushNamed(
      context,
      TaskDetailScreen.routeName,
      arguments: {'taskId': task.id},
    ).then((_) => _loadTasks());
  }

  void _updateTaskStatus(Task task, bool isCompleted) {
    TasksService.markCompleteTask(
      context: context,
      taskId: task.id,
      isCompleted: isCompleted,
      onSuccess: _loadTasks,
    );
  }
}
