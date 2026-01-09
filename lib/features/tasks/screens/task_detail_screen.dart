import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/common/widgets/task_card.dart';
import 'package:frontend/features/projects/services/projects_service.dart';
import 'package:frontend/features/tasks/screens/create_task_screen.dart';
import 'package:frontend/features/tasks/screens/edit_task_screen.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/features/tasks/widgets/assign_task_dialog.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TaskDetailScreen extends StatefulWidget {
  static const String routeName = '/task-detail';
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Task? _task;
  Project? _project;
  List<Task> _subtasks = [];
  bool _isLoading = true;
  bool _isLoadingSubtasks = false;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    setState(() => _isLoading = true);

    await TasksService.getTaskDetails(
      context: context,
      taskId: widget.taskId,
      onSuccess: (task) {
        setState(() {
          _task = task;
          _isLoading = false;
        });
        _loadProject();
        _loadSubtasks();
      },
    );
  }

  Future<void> _loadProject() async {
    if (_task == null) return;

    await ProjectsService.getProjectDetails(
      context: context,
      projectId: _task!.projectId,
      onSuccess: (project) {
        setState(() {
          _project = project;
        });
      },
    );
  }

  Future<void> _loadSubtasks() async {
    if (_task == null) return;

    setState(() => _isLoadingSubtasks = true);

    await TasksService.getProjectTasks(
      context: context,
      projectId: _task!.projectId,
      parentTaskId: _task!.id,
      includeSubtasks: false,
      onSuccess: (subtasks) {
        setState(() {
          _subtasks = subtasks;
          _isLoadingSubtasks = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: CustomAppBar(title: tr('project_detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_task == null) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: CustomAppBar(title: tr('project_detail')),
        body: Center(child: Text(tr('no_tasks'))),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      appBar: CustomAppBar(
        title: tr('task_detail'),
        actions: [
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'assign':
                    _showAssignTaskDialog();
                    break;
                  case 'edit':
                    _navigateToEditTask();
                    break;
                  case 'delete':
                    _showDeleteTaskDialog();
                    break;
                  case 'mark_completed':
                    _updateTaskStatus('completed');
                    break;
                  case 'mark_todo':
                    _updateTaskStatus('todo');
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                final currentUser = Provider.of<UserProvider>(
                  context,
                  listen: false,
                ).user;
                final isOwner = _project?.createdBy['id'] == currentUser.id;
                final currentUserMember = _project?.members.firstWhere(
                  (member) => member.userId == currentUser.id,
                  orElse: () => ProjectMember(
                    userId: currentUser.id,
                    role: 'Viewer',
                    permissions: ProjectPermissions(),
                    joinedAt: DateTime.now(),
                  ),
                );

                // Kiểm tra từng quyền
                final canAssign =
                    isOwner ||
                    (currentUserMember?.permissions.assignTask ?? false);
                final canEdit =
                    isOwner ||
                    (currentUserMember?.permissions.editTask ?? false);
                final canDelete =
                    isOwner ||
                    (currentUserMember?.permissions.deleteTask ?? false);
                final canMarkComplete =
                    isOwner ||
                    (currentUserMember?.permissions.markCompleteTask ?? false);

                List<PopupMenuEntry<String>> menuItems = [];

                // Edit Task
                if (canEdit) {
                  menuItems.add(
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: GlobalVariables.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(tr('edit')),
                        ],
                      ),
                    ),
                  );
                }

                // Mark Complete/Incomplete
                if (canMarkComplete) {
                  if (!_task!.isCompleted) {
                    menuItems.add(
                      PopupMenuItem<String>(
                        value: 'mark_completed',
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: GlobalVariables.successGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(tr('mark_complete')),
                          ],
                        ),
                      ),
                    );
                  } else {
                    menuItems.add(
                      PopupMenuItem<String>(
                        value: 'mark_todo',
                        child: Row(
                          children: [
                            Icon(
                              Icons.radio_button_unchecked_rounded,
                              color: GlobalVariables.warningAmber,
                            ),
                            const SizedBox(width: 8),
                            Text(tr('mark_incomplete')),
                          ],
                        ),
                      ),
                    );
                  }
                }

                // Assign Task
                if (canAssign && _project != null) {
                  menuItems.add(
                    PopupMenuItem<String>(
                      value: 'assign',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_add_alt_rounded,
                            color: GlobalVariables.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(tr('assign_task')),
                        ],
                      ),
                    ),
                  );
                }

                // Delete Task
                if (canDelete) {
                  menuItems.add(
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            color: GlobalVariables.errorRed,
                          ),
                          const SizedBox(width: 8),
                          Text(tr('delete_task')),
                        ],
                      ),
                    ),
                  );
                }

                return menuItems;
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadTaskDetails();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _task!.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? GlobalVariables.darkTextPrimary
                            : GlobalVariables.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: GlobalVariables.getStatusColor(
                        _task!.status,
                      ).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _task!.statusDisplayName,
                      style: TextStyle(
                        color: GlobalVariables.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Due Date và Priority
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 24,
                    color: isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tr('due_date')}:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkMode
                              ? GlobalVariables.darkTextSecondary
                              : GlobalVariables.textSecondary,
                        ),
                      ),
                      Text(
                        _task!.dueDate == null
                            ? tr('no_deadline')
                            : ' ${DateFormat('MMMM dd, yyyy').format(_task!.dueDate!)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkMode
                              ? GlobalVariables.darkTextSecondary
                              : GlobalVariables.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${tr('priority')}: ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDarkMode
                                ? GlobalVariables.darkTextSecondary
                                : GlobalVariables.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        TextSpan(
                          text: _task!.priorityDisplayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: GlobalVariables.getPriorityColor(
                              _task!.priority,
                            ),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                tr('description'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _task!.description == null || _task!.description!.isEmpty
                    ? tr('no_description')
                    : _task!.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode
                      ? GlobalVariables.darkTextSecondary
                      : GlobalVariables.textSecondary,
                  height: 1.5,
                ),
              ),

              // Project Info
              if (_project != null) ...[
                const SizedBox(height: 16),
                _buildInfoItem(
                  tr('belongs_to_project'),
                  _project!.title,
                  Icons.folder_rounded,
                  GlobalVariables.warningAmber,
                ),
              ],

              if (_task!.assignedTo.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildAssigneesSection(),
              ],
              const SizedBox(height: 24),

              // Progress
              Text(
                tr('progress'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_task!.progress}% ${tr('done')}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode
                          ? GlobalVariables.darkTextSecondary
                          : GlobalVariables.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _task!.progressPercentage,
                  backgroundColor: isDarkMode
                      ? GlobalVariables.darkBorderPrimary
                      : GlobalVariables.borderPrimary,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    GlobalVariables.primaryBlue,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 32),

              _buildSubtasksSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtasksSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Kiểm tra quyền create task
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    final isOwner = _project?.createdBy['id'] == currentUser.id;
    final currentUserMember = _project?.members.firstWhere(
      (member) => member.userId == currentUser.id,
      orElse: () => ProjectMember(
        userId: currentUser.id,
        role: 'Viewer',
        permissions: ProjectPermissions(),
        joinedAt: DateTime.now(),
      ),
    );
    final canCreateTask =
        isOwner || (currentUserMember?.permissions.createTask ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${tr('subtask')} (${_subtasks.length})',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
            ),
            if (_subtasks.isNotEmpty && canCreateTask)
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: GlobalVariables.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _navigateToCreateSubtask(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  iconSize: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingSubtasks)
          const Center(child: CircularProgressIndicator())
        else if (_subtasks.isEmpty)
          _buildEmptySubtasksState()
        else
          Column(
            children: _subtasks.map((subtask) {
              return TaskCard(
                task: subtask,
                onTap: () => _navigateToSubtaskDetail(subtask),
                onStatusChanged: (isCompleted) =>
                    _updateSubtaskStatus(subtask, isCompleted),
                showSubtaskCount: false,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAssigneesSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Phần tiêu đề "Assigned to" giữ nguyên ---
        Row(
          children: [
            Icon(
              Icons.people_rounded,
              size: 20,
              color: GlobalVariables.primaryBlue,
            ),
            const SizedBox(width: 6),
            Text(
              tr('assigned_to'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // --- Gọi widget hiển thị danh sách avatar kiểu mới ---
        _buildAssigneesDisplay(),
      ],
    );
  }

  Widget _buildAssigneesDisplay() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final List<dynamic> assignees = _task?.assignedTo ?? [];
    final maxDisplay = 4;
    final totalAssignees = assignees.length;

    final displayCount = totalAssignees > maxDisplay
        ? maxDisplay
        : totalAssignees;
    final remaining = totalAssignees - displayCount;

    return SizedBox(
      height: 70, // Đặt chiều cao cố định để chứa avatar và tên
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (totalAssignees > 0)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: GestureDetector(
                  onTap: () => _showAssigneesBottomSheet(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Render danh sách các avatar ---
                      ...List.generate(displayCount, (index) {
                        final user = assignees[index];

                        // Xử lý để chỉ lấy tên (từ đầu tiên)
                        final String fullName =
                            user['name'] as String? ?? 'User';
                        final String firstName = fullName
                            .trim()
                            .split(' ')
                            .first;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    (user['avatarColor'] as String? ??
                                            '#2196F3')
                                        .toColor(),
                                backgroundImage:
                                    user['avatar'] != null &&
                                        (user['avatar'] as String).isNotEmpty
                                    ? NetworkImage(user['avatar'] as String)
                                    : null,
                                child:
                                    (user['avatar'] == null ||
                                        (user['avatar'] as String).isEmpty)
                                    ? Text(
                                        fullName.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                firstName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? GlobalVariables.darkTextSecondary
                                      : GlobalVariables.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }),

                      // --- Render cục "+X" nếu còn ---
                      if (remaining > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: GlobalVariables.secondaryCoral,
                                child: Text(
                                  '+$remaining',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(' ', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode
                      ? GlobalVariables.darkTextSecondary
                      : GlobalVariables.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? GlobalVariables.darkTextPrimary
                : GlobalVariables.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySubtasksState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Kiểm tra quyền create task
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    final isOwner = _project?.createdBy['id'] == currentUser.id;
    final currentUserMember = _project?.members.firstWhere(
      (member) => member.userId == currentUser.id,
      orElse: () => ProjectMember(
        userId: currentUser.id,
        role: 'Viewer',
        permissions: ProjectPermissions(),
        joinedAt: DateTime.now(),
      ),
    );
    final canCreateTask =
        isOwner || (currentUserMember?.permissions.createTask ?? false);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add_rounded,
              size: 64,
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              tr('no_subtasks'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canCreateTask
                  ? tr('create_subtask_to_break_down')
                  : tr('no_subtasks_available'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextTertiary
                    : GlobalVariables.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (canCreateTask)
              ElevatedButton(
                onPressed: () => _navigateToCreateSubtask(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: GlobalVariables.primaryBlueLight.withValues(
                      alpha: 0.9,
                    ),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  tr('create_subtask'),
                  style: TextStyle(
                    color: GlobalVariables.primaryBlueLight.withValues(
                      alpha: 0.9,
                    ),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updateTaskStatus(String status) {
    TasksService.updateTask(
      context: context,
      taskId: _task!.id,
      status: status,
      onSuccess: () {
        _loadTaskDetails(); // Reload task để cập nhật UI
        _loadSubtasks(); // Reload subtasks nếu có
      },
    );
  }

  void _navigateToSubtaskDetail(Task subtask) {
    Navigator.pushNamed(
      context,
      TaskDetailScreen.routeName,
      arguments: {'taskId': subtask.id},
    ).then((_) {
      _loadSubtasks();
      _loadTaskDetails();
    });
  }

  void _updateSubtaskStatus(Task subtask, bool isCompleted) {
    final newStatus = isCompleted ? 'completed' : 'todo';
    TasksService.updateTask(
      context: context,
      taskId: subtask.id,
      status: newStatus,
      onSuccess: () {
        _loadSubtasks();
        _loadTaskDetails();
      },
    );
  }

  void _navigateToEditTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(task: _task!, project: _project),
      ),
    ).then((result) {
      if (result == true) {
        _loadTaskDetails();
      }
    });
  }

  void _navigateToCreateSubtask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskScreen(
          projectId: _task!.projectId,
          parentTaskId: _task!.id,
          project: _project,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadSubtasks();
        _loadTaskDetails();
      }
    });
  }

  void _showDeleteTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('confirm_delete')),
        content: Text(
          tr('confirm_delete_task', namedArgs: {'title': _task!.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTask();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalVariables.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
  }

  void _deleteTask() {
    TasksService.deleteTask(
      context: context,
      taskId: _task!.id,
      onSuccess: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _showAssignTaskDialog() {
    if (_task == null || _project == null) return;

    showDialog(
      context: context,
      builder: (context) => AssignTaskDialog(
        task: _task!,
        project: _project!,
        onAssigned: () {
          _loadTaskDetails(); // Reload task details after assigning
        },
      ),
    );
  }

  void _showAssigneesBottomSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? GlobalVariables.darkBorderPrimary
                    : GlobalVariables.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('assigned_to'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? GlobalVariables.darkTextPrimary
                          : GlobalVariables.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_task!.assignedTo.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 48,
                              color: isDarkMode
                                  ? GlobalVariables.darkTextTertiary
                                  : GlobalVariables.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tr('no_assignment'),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: isDarkMode
                                    ? GlobalVariables.darkTextTertiary
                                    : GlobalVariables.textTertiary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._task!.assignedTo.map((user) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: user['avatarColor']
                                  .toString()
                                  .toColor(),
                              backgroundImage:
                                  user['avatar'] != null &&
                                      user['avatar'].isNotEmpty
                                  ? NetworkImage(user['avatar'])
                                  : null,
                              child:
                                  user['avatar'] == null ||
                                      user['avatar'].isEmpty
                                  ? Text(
                                      (user['name'] ?? 'U')
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? tr('unknown'),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: isDarkMode
                                          ? GlobalVariables.darkTextPrimary
                                          : GlobalVariables.textPrimary,
                                    ),
                                  ),
                                  if (user['email'] != null &&
                                      user['email'].isNotEmpty)
                                    Text(
                                      user['email'],
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: isDarkMode
                                                ? GlobalVariables
                                                      .darkTextSecondary
                                                : GlobalVariables.textSecondary,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
