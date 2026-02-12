import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/common/widgets/task_card.dart';
import 'package:frontend/features/account/screens/profile_screen.dart';
import 'package:frontend/features/chat/screens/chat_room_screen.dart';
import 'package:frontend/features/notifications/services/invitation_service.dart';
import 'package:frontend/features/projects/services/projects_service.dart';
import 'package:frontend/features/projects/widgets/member_invitation_form.dart';
import 'package:frontend/features/projects/widgets/permissions_dialog.dart';
import 'package:frontend/features/projects/widgets/shift_project_dialog.dart';
import 'package:frontend/features/projects/widgets/project_activity_section.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/features/tasks/screens/task_detail_screen.dart';
import 'package:frontend/features/tasks/screens/create_task_screen.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class ProjectDetailScreen extends StatefulWidget {
  static const String routeName = '/project-detail';
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Project? _project;
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _isLoadingTasks = false;
  bool _isOwner = false;
  ProjectMember? _currentUserMember;
  final GlobalKey<ProjectActivitySectionState> _activitySectionKey =
      GlobalKey<ProjectActivitySectionState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild để cập nhật FAB visibility
    });
    _loadProjectDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectDetails() async {
    setState(() => _isLoading = true);

    await ProjectsService.getProjectDetails(
      context: context,
      projectId: widget.projectId,
      onSuccess: (project) {
        final currentUser = Provider.of<UserProvider>(
          context,
          listen: false,
        ).user;

        final isOwner = project.createdBy['id'] == currentUser.id;
        final currentUserMember = project.members.firstWhere(
          (member) => member.userId == currentUser.id,
          orElse: () => ProjectMember(
            userId: currentUser.id,
            role: 'Viewer',
            permissions: ProjectPermissions(),
            joinedAt: DateTime.now(),
          ),
        );

        // Set project first, then immediately start loading tasks
        _project = project;
        _isOwner = isOwner;
        _currentUserMember = currentUserMember;

        // Gọi load tasks ngay lập tức (không đợi setState rebuild)
        _loadTasks();

        // Sau đó mới setState để trigger rebuild
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _loadTasks() async {
    if (_project == null) return;

    setState(() => _isLoadingTasks = true);

    await TasksService.getProjectTasks(
      context: context,
      projectId: _project!.id,
      parentTaskId: null, // Chỉ lấy root tasks
      includeSubtasks: false, // Không lấy cây phân cấp
      onSuccess: (tasks) {
        setState(() {
          _tasks = tasks;
          _isLoadingTasks = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: CustomAppBar(title: tr('project_detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_project == null) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: CustomAppBar(title: tr('project_detail')),
        body: Center(child: Text(tr('no_projects'))),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      appBar: CustomAppBar(
        title: tr('project_detail'),
        centerTitle: true,
        actions: [
          // Nút mở chat
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: isDarkMode
                  ? GlobalVariables.darkTextPrimary
                  : GlobalVariables.textPrimary,
            ),
            onPressed: _navigateToProjectChat,
            tooltip: tr('group_chat'),
          ),
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
                  case 'edit':
                    _navigateToEditProject();
                    break;
                  case 'delete':
                    _showDeleteProjectDialog();
                    break;
                  case 'update_status':
                    _showUpdateStatusDialog();
                    break;
                  case 'leave':
                    _showLeaveProjectDialog();
                    break;
                  case 'shift_project':
                    _showShiftProjectDialog();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  if (_isOwner ||
                      _currentUserMember!.permissions.editProject) ...[
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
                    PopupMenuItem<String>(
                      value: 'update_status',
                      child: Row(
                        children: [
                          Icon(
                            Icons.update_rounded,
                            color: GlobalVariables.warningAmber,
                          ),
                          const SizedBox(width: 8),
                          Text(tr('update_status')),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'shift_project',
                      child: Row(
                        children: [
                          Icon(
                            Icons.fast_forward_rounded,
                            color: GlobalVariables.secondaryCoral,
                          ),
                          const SizedBox(width: 8),
                          Text(tr('shift_project')),
                        ],
                      ),
                    ),
                  ],
                  if (_isOwner) ...[
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            color: GlobalVariables.errorRed,
                          ),
                          const SizedBox(width: 8),
                          Text(tr('delete_project')),
                        ],
                      ),
                    ),
                  ],
                  if (!_isOwner) ...[
                    PopupMenuItem<String>(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: GlobalVariables.errorRed,
                          ),
                          const SizedBox(width: 8),
                          Text(tr('leave_project')),
                        ],
                      ),
                    ),
                  ],
                ];
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.transparent),
            child: TabBar(
              controller: _tabController,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 2.5, // mảnh nhưng vẫn nổi bật
                  color: GlobalVariables.primaryBlue,
                ),
                insets: EdgeInsets.symmetric(horizontal: 12),
              ),
              dividerColor: Colors.transparent,
              labelColor: GlobalVariables.primaryBlue,
              unselectedLabelColor: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: tr('overview')),
                Tab(text: tr('members')),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCombinedOverviewTab(_isOwner, _currentUserMember!),
                _buildMembersTab(_isOwner, _currentUserMember!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedOverviewTab(
    final bool isOwner,
    final ProjectMember currentUserMember,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final canCreateTask = isOwner || currentUserMember.permissions.createTask;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadProjectDetails();
        await _loadTasks();
      },
      child: SingleChildScrollView(
        //padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Project Title và Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _project!.title,
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
                            _project!.status,
                          ).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _project!.statusDisplayName,
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
                            '${tr('schedule')}:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: isDarkMode
                                  ? GlobalVariables.darkTextSecondary
                                  : GlobalVariables.textSecondary,
                            ),
                          ),
                          Text(
                            _project!.hasValidDates
                                ? '${DateFormat('dd/MM/yyyy').format(_project!.startDate!)} - ${DateFormat('dd/MM/yyyy').format(_project!.endDate!)}'
                                : tr('no_schedule'),
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
                              text: _project!.priorityDisplayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: GlobalVariables.getPriorityColor(
                                  _project!.priority,
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
                    _project!.description ?? tr('no_description'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode
                          ? GlobalVariables.darkTextSecondary
                          : GlobalVariables.textSecondary,
                      height: 1.5,
                      fontSize: 16,
                    ),
                  ),
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
                        '${_project!.progress}% ${tr('done')}',
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
                      value: _project!.progressPercentage,
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

                  // All Tasks Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('all_tasks'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? GlobalVariables.darkTextPrimary
                              : GlobalVariables.textPrimary,
                        ),
                      ),
                      if (_tasks.isNotEmpty && canCreateTask)
                        Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: GlobalVariables.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => _showCreateTaskDialog(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.add, color: Colors.white),
                            iconSize: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tasks List hoặc Empty State
                  if (_isLoadingTasks)
                    const Center(child: CircularProgressIndicator())
                  else if (_tasks.isEmpty)
                    _buildEmptyTasksState(isOwner, currentUserMember)
                  else
                    Column(
                      children: _tasks
                          .map((task) => _buildTaskCard(task))
                          .toList(),
                    ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 3),
            // Activity Log Section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ProjectActivitySection(
                key: _activitySectionKey,
                projectId: widget.projectId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab(
    final bool isOwner,
    final ProjectMember currentUserMember,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadProjectDetails,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Owner Section
            Text(
              tr('owner'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildOwnerCard(_project!.createdBy),
            const SizedBox(height: 24),

            // Members List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tr('members')} (${_project!.members.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : GlobalVariables.textPrimary,
                  ),
                ),
                if (isOwner || currentUserMember.permissions.addMember)
                  TextButton.icon(
                    onPressed: () => _showAddMemberDialog(),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: Text(tr('add')),
                    style: TextButton.styleFrom(
                      foregroundColor: GlobalVariables.primaryBlue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_project!.members.isEmpty)
              _buildEmptyMembersState()
            else
              ...List.generate(_project!.members.length, (index) {
                final member = _project!.members[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMemberCard(
                    member: member,
                    currentUserMember: currentUserMember,
                    isOwner: isOwner,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return TaskCard(
      task: task,
      onTap: () => _navigateToTaskDetail(task),
      onStatusChanged: (isCompleted) => _updateTaskStatus(task, isCompleted),
    );
  }

  void _navigateToTaskDetail(Task task) {
    Navigator.pushNamed(
      context,
      TaskDetailScreen.routeName,
      arguments: {'taskId': task.id},
    ).then((_) {
      // Chỉ reload data khi cần thiết - gọi hàm kết hợp để tránh N+1 calls
      _refreshAfterTaskChange();
    });
  }

  void _updateTaskStatus(Task task, bool isCompleted) {
    TasksService.markCompleteTask(
      context: context,
      taskId: task.id,
      isCompleted: isCompleted,
      onSuccess: () async {
        await _refreshAfterTaskChange();
        _activitySectionKey.currentState?.refreshActivity();
      },
    );
  }

  /// Hàm kết hợp để refresh data sau khi có thay đổi task
  /// Gọi song song cả tasks và project details để tối ưu hiệu năng
  Future<void> _refreshAfterTaskChange() async {
    // Gọi song song cả hai để giảm thời gian chờ
    await Future.wait([_loadTasks(), _loadProjectDetails()]);
  }

  Widget _buildEmptyTasksState(
    final bool isOwner,
    final ProjectMember currentUserMember,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final canCreateTask = isOwner || currentUserMember.permissions.createTask;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_rounded,
              size: 64,
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              tr('no_tasks'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canCreateTask
                  ? tr('create_first_task')
                  : tr('no_tasks_available'),
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
                onPressed: () => _showCreateTaskDialog(),
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
                  tr('create_new_task'),
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

  Widget _buildOwnerCard(Map<String, dynamic> owner) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? GlobalVariables.darkSurfaceCard
            : GlobalVariables.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: owner['avatarColor'].toString().toColor(),
            backgroundImage:
                owner['avatar'] != null && owner['avatar']!.isNotEmpty
                ? NetworkImage(owner['avatar'])
                : null,
            child: owner['avatar'] == null || owner['avatar'].isEmpty
                ? Text(
                    owner['name'].isNotEmpty
                        ? owner['name'][0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: GlobalVariables.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        owner['name'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? GlobalVariables.darkTextPrimary
                              : GlobalVariables.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: GlobalVariables.primaryBlue.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tr('owner'),
                        style: TextStyle(
                          color: GlobalVariables.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  owner['email'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('has_all_permissions'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: GlobalVariables.primaryBlue,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard({
    required ProjectMember member,
    required ProjectMember currentUserMember,
    required bool isOwner,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? GlobalVariables.darkSurfaceCard
            : GlobalVariables.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              ProfileScreen.routeName,
              arguments: member.userId,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: member.avatarColor!.toColor(),
                      backgroundImage:
                          member.avatar != null && member.avatar!.isNotEmpty
                          ? NetworkImage(member.avatar!)
                          : null,
                      child: member.avatar == null || member.avatar!.isEmpty
                          ? Text(
                              member.userName != null &&
                                      member.userName!.isNotEmpty
                                  ? member.userName![0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  member.userName ?? tr('user'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? GlobalVariables.darkTextPrimary
                                        : GlobalVariables.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(
                                    member.role,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getRoleColor(
                                      member.role,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  member.roleDisplayName,
                                  style: TextStyle(
                                    color: _getRoleColor(member.role),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (member.userEmail != null)
                            Text(
                              member.userEmail!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDarkMode
                                    ? GlobalVariables.darkTextSecondary
                                    : GlobalVariables.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Actions menu - CHỈ hiện nếu có quyền editRole hoặc removeMember
                    // Nếu membercard này là current user thì không hiện menu
                    if ((member.userId != currentUserMember.userId) &&
                        (isOwner ||
                            currentUserMember.permissions.editRole ||
                            currentUserMember.permissions.removeMember))
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: isDarkMode
                              ? GlobalVariables.darkTextSecondary
                              : GlobalVariables.textSecondary,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'permissions':
                              _showPermissionsDialog(member, currentUserMember);
                              break;
                            case 'remove':
                              _showRemoveMemberDialog(member);
                              break;
                          }
                        },
                        itemBuilder: (context) {
                          // Tạo danh sách menu items dựa trên quyền
                          List<PopupMenuEntry<String>> menuItems = [];

                          // Chỉ hiện Manage Role nếu có quyền editRole
                          if (isOwner ||
                              currentUserMember.permissions.editRole) {
                            menuItems.add(
                              PopupMenuItem(
                                value: 'permissions',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings_rounded,
                                      color: GlobalVariables.primaryBlue,
                                    ),
                                    SizedBox(width: 8),
                                    Text(tr('manage_role_permissions')),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Chỉ hiện Remove nếu có quyền removeMember
                          if (isOwner ||
                              currentUserMember.permissions.removeMember) {
                            menuItems.add(
                              PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_remove_rounded,
                                      color: GlobalVariables.errorRed,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      tr('remove_from_project'),
                                      style: TextStyle(
                                        color: GlobalVariables.errorRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return menuItems;
                        },
                      ),
                  ],
                ),

                // Permissions (nếu có quyền)
                if (member.permissions.hasAnyPermission) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GlobalVariables.primaryBlue.withValues(
                        alpha: 0.05,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: GlobalVariables.primaryBlue.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('permissions'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: GlobalVariables.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: member.permissions.permissionsList
                              .map(
                                (permission) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GlobalVariables.primaryBlue
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    permission,
                                    style: TextStyle(
                                      color: GlobalVariables.primaryBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    tr('can_only_complete_tasks'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDarkMode
                          ? GlobalVariables.darkTextTertiary
                          : GlobalVariables.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMembersState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 48,
            color: isDarkMode
                ? GlobalVariables.darkTextTertiary
                : GlobalVariables.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            tr('no_members'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('add_members_to_collaborate'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    tr('add_member'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              MemberInvitationForm(
                showSubmitButton: true,
                submitButtonText: tr('add_member'),
                onSubmit: (emails, message) async {
                  Navigator.pop(context); // Đóng dialog

                  int successCount = 0;
                  for (String email in emails) {
                    await InvitationService.sendInvitation(
                      context: context,
                      email: email,
                      projectId: _project!.id,
                      message: message.isNotEmpty ? message : null,
                      onSuccess: () {
                        successCount++;
                      },
                    );
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr(
                            'success_invitations_sent',
                            namedArgs: {
                              'count': '$successCount',
                              'total': '${emails.length}',
                            },
                          ),
                        ),
                        backgroundColor: GlobalVariables.successGreen,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('leave_project')),
        content: Text(tr('confirm_leave_project')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _leaveProject,
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalVariables.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text(tr('leave_project')),
          ),
        ],
      ),
    );
  }

  void _leaveProject() {
    Navigator.of(context).pop();
    ProjectsService.leaveProject(
      context: context,
      projectId: _project!.id,
      onSuccess: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _showPermissionsDialog(
    ProjectMember member,
    ProjectMember currentUserMember,
  ) {
    showDialog(
      context: context,
      builder: (context) => PermissionsDialog(
        member: member,
        currentUserMember: currentUserMember,
        projectId: _project!.id,
        onPermissionsUpdated: () {
          _loadProjectDetails(); // Reload project to get updated permissions
        },
      ),
    );
  }

  void _showRemoveMemberDialog(ProjectMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('confirm_delete')),
        content: Text(
          tr(
            'confirm_remove_member',
            namedArgs: {'name': member.userName ?? tr('user')},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeMember(member);
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

  void _removeMember(ProjectMember member) {
    ProjectsService.removeMemberFromProject(
      context: context,
      projectId: _project!.id,
      userId: member.userId,
      onSuccess: () {
        _loadProjectDetails(); // Reload project after removing member
      },
    );
  }

  void _showCreateTaskDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateTaskScreen(projectId: _project!.id, project: _project),
      ),
    ).then((result) {
      if (result == true) {
        _loadTasks(); // Reload tasks after creating
        _loadProjectDetails(); // Reload project để cập nhật progress
      }
    });
  }

  void _navigateToProjectChat() {
    if (_project == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          projectId: _project!.id,
          projectTitle: _project!.title,
        ),
      ),
    );
  }

  void _navigateToEditProject() {
    Navigator.pushNamed(context, '/edit-project', arguments: _project).then((
      result,
    ) {
      if (result == true) {
        _loadProjectDetails(); // Reload project after edit
      }
    });
  }

  void _showDeleteProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('confirm_delete')),
        content: Text(
          tr('confirm_delete_project', namedArgs: {'title': _project!.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProject();
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

  void _deleteProject() {
    ProjectsService.deleteProject(
      context: context,
      projectId: _project!.id,
      onSuccess: () {
        if (mounted) {
          Navigator.of(context).pop(); // Quay lại projects screen
        }
      },
    );
  }

  void _showUpdateStatusDialog() {
    final statusOptions = [
      {'value': 'Planning', 'label': tr('planning')},
      {'value': 'In-progress', 'label': tr('in_progress')},
      {'value': 'Completed', 'label': tr('completed')},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('update_status')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusOptions.map((option) {
            final isSelected = _project!.status == option['value'];
            return RadioListTile<String>(
              title: Text(option['label']!),
              value: option['value']!,
              groupValue: _project!.status,
              onChanged: (value) {
                Navigator.of(context).pop();
                _updateProjectStatus(value!);
              },
              activeColor: GlobalVariables.primaryBlue,
              selected: isSelected,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
        ],
      ),
    );
  }

  void _updateProjectStatus(String newStatus) {
    ProjectsService.updateProject(
      context: context,
      projectId: _project!.id,
      status: newStatus,
      onSuccess: () {
        _loadProjectDetails(); // Reload project after status update
      },
    );
  }

  void _showShiftProjectDialog() {
    if (_project == null) return;

    showDialog(
      context: context,
      builder: (context) => ShiftProjectDialog(
        project: _project!,
        onShifted: () {
          _loadProjectDetails();
          _loadTasks();
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Manager':
        return GlobalVariables.primaryBlue;
      case 'Member':
        return GlobalVariables.successGreen;
      case 'Viewer':
        return GlobalVariables.textSecondary;
      case 'Custom Role':
        return GlobalVariables.warningAmber;
      default:
        return GlobalVariables.textSecondary;
    }
  }
}
