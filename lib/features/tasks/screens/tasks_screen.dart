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
  List<Task> _allTasks = [];
  List<Task> _tasks = [];
  bool _isLoading = true;

  String? _selectedProjectId;
  String? _selectedParentTaskId;
  String? _selectedPriority;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadMyTasks();
  }

  Future<void> _loadMyTasks() async {
    setState(() => _isLoading = true);

    await TasksService.getMyTasks(
      context: context,
      projectId: _selectedProjectId,
      priority: _selectedPriority,
      status: _selectedStatus,
      onSuccess: (tasks) {
        if (!mounted) return;

        setState(() {
          _allTasks = tasks.toList(growable: false);
          _tasks = _applyLocalFilters(_allTasks);
          _isLoading = false;
        });
      },
    );
  }

  List<Task> _applyLocalFilters(List<Task> source) {
    Iterable<Task> filtered = source;

    if (_selectedParentTaskId != null) {
      filtered = filtered.where(
        (task) => task.parentTaskId == _selectedParentTaskId,
      );
    }

    return filtered.toList(growable: false);
  }

  int get _activeFilterCount {
    return [
      _selectedProjectId,
      _selectedParentTaskId,
      _selectedPriority,
      _selectedStatus,
    ].where((value) => value != null).length;
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_TaskFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _TaskFilterSheet(
          selectedProjectId: _selectedProjectId,
          selectedParentTaskId: _selectedParentTaskId,
          selectedPriority: _selectedPriority,
          selectedStatus: _selectedStatus,
          projectOptions: _buildProjectOptions(),
          parentTaskOptions: _buildParentTaskOptions(),
        );
      },
    );

    if (result == null) {
      return;
    }

    final previousProjectId = _selectedProjectId;
    final previousPriority = _selectedPriority;
    final previousStatus = _selectedStatus;

    final changedServerFilters =
        previousProjectId != result.projectId ||
        previousPriority != result.priority ||
        previousStatus != result.status;

    setState(() {
      _selectedProjectId = result.projectId;
      _selectedParentTaskId = result.parentTaskId;
      _selectedPriority = result.priority;
      _selectedStatus = result.status;
    });

    if (changedServerFilters) {
      await _loadMyTasks();
      return;
    }

    setState(() {
      _tasks = _applyLocalFilters(_allTasks);
    });
  }

  List<_FilterOption> _buildProjectOptions() {
    final map = <String, String>{};
    for (final task in _allTasks) {
      if (task.projectId.isEmpty) continue;
      final title = (task.projectTitle ?? '').trim();
      map[task.projectId] = title.isEmpty ? task.projectId : title;
    }

    final options = map.entries
        .map((entry) => _FilterOption(value: entry.key, label: entry.value))
        .toList(growable: false);
    options.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return options;
  }

  List<_FilterOption> _buildParentTaskOptions() {
    final titleByTaskId = <String, String>{
      for (final task in _allTasks)
        if (task.id.isNotEmpty) task.id: task.title,
    };

    final map = <String, String>{};
    for (final task in _allTasks) {
      final parentId = task.parentTaskId;
      if (parentId == null || parentId.isEmpty) continue;

      final populatedTitle = (task.parentTaskTitle ?? '').trim();
      final fallbackTitle = (titleByTaskId[parentId] ?? parentId).trim();
      map[parentId] = populatedTitle.isNotEmpty
          ? populatedTitle
          : fallbackTitle;
    }

    final options = map.entries
        .map((entry) => _FilterOption(value: entry.key, label: entry.value))
        .toList(growable: false);
    options.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      appBar: CustomAppBar(title: tr('my_tasks')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFilterSheet,
        backgroundColor: isDarkMode
            ? GlobalVariables.darkPrimaryBlue
            : GlobalVariables.primaryBlue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.filter_list_rounded, size: 32),
            if (_activeFilterCount > 0)
              Positioned(
                right: -11,
                top: -13,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: GlobalVariables.secondaryCoral,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_activeFilterCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
                  : _allTasks.isEmpty
                  ? _buildEmptyState(context)
                  : _tasks.isEmpty
                  ? _buildFilteredEmptyState(context)
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
        return TaskListView(tasks: _tasks, onRefresh: _loadMyTasks);
      case TaskViewMode.kanban:
        return TaskKanbanView(tasks: _tasks, onRefresh: _loadMyTasks);
      case TaskViewMode.calendar:
        return TaskCalendarView(tasks: _tasks, onRefresh: _loadMyTasks);
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

  Widget _buildFilteredEmptyState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_rounded,
              size: 72,
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
            const SizedBox(height: 20),
            Text(
              tr('no_filtered_tasks'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              tr('adjust_filters_hint'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                setState(() {
                  _selectedProjectId = null;
                  _selectedParentTaskId = null;
                  _selectedPriority = null;
                  _selectedStatus = null;
                });
                await _loadMyTasks();
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(tr('clear_filters')),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption {
  final String value;
  final String label;

  const _FilterOption({required this.value, required this.label});
}

class _TaskFilterResult {
  final String? projectId;
  final String? parentTaskId;
  final String? priority;
  final String? status;

  const _TaskFilterResult({
    this.projectId,
    this.parentTaskId,
    this.priority,
    this.status,
  });
}

class _TaskFilterSheet extends StatefulWidget {
  final String? selectedProjectId;
  final String? selectedParentTaskId;
  final String? selectedPriority;
  final String? selectedStatus;
  final List<_FilterOption> projectOptions;
  final List<_FilterOption> parentTaskOptions;

  const _TaskFilterSheet({
    required this.selectedProjectId,
    required this.selectedParentTaskId,
    required this.selectedPriority,
    required this.selectedStatus,
    required this.projectOptions,
    required this.parentTaskOptions,
  });

  @override
  State<_TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<_TaskFilterSheet> {
  static const String _allValue = '__all__';

  late String? _projectId;
  late String? _parentTaskId;
  late String? _priority;
  late String? _status;

  @override
  void initState() {
    super.initState();
    _projectId = widget.selectedProjectId;
    _parentTaskId = widget.selectedParentTaskId;
    _priority = widget.selectedPriority;
    _status = widget.selectedStatus;
  }

  Future<void> _selectProject() async {
    final value = await _showSearchableSelector(
      title: tr('project'),
      allLabel: tr('all_projects'),
      searchHint: tr('search_projects'),
      emptyResultText: tr('no_projects_found'),
      options: widget.projectOptions,
      currentValue: _projectId,
    );

    if (!mounted || value == null) return;

    setState(() {
      _projectId = value == _allValue ? null : value;
    });
  }

  Future<void> _selectParentTask() async {
    final value = await _showSearchableSelector(
      title: tr('parent_task'),
      allLabel: tr('all_parent_tasks'),
      searchHint: tr('search_parent_tasks'),
      emptyResultText: tr('no_parent_tasks_found'),
      options: widget.parentTaskOptions,
      currentValue: _parentTaskId,
    );

    if (!mounted || value == null) return;

    setState(() {
      _parentTaskId = value == _allValue ? null : value;
    });
  }

  Future<String?> _showSearchableSelector({
    required String title,
    required String allLabel,
    required String searchHint,
    required String emptyResultText,
    required List<_FilterOption> options,
    required String? currentValue,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final controller = TextEditingController();
        String query = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final normalizedQuery = query.trim().toLowerCase();
            final filteredOptions = options
                .where(
                  (option) =>
                      normalizedQuery.isEmpty ||
                      option.label.toLowerCase().contains(normalizedQuery),
                )
                .toList(growable: false);

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: RadioGroup<String>(
                  groupValue: currentValue ?? _allValue,
                  onChanged: (value) {
                    if (value != null) Navigator.pop(context, value);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        onChanged: (value) {
                          setModalState(() {
                            query = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: searchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Radio<String>(value: _allValue),
                        title: Text(allLabel),
                        onTap: () => Navigator.pop(context, _allValue),
                      ),
                      Divider(
                        height: 1.2,
                        color:
                            (Theme.of(context).brightness == Brightness.dark
                                    ? GlobalVariables.darkBorderPrimary
                                    : GlobalVariables.borderPrimary)
                                .withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filteredOptions.isEmpty
                            ? Center(
                                child: Text(
                                  emptyResultText,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredOptions.length,
                                itemBuilder: (context, index) {
                                  final option = filteredOptions[index];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Radio<String>(value: option.value),
                                    title: Text(
                                      option.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    onTap: () =>
                                        Navigator.pop(context, option.value),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _resolveLabel(
    List<_FilterOption> options,
    String? value,
    String allLabel,
  ) {
    if (value == null) return allLabel;
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final priorityOptions = [
      _FilterOption(value: 'low', label: tr('low')),
      _FilterOption(value: 'medium', label: tr('medium')),
      _FilterOption(value: 'high', label: tr('high')),
    ];
    final statusOptions = [
      _FilterOption(value: 'todo', label: tr('todo')),
      _FilterOption(value: 'in-progress', label: tr('in_progress')),
      _FilterOption(value: 'completed', label: tr('completed')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? GlobalVariables.darkBackgroundSecondary
            : GlobalVariables.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? GlobalVariables.darkBorderPrimary
                          : GlobalVariables.borderPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('task_filters'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 18),
                _FilterSelectionTile(
                  label: tr('project'),
                  valueLabel: _resolveLabel(
                    widget.projectOptions,
                    _projectId,
                    tr('all_projects'),
                  ),
                  icon: Icons.folder_open_rounded,
                  onTap: _selectProject,
                ),
                const SizedBox(height: 10),
                _FilterSelectionTile(
                  label: tr('parent_task'),
                  valueLabel: _resolveLabel(
                    widget.parentTaskOptions,
                    _parentTaskId,
                    tr('all_parent_tasks'),
                  ),
                  icon: Icons.account_tree_rounded,
                  onTap: _selectParentTask,
                ),
                const SizedBox(height: 14),
                Text(
                  tr('priority'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(tr('all_priority')),
                      selected: _priority == null,
                      onSelected: (_) => setState(() => _priority = null),
                    ),
                    ...priorityOptions.map(
                      (option) => ChoiceChip(
                        label: Text(option.label),
                        selected: _priority == option.value,
                        onSelected: (_) =>
                            setState(() => _priority = option.value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  tr('status'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(tr('all_status')),
                      selected: _status == null,
                      onSelected: (_) => setState(() => _status = null),
                    ),
                    ...statusOptions.map(
                      (option) => ChoiceChip(
                        label: Text(option.label),
                        selected: _status == option.value,
                        onSelected: (_) =>
                            setState(() => _status = option.value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 21),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _projectId = null;
                            _parentTaskId = null;
                            _priority = null;
                            _status = null;
                          });
                        },
                        child: Text(tr('clear_filters')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            _TaskFilterResult(
                              projectId: _projectId,
                              parentTaskId: _parentTaskId,
                              priority: _priority,
                              status: _status,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode
                              ? GlobalVariables.darkPrimaryBlue
                              : GlobalVariables.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(tr('apply_filters')),
                      ),
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
}

class _FilterSelectionTile extends StatelessWidget {
  final String label;
  final String valueLabel;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterSelectionTile({
    required this.label,
    required this.valueLabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            Icon(
              icon,
              size: 25,
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDarkMode
                          ? GlobalVariables.darkTextSecondary
                          : GlobalVariables.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valueLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? GlobalVariables.darkTextPrimary
                          : GlobalVariables.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
