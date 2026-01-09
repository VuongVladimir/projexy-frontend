import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/features/tasks/widgets/calendar_view.dart';
import 'package:frontend/features/tasks/widgets/kanban_view.dart';
import 'package:frontend/features/tasks/widgets/list_view.dart';
import 'package:frontend/models/task.dart';

enum TaskViewMode { list, kanban, calendar }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskViewMode _currentViewMode = TaskViewMode.list;
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyTasks();
  }

  Future<void> _loadMyTasks() async {
    setState(() => _isLoading = true);

    await TasksService.getMyTasks(
      context: context,
      onSuccess: (tasks) {
        // Only show root tasks (no parent)
        final rootTasks = tasks.where((task) => task.parentTaskId == null).toList();
        setState(() {
          _tasks = rootTasks;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      appBar: CustomAppBar(
        title: tr('my_tasks'),
      ),
      body: Column(
        children: [
          // View mode selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? GlobalVariables.darkSurfaceCard
                  : GlobalVariables.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? GlobalVariables.darkBorderPrimary
                    : GlobalVariables.borderPrimary,
              ),
            ),
            child: Row(
              children: [
                _buildViewModeButton(
                  context,
                  TaskViewMode.list,
                  Icons.list_rounded,
                  tr('list_view'),
                ),
                const SizedBox(width: 8),
                _buildViewModeButton(
                  context,
                  TaskViewMode.kanban,
                  Icons.view_column_rounded,
                  tr('kanban_view'),
                ),
                const SizedBox(width: 8),
                _buildViewModeButton(
                  context,
                  TaskViewMode.calendar,
                  Icons.calendar_month_rounded,
                  tr('calendar_view'),
                ),
              ],
            ),
          ),

          // Content based on view mode
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMyTasks,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _tasks.isEmpty
                      ? _buildEmptyState(context)
                      : _buildViewContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(
    BuildContext context,
    TaskViewMode mode,
    IconData icon,
    String label,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentViewMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentViewMode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode
                    ? GlobalVariables.darkPrimaryBlue
                    : GlobalVariables.primaryBlue)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDarkMode
                            ? GlobalVariables.darkTextSecondary
                            : GlobalVariables.textSecondary),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewContent() {
    switch (_currentViewMode) {
      case TaskViewMode.list:
        return TaskListView(
          tasks: _tasks,
          onRefresh: _loadMyTasks,
        );
      case TaskViewMode.kanban:
        return TaskKanbanView(
          tasks: _tasks,
          onRefresh: _loadMyTasks,
        );
      case TaskViewMode.calendar:
        return TaskCalendarView(
          tasks: _tasks,
          onRefresh: _loadMyTasks,
        );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              tr('no_tasks_assigned'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              tr('start_working_on_tasks'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}