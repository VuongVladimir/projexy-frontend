import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/common/widgets/project_card.dart';
import 'package:frontend/common/widgets/task_card.dart';
import 'package:frontend/features/projects/screens/projects_screen.dart';
import 'package:frontend/features/projects/services/projects_service.dart';
import 'package:frontend/features/tasks/screens/task_detail_screen.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/actual-home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Project> _projects = [];
  List<Task> _recentTasks = [];
  bool _isLoadingProjects = true;
  bool _isLoadingTasks = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadProjects(), _loadRecentTasks()]);
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoadingProjects = true);

    await ProjectsService.getProjects(
      context: context,
      page: 1,
      limit: 5,
      sortBy: 'createdAt',
      sortOrder: 'desc',
      onSuccess: (data) {
        final projectsList = data['projects'] as List? ?? [];
        final newProjects = projectsList
            .where((json) => json != null)
            .map((json) => Project.fromMap(json as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _projects = newProjects;
            _isLoadingProjects = false;
          });
        }
      },
    );

    if (mounted) {
      setState(() => _isLoadingProjects = false);
    }
  }

  Future<void> _loadRecentTasks() async {
    setState(() => _isLoadingTasks = true);

    await TasksService.getMyTasks(
      context: context,
      onSuccess: (tasks) {
        // Only show root tasks (no parent), sort by created date, limit to 5
        final rootTasks = tasks
            .where((task) => task.parentTaskId == null)
            .toList();
        rootTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final limitedTasks = rootTasks.take(5).toList();

        if (mounted) {
          setState(() {
            _recentTasks = limitedTasks;
            _isLoadingTasks = false;
          });
        }
      },
    );

    if (mounted) {
      setState(() => _isLoadingTasks = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return tr('good_morning');
    } else if (hour < 18) {
      return tr('good_afternoon');
    } else {
      return tr('good_evening');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUser = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      appBar: CustomAppBar(
        leading: _buildAvatarWithGreeting(currentUser, isDarkMode),
        showNotificationIcon: true,
        centerTitle: false,
        leadingWidth: MediaQuery.of(context).size.width * 0.62,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Your Projects Section
              _buildProjectsSection(isDarkMode),

              // Recent Tasks Section
              _buildRecentTasksHeader(isDarkMode),

              // Recent Tasks List
              _buildRecentTasksList(isDarkMode),

              // Bottom Spacing
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWithGreeting(dynamic currentUser, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor:
                currentUser.avatarColor?.toString().toColor() ??
                GlobalVariables.primaryBlue,
            backgroundImage:
                currentUser.avatar != null && currentUser.avatar!.isNotEmpty
                ? NetworkImage(currentUser.avatar!)
                : null,
            child: currentUser.avatar == null || currentUser.avatar!.isEmpty
                ? Text(
                    currentUser.name.isNotEmpty
                        ? currentUser.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Greeting
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 13,
                    color: (isDarkMode
                        ? Colors.white
                        : GlobalVariables.textPrimary),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentUser.name.isNotEmpty ? currentUser.name : 'User',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.white
                        : GlobalVariables.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('your_projects'),
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, ProjectsScreen.routeName);
                },
                child: Text(
                  tr('see_all'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: GlobalVariables.secondaryCoral,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Projects Horizontal List
        SizedBox(
          height: 225,
          child: _isLoadingProjects
              ? const Center(child: CircularProgressIndicator())
              : _projects.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      tr('no_projects'),
                      style: TextStyle(
                        color: isDarkMode
                            ? GlobalVariables.darkTextSecondary
                            : GlobalVariables.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 333,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: ProjectCard(
                          project: _projects[index],
                          index: index,
                          onTap: () =>
                              _navigateToProjectDetails(_projects[index]),
                          showMenu: false,
                          isHomeScreen: true,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecentTasksHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        tr('recent_tasks'),
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
          color: isDarkMode
              ? GlobalVariables.darkTextPrimary
              : GlobalVariables.textPrimary,
        ),
      ),
    );
  }

  Widget _buildRecentTasksList(bool isDarkMode) {
    if (_isLoadingTasks) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recentTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: isDarkMode
                    ? GlobalVariables.darkTextTertiary
                    : GlobalVariables.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                tr('no_tasks_assigned'),
                style: TextStyle(
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _recentTasks.map((task) {
          return TaskCard(
            task: task,
            onTap: () => _navigateToTaskDetails(task),
            showMenu: false,
            showSubtaskCount: true,
            isHomeScreen: true,
          );
        }).toList(),
      ),
    );
  }

  void _navigateToProjectDetails(Project project) {
    Navigator.pushNamed(
      context,
      '/project-detail',
      arguments: {'projectId': project.id},
    ).then((_) {
      _loadProjects();
    });
  }

  void _navigateToTaskDetails(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: task.id),
      ),
    ).then((_) {
      _loadRecentTasks();
    });
  }
}
