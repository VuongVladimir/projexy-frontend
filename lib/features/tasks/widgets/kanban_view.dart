import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/tasks/screens/task_detail_screen.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/models/task.dart';
import 'package:intl/intl.dart';

class TaskKanbanView extends StatelessWidget {
  final List<Task> tasks;
  final VoidCallback onRefresh;

  const TaskKanbanView({
    super.key,
    required this.tasks,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Group tasks by status
    final todoTasks = tasks.where((t) => t.status == 'todo').toList();
    final inProgressTasks =
        tasks.where((t) => t.status == 'in-progress').toList();
    final reviewTasks = tasks.where((t) => t.status == 'review').toList();
    final completedTasks = tasks.where((t) => t.status == 'completed').toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColumn(
            title: easy.tr('todo'),
            color: GlobalVariables.statusPlanning,
            tasks: todoTasks,
            onTaskTap: (task) => _navigateToTaskDetail(context, task.id),
            onStatusChanged: (task) => _updateTaskStatus(context, task),
          ),
          const SizedBox(width: 12),
          _KanbanColumn(
            title: easy.tr('in_progress'),
            color: GlobalVariables.statusInProgress,
            tasks: inProgressTasks,
            onTaskTap: (task) => _navigateToTaskDetail(context, task.id),
            onStatusChanged: (task) => _updateTaskStatus(context, task),
          ),
          const SizedBox(width: 12),
          _KanbanColumn(
            title: easy.tr('review'),
            color: GlobalVariables.statusReview,
            tasks: reviewTasks,
            onTaskTap: (task) => _navigateToTaskDetail(context, task.id),
            onStatusChanged: (task) => _updateTaskStatus(context, task),
          ),
          const SizedBox(width: 12),
          _KanbanColumn(
            title: easy.tr('completed'),
            color: GlobalVariables.statusCompleted,
            tasks: completedTasks,
            onTaskTap: (task) => _navigateToTaskDetail(context, task.id),
            onStatusChanged: (task) => _updateTaskStatus(context, task),
          ),
        ],
      ),
    );
  }

  void _navigateToTaskDetail(BuildContext context, String taskId) {
    Navigator.pushNamed(
      context,
      TaskDetailScreen.routeName,
      arguments: {'taskId': taskId},
    ).then((_) => onRefresh());
  }

  void _updateTaskStatus(BuildContext context, Task task) {
    // Cycle through statuses when tapped
    String nextStatus;
    switch (task.status) {
      case 'todo':
        nextStatus = 'in-progress';
        break;
      case 'in-progress':
        nextStatus = 'review';
        break;
      case 'review':
        nextStatus = 'completed';
        break;
      case 'completed':
        nextStatus = 'todo';
        break;
      default:
        nextStatus = 'in-progress';
    }

    TasksService.updateTask(
      context: context,
      taskId: task.id,
      status: nextStatus,
      onSuccess: onRefresh,
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task) onStatusChanged;

  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.tasks,
    required this.onTaskTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? GlobalVariables.darkSurfaceCard.withValues(alpha: 0.5)
            : GlobalVariables.surfaceCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column header
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Task cards
          ...tasks.map((task) => _KanbanCard(
                task: task,
                onTap: () => onTaskTap(task),
                onStatusChanged: () => onStatusChanged(task),
              )),

          // Empty state
          if (tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  easy.tr('no_tasks'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode
                        ? GlobalVariables.darkTextTertiary
                        : GlobalVariables.textTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onStatusChanged;

  const _KanbanCard({
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode
              ? GlobalVariables.darkBackgroundSecondary
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? GlobalVariables.darkBorderPrimary
                : GlobalVariables.borderPrimary,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode ? Colors.black : Colors.grey)
                  .withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              task.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Description
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode
                      ? GlobalVariables.darkTextSecondary
                      : GlobalVariables.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 8),

            // Priority and due date
            Row(
              children: [
                // Priority
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GlobalVariables.getPriorityColor(task.priority)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: GlobalVariables.getPriorityColor(task.priority)
                          .withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    task.priorityDisplayName,
                    style: TextStyle(
                      color: GlobalVariables.getPriorityColor(task.priority),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),

                // Date range hoặc end date
                if (task.hasValidDates)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: task.isOverdue
                            ? GlobalVariables.errorRed
                            : (isDarkMode
                                ? GlobalVariables.darkTextTertiary
                                : GlobalVariables.textTertiary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('MMM dd').format(task.startDate!)} - ${DateFormat('MMM dd').format(task.endDate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: task.isOverdue
                              ? GlobalVariables.errorRed
                              : (isDarkMode
                                  ? GlobalVariables.darkTextTertiary
                                  : GlobalVariables.textTertiary),
                          fontSize: 11,
                          fontWeight:
                              task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Progress bar
            if (task.progress > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: task.progressPercentage,
                        backgroundColor: isDarkMode
                            ? GlobalVariables.darkBorderPrimary
                            : GlobalVariables.borderPrimary,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          task.isCompleted
                              ? GlobalVariables.successGreen
                              : GlobalVariables.primaryBlue,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${task.progress}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDarkMode
                          ? GlobalVariables.darkTextSecondary
                          : GlobalVariables.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

