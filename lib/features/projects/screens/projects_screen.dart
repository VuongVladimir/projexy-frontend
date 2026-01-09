import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/common/widgets/project_card.dart';
import 'package:frontend/features/projects/screens/create_project_screen.dart';
import 'package:frontend/features/projects/screens/edit_project_screen.dart';
import 'package:frontend/features/projects/services/projects_service.dart';
import 'package:frontend/models/project.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_symbols_icons/symbols.dart';

class ProjectsScreen extends StatefulWidget {
  static const String routeName = '/projects';

  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Project> _projects = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedSortBy = 'createdAt';
  String? _selectedSortOrder = 'desc';
  String _searchQuery = '';

  // Filter options - will be populated in build method for localization
  List<Map<String, String>> _statusOptions = [];

  List<Map<String, String>> _priorityOptions = [];

  List<Map<String, String>> _sortOptions = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
    _loadProjects();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadMoreProjects();
      }
    }
  }

  Future<void> _loadProjects({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _projects.clear();
        _currentPage = 1;
        _hasMore = true;
      }
    });

    await ProjectsService.getProjects(
      context: context,
      page: _currentPage,
      limit: 10,
      status: _selectedStatus?.isNotEmpty == true ? _selectedStatus : null,
      priority: _selectedPriority?.isNotEmpty == true
          ? _selectedPriority
          : null,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      sortBy: _selectedSortBy,
      sortOrder: _selectedSortOrder,
      onSuccess: (data) {
        final projectsList = data['projects'] as List? ?? [];
        final newProjects = projectsList
            .where((json) => json != null)
            .map((json) => Project.fromMap(json as Map<String, dynamic>))
            .toList();

        setState(() {
          if (refresh) {
            _projects = newProjects;
          } else {
            _projects.addAll(newProjects);
          }
          _hasMore = newProjects.length == 10;
          _currentPage++;
          _isLoading = false;
        });
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProjects() async {
    await _loadProjects();
  }

  void _onSearchChanged() {
    _searchQuery = _searchController.text.trim();
    _debounceSearch();
  }

  Timer? _debounceTimer;
  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _loadProjects(refresh: true);
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSortBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // final theme = Theme.of(context);

    // Initialize localized options
    _statusOptions = [
      {'value': '', 'label': tr('all_status')},
      {'value': 'Planning', 'label': tr('planning')},
      {'value': 'In-progress', 'label': tr('in_progress')},
      {'value': 'Completed', 'label': tr('completed')},
    ];

    _priorityOptions = [
      {'value': '', 'label': tr('all_priority')},
      {'value': 'Low', 'label': tr('low')},
      {'value': 'Medium', 'label': tr('medium')},
      {'value': 'High', 'label': tr('high')},
    ];

    _sortOptions = [
      {'value': 'createdAt', 'label': tr('created_date')},
      {'value': 'title', 'label': tr('project_name')},
      {'value': 'priority', 'label': tr('priority')},
      {'value': 'endDate', 'label': tr('end_date')},
      {'value': 'progress', 'label': tr('progress')},
    ];

    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: CustomAppBar(title: tr('projects')),
        body: RefreshIndicator(
          onRefresh: () => _loadProjects(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Search và Filter Bar
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.0),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.grey.shade300.withValues(alpha: 0.6),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (_) => _onSearchChanged(),
                          onSubmitted: (value) {
                            _debounceTimer?.cancel();
                            _loadProjects(refresh: true);
                            _searchFocusNode.unfocus();
                          },
                          decoration: InputDecoration(
                            hintText: tr('search_projects'),
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? GlobalVariables.darkTextSecondary
                                  : GlobalVariables.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: _searchFocusNode.hasFocus
                                  ? GlobalVariables.primaryBlue
                                  : GlobalVariables.black.withValues(
                                      alpha: 0.75,
                                    ),
                              size: 22,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: GlobalVariables.secondaryCoral,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDarkMode
                                ? GlobalVariables.darkSurfaceCard
                                : Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28.0),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28.0),
                              borderSide: BorderSide(
                                color: GlobalVariables.primaryBlue,
                                width: 2.0,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Projects List
              if (_isLoading && _projects.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_projects.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.84, // Tỷ lệ chiều rộng/chiều cao
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index < _projects.length) {
                        final row =
                            index ~/ 2; // Lấy phần nguyên của index chia 2
                        final column =
                            index % 2; // Lấy phần dư của index chia 2
                        // Nếu tổng của row và column là số chẵn thì dùng màu primaryBlue
                        final adjustedIndex = row + column;
                        return ProjectCard(
                          project: _projects[index],
                          index: adjustedIndex,
                          onTap: () =>
                              _navigateToProjectDetails(_projects[index]),
                          onEdit: () =>
                              _navigateToEditProject(_projects[index]),
                          onDelete: () => _deleteProject(_projects[index]),
                          showMenu: false,
                        );
                      } else if (_hasMore) {
                        return Container(
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
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return null;
                    }, childCount: _projects.length + (_hasMore ? 1 : 0)),
                  ),
                ),

              // Bottom Spacing
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 32),
            FloatingActionButton(
              heroTag: 'fab_left',
              onPressed: _showManageViewBottomSheet,
              backgroundColor: GlobalVariables.secondaryCoral,
              shape: const CircleBorder(),
              child: const Icon(
                Symbols.tune,
                weight: 500,
                size: 26,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            FloatingActionButton(
              heroTag: 'fab_right',
              onPressed: () => _navigateToCreateProject(),
              backgroundColor: GlobalVariables.primaryBlue,
              shape: const CircleBorder(),
              child: const Icon(
                Symbols.add,
                weight: 300,
                size: 36,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 64,
            color: isDarkMode
                ? GlobalVariables.darkTextTertiary
                : GlobalVariables.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            tr('no_projects'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('create_first_project'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateProject(),
            icon: const Icon(Icons.add_rounded),
            label: Text(tr('create_new_project')),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalVariables.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManageViewBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildManageViewBottomSheet(),
    );
  }

  Widget _buildManageViewBottomSheet() {
    final hasActiveFilters =
        (_selectedStatus?.isNotEmpty == true) ||
        (_selectedPriority?.isNotEmpty == true);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDarkMode
        ? GlobalVariables.darkTextPrimary
        : GlobalVariables.textPrimary;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        6,
        10,
        6,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                tr('manage_view'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: titleColor,
                ),
              ),
            ),
          ),

          // Nút Filter
          ListTile(
            leading: Icon(
              Symbols.filter_list,
              color: GlobalVariables.black.withValues(alpha: 0.6),
            ),
            title: Text(
              tr('filter'),
              style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
            ),
            trailing: hasActiveFilters
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: GlobalVariables.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  )
                : const Icon(Icons.chevron_right_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              Navigator.pop(context); // 1. Đóng bottom sheet hiện tại
              _showFilterBottomSheet(); // 2. Mở bottom sheet filter
            },
          ),
          Divider(
            height: 1.2,
            thickness: 1.2,
            color: GlobalVariables.borderPrimary,
            indent: 50, // Thụt lề trái
          ),

          // Nút Sort
          ListTile(
            leading: Icon(
              Symbols.swap_vert,
              color: GlobalVariables.black.withValues(alpha: 0.6),
            ),
            title: Text(
              tr('sort'),
              style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
            ),
            trailing: Icon(Icons.chevron_right_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              Navigator.pop(context); // 1. Đóng bottom sheet hiện tại
              _showSortBottomSheet(); // 2. Mở bottom sheet sort
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  tr('filter'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status Filter
              Text(
                tr('all_status'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statusOptions
                    .map(
                      (option) => _buildFilterChip(
                        label: option['label']!,
                        isSelected: _selectedStatus == option['value'],
                        onTap: () =>
                            setState(() => _selectedStatus = option['value']),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Priority Filter
              Text(
                tr('priority'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _priorityOptions
                    .map(
                      (option) => _buildFilterChip(
                        label: option['label']!,
                        isSelected: _selectedPriority == option['value'],
                        onTap: () =>
                            setState(() => _selectedPriority = option['value']),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = null;
                          _selectedPriority = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        tr('clear_filter'),
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        this.setState(() {});
                        _loadProjects(refresh: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalVariables.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(tr('apply'), style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortBottomSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDarkMode
        ? GlobalVariables.darkTextPrimary
        : GlobalVariables.textPrimary;
    final subtitleColor = isDarkMode
        ? GlobalVariables.darkTextSecondary
        : GlobalVariables.textSecondary;

    String? tempSortBy = _selectedSortBy;
    String? tempSortOrder = _selectedSortOrder;

    // Sử dụng StatefulBuilder để tạo ra một state cục bộ cho bottom sheet.
    // Các thay đổi sẽ chỉ rebuild sheet này, không ảnh hưởng đến màn hình chính
    // cho đến khi nhấn "Áp dụng".
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter sheetSetState) {
        return SingleChildScrollView(
          child: Container(
            // Thêm padding cho thanh điều hướng/gesture bar ở dưới
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Drag Handle ---
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // --- Tiêu đề chính ---
                Center(
                  child: Text(
                    tr('sort'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('sort_by'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 8),
                ..._sortOptions
                    .map(
                      (option) => RadioListTile<String>(
                        title: Text(
                          option['label']!,
                          style: TextStyle(color: titleColor),
                        ),
                        value: option['value']!,
                        groupValue: tempSortBy,
                        onChanged: (value) {
                          sheetSetState(() => tempSortBy = value);
                        },
                        activeColor: GlobalVariables.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),

                const SizedBox(height: 12),
                Divider(
                  height: 1.2,
                  thickness: 1.2,
                  color: GlobalVariables.black.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  tr('sort_order'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment<String>(
                        value: 'desc',
                        label: Text(tr('newest_first')),
                        icon: const Icon(Icons.trending_down_rounded),
                      ),
                      ButtonSegment<String>(
                        value: 'asc',
                        label: Text(tr('oldest_first')),
                        icon: const Icon(Icons.trending_up_rounded),
                      ),
                    ],
                    selected: <String>{tempSortOrder ?? 'desc'},
                    onSelectionChanged: (Set<String> newSelection) {
                      sheetSetState(() {
                        tempSortOrder = newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      // Style cho nút được chọn
                      selectedBackgroundColor: GlobalVariables.primaryBlue
                          .withValues(alpha: 0.1),
                      selectedForegroundColor: GlobalVariables.primaryBlue,
                      // Style cho nút không được chọn
                      backgroundColor: isDarkMode
                          ? GlobalVariables.darkSurfaceCard
                          : Colors.white,
                      foregroundColor: subtitleColor,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          tr('reset'),
                          style: TextStyle(fontSize: 15),
                        ),
                        onPressed: () {
                          // Reset biến tạm về giá trị ban đầu (lúc mở sheet)
                          sheetSetState(() {
                            tempSortBy = _selectedSortBy;
                            tempSortOrder = _selectedSortOrder;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalVariables.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          tr('apply'),
                          style: TextStyle(fontSize: 15),
                        ),
                        onPressed: () {
                          // Cập nhật state CHÍNH của màn hình
                          setState(() {
                            _selectedSortBy = tempSortBy;
                            _selectedSortOrder = tempSortOrder;
                          });
                          Navigator.pop(context);
                          _loadProjects(refresh: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GlobalVariables.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? GlobalVariables.primaryBlue
                : GlobalVariables.borderPrimary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _navigateToCreateProject() {
    Navigator.pushNamed(context, CreateProjectScreen.routeName).then((_) {
      _loadProjects(refresh: true);
    });
  }

  void _navigateToProjectDetails(Project project) {
    Navigator.pushNamed(
      context,
      '/project-detail',
      arguments: {'projectId': project.id},
    ).then((_) {
      _loadProjects(refresh: true); // Reload projects khi quay lại
    });
  }

  void _navigateToEditProject(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProjectScreen(project: project),
      ),
    ).then((result) {
      if (result == true) {
        _loadProjects(refresh: true); // Reload projects khi có cập nhật
      }
    });
  }

  void _deleteProject(Project project) {
    ProjectsService.deleteProject(
      context: context,
      projectId: project.id,
      onSuccess: () {
        _loadProjects(refresh: true);
      },
    );
  }
}
