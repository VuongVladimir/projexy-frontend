import 'package:flutter/material.dart';
import 'package:frontend/common/widgets/task_card.dart';
import 'package:frontend/features/tasks/screens/task_detail_screen.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/models/task.dart';

class TaskListView extends StatelessWidget {
  final List<Task> tasks;
  final VoidCallback onRefresh;

  const TaskListView({super.key, required this.tasks, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onTap: () => _navigateToTaskDetail(context, task.id),
          onStatusChanged: (isCompleted) =>
              _updateTaskStatus(context, task, isCompleted),
        );
      },
    );
  }

  void _navigateToTaskDetail(BuildContext context, String taskId) {
    Navigator.pushNamed(
      context,
      TaskDetailScreen.routeName,
      arguments: {'taskId': taskId},
    ).then((_) => onRefresh());
  }

  void _updateTaskStatus(BuildContext context, Task task, bool isCompleted) {
    TasksService.markCompleteTask(
      context: context,
      taskId: task.id,
      isCompleted: isCompleted,
      onSuccess: onRefresh,
    );
  }
}
