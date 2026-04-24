import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/common/widgets/task_card.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:frontend/features/account/screens/profile_screen.dart';
import 'package:frontend/features/account/services/account_service.dart';
import 'package:frontend/features/chat/screens/chat_room_screen.dart';
import 'package:frontend/features/notifications/services/notification_service.dart';
import 'package:frontend/features/projects/services/projects_service.dart';
import 'package:frontend/features/projects/widgets/member_invitation_form.dart';
import 'package:frontend/features/projects/widgets/permissions_dialog.dart';
import 'package:frontend/features/projects/widgets/shift_project_dialog.dart';
import 'package:frontend/features/projects/widgets/project_activity_section.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/features/tasks/screens/task_detail_screen.dart';
import 'package:frontend/features/tasks/screens/create_task_screen.dart';
import 'package:frontend/features/tasks/screens/list_tasks_filter.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:frontend/common/widgets/premium_feature_gate.dart';

class ProjectDetailScreen extends StatefulWidget {
  static const String routeName = '/project-detail';
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  final AccountService _accountService = AccountService();
  late TabController _tabController;
  final TextEditingController _memberSearchController = TextEditingController();
  final FocusNode _memberSearchFocusNode = FocusNode();
  Project? _project;
  ProjectAnalytics? _analytics;
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _isLoadingTasks = false;
  bool _isLoadingAnalytics = false;
  bool _isOwner = false;
  bool _showMemberSearch = false;
  String? _pressedTagKey;
  String? _activeTagActionKey;
  ProjectMember? _currentUserMember;
  final GlobalKey<ProjectActivitySectionState> _activitySectionKey =
      GlobalKey<ProjectActivitySectionState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild để cập nhật FAB visibility
    });
    _loadProjectDetails();
  }

  @override
  void dispose() {
    _memberSearchFocusNode.dispose();
    _memberSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectDetails() async {
    setState(() => _isLoading = true);

    await ProjectsService.getProjectDetails(
      context: context,
      projectId: widget.projectId,
      onSuccess: (project) {
        _applyProjectData(project);

        _loadTasks();
        _loadAnalytics();

        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  /// Silent refresh - cập nhật project mà không hiển thị full-screen loading
  Future<void> _refreshProject() async {
    await ProjectsService.getProjectDetails(
      context: context,
      projectId: widget.projectId,
      onSuccess: (project) {
        if (mounted) {
          _applyProjectData(project);
          setState(() {});
        }
      },
    );
  }

  void _applyProjectData(Project project) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;

    _project = project;
    _isOwner = project.createdBy['id'] == currentUser.id;
    _currentUserMember = project.members.firstWhere(
      (member) => member.userId == currentUser.id,
      orElse: () => ProjectMember(
        userId: currentUser.id,
        role: 'Viewer',
        permissions: ProjectPermissions(),
        joinedAt: DateTime.now(),
      ),
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

  Future<void> _loadAnalytics() async {
    if (_project == null) return;

    setState(() => _isLoadingAnalytics = true);

    await ProjectsService.getProjectAnalytics(
      context: context,
      projectId: _project!.id,
      onSuccess: (analytics) {
        if (!mounted) return;
        setState(() {
          _analytics = analytics;
          _isLoadingAnalytics = false;
        });
      },
    );

    if (mounted && _isLoadingAnalytics) {
      setState(() => _isLoadingAnalytics = false);
    }
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
          if (_project?.isPremium == true)
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
                      _currentUserMember!
                          .permissions
                          .editProjectPermission) ...[
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
                //insets: EdgeInsets.symmetric(horizontal: 12),
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
                Tab(text: tr('analytics')),
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
                _buildAnalyticsTab(),
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

    final canCreateTask =
        isOwner || currentUserMember.permissions.createTaskPermission;
    final canManageTags =
        isOwner || currentUserMember.permissions.editProjectPermission;

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
                      if (_project!.isPremium)
                        SvgPicture.asset(
                          'assets/images/premium_1.svg',
                          width: 32,
                          height: 32,
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
                      const Spacer(),
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
                  const SizedBox(height: 18),

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
                  const SizedBox(height: 18),
                  _buildProjectTagsSection(
                    theme: theme,
                    isDarkMode: isDarkMode,
                    canManageTags: canManageTags,
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

  Widget _buildProjectTagsSection({
    required ThemeData theme,
    required bool isDarkMode,
    required bool canManageTags,
  }) {
    final tags = _project!.tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    const int maxVisibleTags = 6;
    final visibleCount = math.min(maxVisibleTags, tags.length);
    final hasMoreTags = tags.length > maxVisibleTags;
    final remainingTags = tags.length - visibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('project_tags_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? GlobalVariables.darkTextPrimary
                : GlobalVariables.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...List.generate(
              visibleCount,
              (index) => _buildProjectTagChip(
                index: index,
                tag: tags[index],
                isDarkMode: isDarkMode,
                canManageTags: canManageTags,
              ),
            ),
            if (hasMoreTags)
              _buildRemainingTagsCircle(
                remainingCount: remainingTags,
                isDarkMode: isDarkMode,
                allTags: tags,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectTagChip({
    required int index,
    required String tag,
    required bool isDarkMode,
    required bool canManageTags,
  }) {
    final key = '$index::$tag';
    final isPressed = _pressedTagKey == key;
    final showActions = _activeTagActionKey == key && canManageTags;

    final baseColor = isDarkMode
        ? GlobalVariables.darkSurfaceCard
        : GlobalVariables.surfaceCard;
    final borderColor = showActions
        ? GlobalVariables.primaryBlue
        : (isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isPressed
            ? GlobalVariables.primaryBlue.withValues(alpha: 0.14)
            : baseColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          splashColor: GlobalVariables.primaryBlue.withValues(alpha: 0.18),
          highlightColor: GlobalVariables.primaryBlue.withValues(alpha: 0.08),
          onHighlightChanged: (value) {
            if (!mounted) return;
            setState(() {
              _pressedTagKey = value ? key : null;
            });
          },
          onTap: () {
            if (_activeTagActionKey != null) {
              setState(() => _activeTagActionKey = null);
            }
          },
          onLongPress: canManageTags
              ? () {
                  setState(() {
                    _activeTagActionKey = _activeTagActionKey == key
                        ? null
                        : key;
                  });
                }
              : null,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 8, showActions ? 6 : 12, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sell_rounded,
                  size: 16,
                  color: GlobalVariables.greyDark.withValues(alpha: 0.84),
                ),
                const SizedBox(width: 6),
                Text(
                  tag,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showActions) ...[
                  const SizedBox(width: 6),
                  _buildTagActionIcon(
                    icon: Icons.edit_outlined,
                    tooltip: tr('edit'),
                    color: GlobalVariables.primaryBlue,
                    onPressed: () => _showEditTagDialog(index, tag),
                  ),
                  const SizedBox(width: 2),
                  _buildTagActionIcon(
                    icon: Icons.close_rounded,
                    tooltip: tr('delete'),
                    color: GlobalVariables.errorRed,
                    onPressed: () => _removeTag(index),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagActionIcon({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildRemainingTagsCircle({
    required int remainingCount,
    required bool isDarkMode,
    required List<String> allTags,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _showAllTagsBottomSheet(allTags),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkMode
                ? GlobalVariables.darkSurfaceCard
                : GlobalVariables.surfaceCard,
            border: Border.all(
              color: isDarkMode
                  ? GlobalVariables.darkBorderPrimary
                  : GlobalVariables.borderPrimary,
            ),
          ),
          child: Center(
            child: Text(
              '+$remainingCount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAllTagsBottomSheet(List<String> tags) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isDarkMode
                          ? GlobalVariables.darkBorderPrimary
                          : GlobalVariables.borderPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  tr(
                    'project_all_tags_count',
                    namedArgs: {'count': '${tags.length}'},
                  ),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : GlobalVariables.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? GlobalVariables.darkSurfaceCard
                                    : GlobalVariables.surfaceCard,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isDarkMode
                                      ? GlobalVariables.darkBorderPrimary
                                      : GlobalVariables.borderPrimary,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.sell_rounded,
                                    size: 16,
                                    color: GlobalVariables.greyDark.withValues(
                                      alpha: 0.84,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tag,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: isDarkMode
                                              ? GlobalVariables
                                                    .darkTextSecondary
                                              : GlobalVariables.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditTagDialog(int index, String tag) {
    final controller = TextEditingController(text: tag);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${tr('edit')}: #$tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: tr('project_tag_name_hint'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final newTag = controller.text.trim();
              if (newTag.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('project_tag_cannot_empty'))),
                );
                return;
              }

              final hasDuplicate = _project!.tags.asMap().entries.any((entry) {
                return entry.key != index &&
                    entry.value.toLowerCase() == newTag.toLowerCase();
              });

              if (hasDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('project_tag_already_exists'))),
                );
                return;
              }

              Navigator.of(dialogContext).pop();
              _editTag(index, newTag);
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }

  void _editTag(int index, String newTag) {
    if (_project == null) return;
    if (index < 0 || index >= _project!.tags.length) return;

    final previousProject = _project!;
    final updatedTags = List<String>.from(previousProject.tags);
    updatedTags[index] = newTag;

    setState(() {
      _project = previousProject.copyWith(tags: updatedTags);
      _activeTagActionKey = null;
      _pressedTagKey = null;
    });

    ProjectsService.updateProject(
      context: context,
      projectId: previousProject.id,
      tags: updatedTags,
      onSuccess: () {
        _refreshProject();
        _activitySectionKey.currentState?.refreshActivity();
      },
      onError: () {
        if (mounted) {
          setState(() {
            _project = previousProject;
            _activeTagActionKey = null;
            _pressedTagKey = null;
          });
        }
      },
    );
  }

  void _removeTag(int index) {
    if (_project == null) return;
    if (index < 0 || index >= _project!.tags.length) return;

    final previousProject = _project!;
    final updatedTags = List<String>.from(previousProject.tags)
      ..removeAt(index);

    setState(() {
      _project = previousProject.copyWith(tags: updatedTags);
      _activeTagActionKey = null;
      _pressedTagKey = null;
    });

    ProjectsService.updateProject(
      context: context,
      projectId: previousProject.id,
      tags: updatedTags,
      onSuccess: () {
        _refreshProject();
        _activitySectionKey.currentState?.refreshActivity();
      },
      onError: () {
        if (mounted) {
          setState(() {
            _project = previousProject;
            _activeTagActionKey = null;
            _pressedTagKey = null;
          });
        }
      },
    );
  }

  Widget _buildMembersTab(
    final bool isOwner,
    final ProjectMember currentUserMember,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final searchKeyword = _showMemberSearch
        ? _memberSearchController.text.trim().toLowerCase()
        : '';
    final filteredMembers = _project!.members.where((member) {
      if (searchKeyword.isEmpty) return true;

      final name = (member.userName ?? '').toLowerCase();
      final email = (member.userEmail ?? '').toLowerCase();
      return name.contains(searchKeyword) || email.contains(searchKeyword);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadProjectDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() => _showMemberSearch = true);
                          Future.microtask(
                            () => _memberSearchFocusNode.requestFocus(),
                          );
                        },
                        icon: Icon(
                          Icons.search_rounded,
                          color: Color(0xFF6B7280),
                        ),
                        tooltip: tr('search_member_name_email'),
                      ),
                      if (isOwner ||
                          currentUserMember.permissions.addMemberPermission)
                        TextButton.icon(
                          onPressed: () {
                            if (_project?.isPremium != true &&
                                (_project?.members.length ?? 0) >= 5) {
                              PremiumFeatureGate.show(
                                context,
                                feature: tr('add_member'),
                                description: tr(
                                  'premium_project_member_limit_description',
                                ),
                              );
                              return;
                            }
                            _showAddMemberDialog();
                          },
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: Text(tr('add')),
                          style: TextButton.styleFrom(
                            foregroundColor: GlobalVariables.primaryBlue,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_showMemberSearch) ...[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F7),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: TextField(
                    focusNode: _memberSearchFocusNode,
                    controller: _memberSearchController,
                    onChanged: (_) => setState(() {}),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: tr('search_member_name_email'),
                      prefixIcon: IconButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          _memberSearchController.clear();
                          setState(() => _showMemberSearch = false);
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: tr('cancel'),
                        color: const Color(0xFF6B7280),
                      ),
                      suffixIcon: _memberSearchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _memberSearchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                              tooltip: tr('clear_filter'),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_project!.members.isEmpty)
                _buildEmptyMembersState()
              else if (filteredMembers.isEmpty)
                _buildEmptyMemberSearchState(searchKeyword)
              else
                ...List.generate(filteredMembers.length, (index) {
                  final member = filteredMembers[index];
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
      ),
    );
  }

  Widget _buildEmptyMemberSearchState(String keyword) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: isDarkMode
                ? GlobalVariables.darkTextTertiary
                : GlobalVariables.textTertiary,
          ),
          const SizedBox(height: 10),
          Text(
            tr('no_members_found'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('no_members_match_keyword', namedArgs: {'keyword': keyword}),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await _loadProjectDetails();
        await _loadAnalytics();
      },
      child: _isLoadingAnalytics
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Text(
                    tr('no_tasks'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode
                          ? GlobalVariables.darkTextSecondary
                          : GlobalVariables.textSecondary,
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricsCards(theme, isDarkMode),
                  const SizedBox(height: 20),
                  _buildStatusOverviewCard(theme, isDarkMode),
                  const SizedBox(height: 20),
                  _buildTeamWorkloadCard(theme, isDarkMode),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricsCards(ThemeData theme, bool isDarkMode) {
    final metrics = _analytics!.metrics;

    final cards = <Map<String, dynamic>>[
      {
        'title': '${metrics.doneLast7Days.count} ${tr('done')}',
        'subtitle': tr('in_last_7_days'),
        'icon': Symbols.check_rounded,
        'color': GlobalVariables.successGreen,
        'taskIds': metrics.doneLast7Days.taskIds,
      },
      {
        'title': '${metrics.updatedLast7Days.count} ${tr('updated')}',
        'subtitle': tr('in_last_7_days'),
        'icon': Symbols.edit,
        'color': GlobalVariables.primaryBlue,
        'taskIds': metrics.updatedLast7Days.taskIds,
      },
      {
        'title': '${metrics.createdLast7Days.count} ${tr('created')}',
        'subtitle': tr('in_last_7_days'),
        'icon': Symbols.add_rounded,
        'color': const Color(0xFF8E44AD),
        'taskIds': metrics.createdLast7Days.taskIds,
      },
      {
        'title': '${metrics.dueSoonNext7Days.count} ${tr('due')}',
        'subtitle': tr('in_next_7_days'),
        'icon': Symbols.calendar_today,
        'color': Colors.blueGrey,
        'taskIds': metrics.dueSoonNext7Days.taskIds,
      },
      {
        'title': '${metrics.blockedTasks.count} ${tr('blocked')}',
        'subtitle': tr('blocked_tasks_subtitle'),
        'icon': Symbols.block,
        'color': GlobalVariables.orangeBadge,
        'taskIds': metrics.blockedTasks.taskIds,
      },
      {
        'title': '${metrics.dependencyViolations.count} ${tr('violations')}',
        'subtitle': tr('dependency_violations_subtitle'),
        'icon': Symbols.warning_rounded,
        'color': GlobalVariables.redPinkBadge,
        'taskIds': metrics.dependencyViolations.taskIds,
      },
    ];

    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.22,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openFilteredTasks(
            card['title'] as String,
            List<String>.from(card['taskIds'] as List),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: (card['color'] as Color).withValues(
                    alpha: 0.15,
                  ),
                  child: Icon(
                    card['icon'] as IconData,
                    size: 20,
                    weight: 700,
                    color: card['color'] as Color,
                  ),
                ),
                const Spacer(),
                Text(
                  card['title'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: card['color'] as Color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card['subtitle'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusOverviewCard(ThemeData theme, bool isDarkMode) {
    final overview = _analytics!.statusOverview;
    final total = overview.total;

    final sections = overview.buckets
        .where((bucket) => bucket.count > 0)
        .map(
          (bucket) => PieChartSectionData(
            value: bucket.count.toDouble(),
            color: _statusColor(bucket.status),
            radius: 35,
            showTitle: false,
          ),
        )
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('status_overview'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextPrimary
                  : GlobalVariables.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('in_last_14_days'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w300,
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 70,
                    sections: sections.isEmpty
                        ? [
                            PieChartSectionData(
                              value: 1,
                              color: GlobalVariables.borderPrimary,
                              radius: 35,
                              showTitle: false,
                            ),
                          ]
                        : sections,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? GlobalVariables.darkTextPrimary
                            : GlobalVariables.textPrimary,
                      ),
                    ),
                    Text(
                      tr('total_work_items'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? GlobalVariables.darkTextSecondary
                            : GlobalVariables.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...overview.buckets.map(
            (bucket) => InkWell(
              onTap: () => _openFilteredTasks(
                _statusLabel(bucket.status),
                bucket.taskIds,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(bucket.status),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusLabel(bucket.status),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDarkMode
                              ? GlobalVariables.darkTextPrimary
                              : GlobalVariables.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${bucket.count}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDarkMode
                            ? GlobalVariables.darkTextSecondary
                            : GlobalVariables.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDarkMode
                          ? GlobalVariables.darkTextSecondary
                          : GlobalVariables.textSecondary,
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

  Widget _buildTeamWorkloadCard(ThemeData theme, bool isDarkMode) {
    final workload = _analytics!.teamWorkload.members;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, left: 16, right: 6, bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('team_workload'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextPrimary
                  : GlobalVariables.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('team_workload_description'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...workload.map((member) {
            final displayName = _getFirstNameToken(member.name);
            final isUnassigned = member.userId == null;
            final ImageProvider<Object>? avatarImage = isUnassigned
                ? const AssetImage('assets/images/avatar.png')
                : (member.avatar.isNotEmpty
                      ? NetworkImage(member.avatar)
                      : null);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: isUnassigned
                        ? Colors.transparent
                        : member.avatarColor.toColor(),
                    backgroundImage: avatarImage,
                    child: (!isUnassigned && member.avatar.isEmpty)
                        ? Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        color: isDarkMode
                            ? GlobalVariables.darkTextPrimary
                            : GlobalVariables.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          _openFilteredTasks(member.name, member.taskIds),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final clampedPercentage = member.percentage
                                .clamp(0, 100)
                                .toInt();
                            final widthFactor = clampedPercentage / 100;
                            final isDarkSegmentLabel = clampedPercentage >= 20;
                            final filledWidth =
                                constraints.maxWidth * widthFactor;
                            const horizontalLabelPadding = 10.0;
                            final lightSegmentLeft =
                                filledWidth + horizontalLabelPadding;
                            final labelLeft = isDarkSegmentLabel
                                ? horizontalLabelPadding
                                : lightSegmentLeft;

                            return Stack(
                              children: [
                                Container(
                                  height: 30,
                                  width: double.infinity,
                                  color: isDarkMode
                                      ? GlobalVariables.darkBorderPrimary
                                      : GlobalVariables.borderPrimary,
                                ),
                                FractionallySizedBox(
                                  widthFactor: widthFactor,
                                  child: Container(
                                    height: 30,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  left: labelLeft,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '$clampedPercentage%',
                                      style: TextStyle(
                                        color: isDarkSegmentLabel
                                            ? Colors.white
                                            : (isDarkMode
                                                  ? GlobalVariables
                                                        .darkTextPrimary
                                                  : GlobalVariables
                                                        .textPrimary),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openFilteredTasks(String title, List<String> taskIds) {
    Navigator.pushNamed(
      context,
      ListTasksFilterScreen.routeName,
      arguments: {
        'projectId': _project!.id,
        'title': title,
        'taskIds': taskIds,
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in-progress':
        return GlobalVariables.blueBadge;
      case 'completed':
        return GlobalVariables.greenBadge;
      case 'todo':
      default:
        return GlobalVariables.purpleBadge;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in-progress':
        return tr('in_progress');
      case 'completed':
        return tr('completed');
      case 'todo':
      default:
        return tr('todo');
    }
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
      _refreshAfterTaskChange();
      _activitySectionKey.currentState?.refreshActivity();
    });
  }

  void _updateTaskStatus(Task task, bool isCompleted) {
    final previousTasks = List<Task>.from(_tasks);

    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          status: isCompleted ? 'completed' : 'todo',
          progress: isCompleted ? 100 : 0,
        );
      }
    });

    TasksService.markCompleteTask(
      context: context,
      taskId: task.id,
      isCompleted: isCompleted,
      onSuccess: () {
        _refreshAfterTaskChange();
        _activitySectionKey.currentState?.refreshActivity();
      },
      onError: () {
        if (mounted) {
          setState(() => _tasks = previousTasks);
        }
      },
    );
  }

  /// Refresh song song tasks, project, analytics mà không full-screen loading
  Future<void> _refreshAfterTaskChange() async {
    await Future.wait([_loadTasks(), _refreshProject(), _loadAnalytics()]);
  }

  Widget _buildEmptyTasksState(
    final bool isOwner,
    final ProjectMember currentUserMember,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final canCreateTask =
        isOwner || currentUserMember.permissions.createTaskPermission;

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
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    final ownerId = owner['id']?.toString();
    final canOpenProfile = ownerId != null && ownerId != currentUser.id;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: canOpenProfile
            ? () {
                Navigator.pushNamed(
                  context,
                  ProfileScreen.routeName,
                  arguments: ownerId,
                );
              }
            : null,
        child: Container(
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? GlobalVariables.darkTextPrimary
                                  : GlobalVariables.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tr('owner'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      owner['email'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        ),
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? GlobalVariables.darkTextPrimary
                                        : GlobalVariables.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(member.role),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  member.roleDisplayName,
                                  style: TextStyle(
                                    color: Colors.white,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDarkMode
                                    ? GlobalVariables.darkTextSecondary
                                    : GlobalVariables.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Actions menu
                    if (isOwner ||
                        currentUserMember.permissions.manageAccessPermission ||
                        currentUserMember.permissions.removeMemberPermission ||
                        member.userId == currentUserMember.userId)
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
                          final canManageAccess =
                              isOwner ||
                              currentUserMember
                                  .permissions
                                  .manageAccessPermission;
                          final canRemoveMember =
                              (isOwner ||
                                  currentUserMember
                                      .permissions
                                      .removeMemberPermission) &&
                              (isOwner || !member.isManager);
                          final isSelf =
                              member.userId == currentUserMember.userId;

                          // Tạo danh sách menu items dựa trên quyền
                          List<PopupMenuEntry<String>> menuItems = [];

                          // Hiện dialog permissions khi có quyền manageAccess hoặc là chính mình
                          if (canManageAccess || isSelf) {
                            menuItems.add(
                              PopupMenuItem(
                                value: 'permissions',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      color: GlobalVariables.primaryBlue,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      canManageAccess
                                          ? tr('manage_role_permissions')
                                          : tr('permissions'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Chỉ hiện Remove nếu có quyền removeMember
                          // Member/Manager không được remove Manager, chỉ Owner mới được
                          if (canRemoveMember) {
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
      builder: (dialogContext) {
        final media = MediaQuery.of(dialogContext);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: media.size.height * 0.82,
                  maxWidth: 560,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tr('add_member'),
                            style: Theme.of(dialogContext).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: MemberInvitationForm(
                          validateEmailBeforeAdd:
                              _validateInvitationEmailBeforeAdd,
                          showSubmitButton: true,
                          submitButtonText: tr('add_member'),
                          onSubmit: (emails, message) async {
                            Navigator.pop(dialogContext);
                            await _sendProjectInvitationsWithProgress(
                              emails: emails,
                              message: message,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendProjectInvitationsWithProgress({
    required List<String> emails,
    required String message,
  }) async {
    if (_project == null || emails.isEmpty) return;

    const int concurrencyLimit = 3;
    int nextIndex = 0;
    int processed = 0;
    bool isCancelled = false;
    StateSetter? setProgressState;

    final List<String> successEmails = [];
    final List<Map<String, String>> failedEmails = [];

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, stateSetter) {
          setProgressState = stateSetter;
          final progress = emails.isEmpty ? 0.0 : processed / emails.length;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(tr('add_member')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    'invitation_progress',
                    namedArgs: {
                      'processed': '$processed',
                      'total': '${emails.length}',
                    },
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text(
                  isCancelled
                      ? tr('invitation_stopping_hint')
                      : tr('invitation_cancel_hint'),
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isCancelled
                    ? null
                    : () {
                        stateSetter(() {
                          isCancelled = true;
                        });
                      },
                child: Text(tr('cancel')),
              ),
            ],
          );
        },
      ),
    );

    Future<void> worker() async {
      while (true) {
        if (isCancelled) return;
        if (nextIndex >= emails.length) return;

        final currentIndex = nextIndex;
        nextIndex += 1;
        final email = emails[currentIndex];

        final result =
            await NotificationService.sendProjectInvitationWithResult(
              context: context,
              email: email,
              projectId: _project!.id,
              message: message.isNotEmpty ? message : null,
            );

        if (result['success'] == true) {
          successEmails.add(email);
        } else {
          failedEmails.add({
            'email': email,
            'message': (result['message']?.toString() ?? tr('unknown_error')),
          });
        }

        processed += 1;
        if (mounted && setProgressState != null) {
          setProgressState!.call(() {});
        }
      }
    }

    final int workerCount = emails.length < concurrencyLimit
        ? emails.length
        : concurrencyLimit;
    await Future.wait(List.generate(workerCount, (_) => worker()));

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;

    final int cancelledCount = emails.length - processed;
    final summaryParts = <String>[
      tr(
        'invitation_summary_success',
        namedArgs: {
          'success': '${successEmails.length}',
          'total': '${emails.length}',
        },
      ),
      if (failedEmails.isNotEmpty)
        tr(
          'invitation_summary_failed',
          namedArgs: {'count': '${failedEmails.length}'},
        ),
      if (cancelledCount > 0)
        tr(
          'invitation_summary_unprocessed',
          namedArgs: {'count': '$cancelledCount'},
        ),
    ];
    final String summaryMessage = summaryParts.join(' ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(summaryMessage),
        backgroundColor: failedEmails.isEmpty && cancelledCount == 0
            ? GlobalVariables.successGreen
            : GlobalVariables.warningAmber,
      ),
    );

    if (failedEmails.isEmpty && cancelledCount == 0) {
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('invitation_result_title')),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.45,
            maxWidth: 520,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    'invitation_result_success',
                    namedArgs: {'count': '${successEmails.length}'},
                  ),
                ),
                Text(
                  tr(
                    'invitation_result_failed',
                    namedArgs: {'count': '${failedEmails.length}'},
                  ),
                ),
                if (cancelledCount > 0)
                  Text(
                    tr(
                      'invitation_result_unprocessed',
                      namedArgs: {'count': '$cancelledCount'},
                    ),
                  ),
                if (failedEmails.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    tr('invitation_failed_emails_title'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...failedEmails.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('- ${item['email']}: ${item['message']}'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr('cancel')),
          ),
        ],
      ),
    );
  }

  Future<String?> _validateInvitationEmailBeforeAdd(String email) async {
    final users = await _accountService.searchUsers(
      context,
      email,
      showErrorSnackBar: false,
    );
    final matchedUser = users
        .where((u) => u.email.toLowerCase() == email)
        .toList();

    if (matchedUser.isEmpty) {
      return tr('validation_email_not_found', namedArgs: {'email': email});
    }

    final user = matchedUser.first;
    final ownerId = _project?.createdBy['id']?.toString() ?? '';
    final isOwnerUser = ownerId == user.id;
    final isMember =
        _project?.members.any((member) => member.userId == user.id) ?? false;

    if (isOwnerUser || isMember) {
      return tr('validation_user_already_member', namedArgs: {'email': email});
    }

    return null;
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
            child: Text(tr('cancel')),
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
        isOwner: _isOwner,
        onPermissionsUpdated: () {
          _refreshProject();
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
    final previousProject = _project!;

    setState(() {
      _project = _project!.copyWith(
        members: _project!.members
            .where((m) => m.userId != member.userId)
            .toList(),
      );
    });

    ProjectsService.removeMemberFromProject(
      context: context,
      projectId: previousProject.id,
      userId: member.userId,
      onSuccess: () {
        _refreshProject();
        _activitySectionKey.currentState?.refreshActivity();
      },
      onError: () {
        if (mounted) {
          setState(() => _project = previousProject);
        }
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
        _refreshAfterTaskChange();
        _activitySectionKey.currentState?.refreshActivity();
      }
    });
  }

  Future<void> _navigateToProjectChat() async {
    if (_project == null) return;

    try {
      await StreamChatService.ensureProjectChannelAccess(_project!.id);
    } on ProjectChatPremiumRequiredException catch (e) {
      if (!mounted) return;
      showSnackBar(context, e.message);
      return;
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'Không thể truy cập phòng chat dự án');
      return;
    }

    if (!mounted) return;

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
        _refreshProject();
        _activitySectionKey.currentState?.refreshActivity();
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
    final previousProject = _project!;

    setState(() {
      _project = _project!.copyWith(status: newStatus);
    });

    ProjectsService.updateProject(
      context: context,
      projectId: previousProject.id,
      status: newStatus,
      onSuccess: () {
        _refreshProject();
        _activitySectionKey.currentState?.refreshActivity();
      },
      onError: () {
        if (mounted) {
          setState(() => _project = previousProject);
        }
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
          _refreshAfterTaskChange();
          _activitySectionKey.currentState?.refreshActivity();
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Manager':
        return GlobalVariables.secondaryCoral;
      case 'Member':
        return GlobalVariables.blueAvatar;
      case 'Viewer':
        return Color(0xFF9CA3AF);
      default:
        return GlobalVariables.textSecondary;
    }
  }

  String _getFirstNameToken(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return tr('user');
    return trimmed.split(RegExp(r'\s+')).first;
  }
}
