import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/task_card.dart';
import 'package:frontend/features/tasks/screens/task_detail_screen.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/models/task.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class TaskCalendarView extends StatefulWidget {
  final List<Task> tasks;
  final VoidCallback onRefresh;

  const TaskCalendarView({
    super.key,
    required this.tasks,
    required this.onRefresh,
  });

  @override
  State<TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends State<TaskCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Map<DateTime, List<Task>> _groupTasksByDate() {
    final Map<DateTime, List<Task>> taskMap = {};

    for (var task in widget.tasks) {
      // Hiển thị task dựa trên endDate (deadline)
      if (task.endDate != null) {
        final date = DateTime(
          task.endDate!.year,
          task.endDate!.month,
          task.endDate!.day,
        );
        if (taskMap[date] == null) {
          taskMap[date] = [];
        }
        taskMap[date]!.add(task);
      }
    }

    return taskMap;
  }

  List<Task> _getTasksForDay(DateTime day) {
    final taskMap = _groupTasksByDate();
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return taskMap[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final selectedDayTasks = _selectedDay != null
        ? _getTasksForDay(_selectedDay!)
        : [];

    return Column(
      children: [
        // Calendar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? GlobalVariables.darkSurfaceCard
                : GlobalVariables.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? GlobalVariables.darkBorderPrimary
                  : GlobalVariables.borderPrimary,
            ),
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getTasksForDay,
            calendarStyle: CalendarStyle(
              // Today
              todayDecoration: BoxDecoration(
                color: GlobalVariables.primaryBlue.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
                fontWeight: FontWeight.w700,
              ),

              // Selected
              selectedDecoration: BoxDecoration(
                color: GlobalVariables.primaryBlue,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),

              // Default
              defaultTextStyle: TextStyle(
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),

              // Weekend
              weekendTextStyle: TextStyle(
                color: isDarkMode
                    ? GlobalVariables.darkSecondaryCoral
                    : GlobalVariables.secondaryCoral,
              ),

              // Outside
              outsideTextStyle: TextStyle(
                color: isDarkMode
                    ? GlobalVariables.darkTextTertiary
                    : GlobalVariables.textTertiary,
              ),

              // Markers
              markerDecoration: BoxDecoration(
                color: GlobalVariables.secondaryCoral,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 6,
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: true,
              titleTextStyle:
                  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : GlobalVariables.textPrimary,
                  ) ??
                  const TextStyle(),
              formatButtonTextStyle: TextStyle(
                color: GlobalVariables.primaryBlue,
                fontSize: 12,
              ),
              formatButtonDecoration: BoxDecoration(
                border: Border.all(
                  color: GlobalVariables.primaryBlue.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: isDarkMode
                    ? GlobalVariables.darkSecondaryCoral
                    : GlobalVariables.secondaryCoral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Tasks for selected day
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        _selectedDay != null
                            ? DateFormat('MMMM dd, yyyy').format(_selectedDay!)
                            : easy.tr('select_date'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? GlobalVariables.darkTextPrimary
                              : GlobalVariables.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selectedDayTasks.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: GlobalVariables.primaryBlue.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${selectedDayTasks.length}',
                            style: TextStyle(
                              color: GlobalVariables.primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: selectedDayTasks.isEmpty
                      ? _buildEmptyDayState(context)
                      : ListView.builder(
                          itemCount: selectedDayTasks.length,
                          itemBuilder: (context, index) {
                            final task = selectedDayTasks[index];
                            return TaskCard(
                              task: task,
                              onTap: () => _navigateToTaskDetail(task.id),
                              onStatusChanged: (isCompleted) =>
                                  _updateTaskStatus(task, isCompleted),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDayState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              easy.tr('no_tasks'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTaskDetail(String taskId) {
    Navigator.pushNamed(
      context,
      TaskDetailScreen.routeName,
      arguments: {'taskId': taskId},
    ).then((_) => widget.onRefresh());
  }

  void _updateTaskStatus(Task task, bool isCompleted) {
    final newStatus = isCompleted ? 'completed' : 'todo';
    TasksService.updateTask(
      context: context,
      taskId: task.id,
      status: newStatus,
      onSuccess: widget.onRefresh,
    );
  }
}
