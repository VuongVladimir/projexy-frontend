import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/features/tasks/services/dependency_service.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/models/task.dart';

class AddDependencyDialog extends StatefulWidget {
  final Task task;
  final Project project;
  final VoidCallback onAdded;

  const AddDependencyDialog({
    super.key,
    required this.task,
    required this.project,
    required this.onAdded,
  });

  @override
  State<AddDependencyDialog> createState() => _AddDependencyDialogState();
}

class _AddDependencyDialogState extends State<AddDependencyDialog> {
  List<Task> _availableTasks = [];
  Task? _selectedTask;
  bool _isLoading = true;
  bool _isLoadingPreview = false;
  bool _isCreating = false;
  String _dependencyType = 'predecessor'; // or 'successor'
  List<Map<String, dynamic>> _impactedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableTasks();
  }

  Future<void> _loadAvailableTasks() async {
    setState(() => _isLoading = true);

    await TasksService.getProjectTasks(
      context: context,
      projectId: widget.project.id,
      parentTaskId: null,
      includeSubtasks: true,
      onSuccess: (tasks) {
        // Filter: loại bỏ task hiện tại và ancestors/descendants
        final filtered = tasks
            .where(
              (t) =>
                  t.id != widget.task.id &&
                  !_isAncestorOrDescendant(t, widget.task),
            )
            .toList();

        if (mounted) {
          setState(() {
            _availableTasks = filtered;
            _isLoading = false;
          });
        }
      },
    );
  }

  bool _isAncestorOrDescendant(Task a, Task b) {
    // Check if a is ancestor of b or vice versa
    if (a.path.contains(b.id) || b.path.contains(a.id)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E2530) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: GlobalVariables.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    color: GlobalVariables.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('add_dependency'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? GlobalVariables.darkTextPrimary
                          : GlobalVariables.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dependency Type Selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF3F6FC),
                border: Border.all(
                  color: GlobalVariables.primaryBlue.withValues(alpha: 0.22),
                ),
              ),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    return states.contains(WidgetState.selected)
                        ? Colors.white
                        : (isDarkMode
                              ? GlobalVariables.darkTextPrimary
                              : GlobalVariables.textPrimary);
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    return states.contains(WidgetState.selected)
                        ? GlobalVariables.primaryBlue
                        : Colors.transparent;
                  }),
                  side: const WidgetStatePropertyAll(BorderSide.none),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  textStyle: WidgetStatePropertyAll(
                    theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
                segments: [
                  ButtonSegment<String>(
                    value: 'predecessor',
                    label: Text(
                      tr('predecessor'),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  ButtonSegment<String>(
                    value: 'successor',
                    label: Text(
                      tr('successor'),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
                selected: {_dependencyType},
                onSelectionChanged: (selection) {
                  final selectedType = selection.first;
                  if (selectedType == _dependencyType) return;

                  setState(() {
                    _dependencyType = selectedType;
                    _impactedTasks = [];
                  });
                  if (_selectedTask != null) _loadPreview();
                },
              ),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF4F7FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        _dependencyType == 'predecessor'
                            ? tr('predecessor_description')
                            : tr('successor_description'),
                        key: ValueKey(_dependencyType),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          height: 1.35,
                          color: isDarkMode
                              ? GlobalVariables.darkTextSecondary
                              : GlobalVariables.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Task Dropdown
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<Task>(
                value: _selectedTask,
                decoration: InputDecoration(
                  labelText: _dependencyType == 'predecessor'
                      ? tr('select_predecessor')
                      : tr('select_successor'),
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF9FAFC),
                  prefixIcon: const Icon(Icons.task_alt_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: GlobalVariables.primaryBlue.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: GlobalVariables.primaryBlue.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: GlobalVariables.primaryBlue,
                      width: 1.8,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _availableTasks
                    .map(
                      (task) => DropdownMenuItem<Task>(
                        value: task,
                        child: Text(
                          task.indentedTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (task) {
                  setState(() {
                    _selectedTask = task;
                    _impactedTasks = [];
                  });
                  if (task != null) _loadPreview();
                },
              ),

            // Impact Preview
            if (_isLoadingPreview) ...[
              const SizedBox(height: 16),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ] else if (_impactedTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GlobalVariables.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GlobalVariables.warningAmber),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: GlobalVariables.warningAmber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr('schedule_impact_preview'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: GlobalVariables.warningAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._impactedTasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: GlobalVariables.warningAmber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${task['taskTitle']} ${tr('will_be_shifted')} ${task['shiftDays']} ${tr('days')}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDarkMode
                                      ? GlobalVariables.darkTextPrimary
                                      : GlobalVariables.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isCreating ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GlobalVariables.primaryBlue,
                    side: BorderSide(
                      color: GlobalVariables.primaryBlue.withValues(
                        alpha: 0.35,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  child: Text(tr('cancel')),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: (_selectedTask != null && !_isCreating)
                      ? _createDependency
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalVariables.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(tr('add')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _loadPreview() {
    if (_selectedTask == null) return;

    final predecessorId = _dependencyType == 'predecessor'
        ? _selectedTask!.id
        : widget.task.id;
    final successorId = _dependencyType == 'predecessor'
        ? widget.task.id
        : _selectedTask!.id;

    setState(() => _isLoadingPreview = true);

    DependencyService.previewDependencyImpact(
      context: context,
      predecessorId: predecessorId,
      successorId: successorId,
      projectId: widget.project.id,
      onSuccess: (impacted) {
        if (mounted) {
          setState(() {
            _impactedTasks = impacted;
            _isLoadingPreview = false;
          });
        }
      },
    );
  }

  void _createDependency() {
    if (_selectedTask == null) return;

    setState(() => _isCreating = true);

    final predecessorId = _dependencyType == 'predecessor'
        ? _selectedTask!.id
        : widget.task.id;
    final successorId = _dependencyType == 'predecessor'
        ? widget.task.id
        : _selectedTask!.id;

    DependencyService.createDependency(
      context: context,
      predecessorId: predecessorId,
      successorId: successorId,
      projectId: widget.project.id,
      onSuccess: (dependency, violation) {
        Navigator.pop(context);

        if (violation != null) {
          // Hiển thị thông báo về auto-schedule
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(tr('dependency_created')),
              content: Text(
                tr(
                  'task_auto_scheduled',
                  namedArgs: {'gap': '${violation.gap}'},
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('ok')),
                ),
              ],
            ),
          );
        } else {
          showSnackBar(context, tr('dependency_created_success'));
        }

        widget.onAdded();
      },
    );
  }
}
