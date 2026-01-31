import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/features/tasks/services/dependency_service.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/models/task.dart';
import 'package:intl/intl.dart';

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
  String _dependencyType = 'predecessor'; // or 'successor'
  
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
        final filtered = tasks.where((t) => 
          t.id != widget.task.id &&
          !_isAncestorOrDescendant(t, widget.task)
        ).toList();
        
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('add_dependency'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Dependency Type Selector
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(tr('predecessor')),
                    subtitle: Text(
                      tr('predecessor_description'),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    value: 'predecessor',
                    groupValue: _dependencyType,
                    onChanged: (val) => setState(() => _dependencyType = val!),
                    activeColor: GlobalVariables.primaryBlue,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(tr('successor')),
                    subtitle: Text(
                      tr('successor_description'),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    value: 'successor',
                    groupValue: _dependencyType,
                    onChanged: (val) => setState(() => _dependencyType = val!),
                    activeColor: GlobalVariables.primaryBlue,
                  ),
                ),
              ],
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _availableTasks.map((task) => 
                  DropdownMenuItem<Task>(
                    value: task,
                    child: Text(
                      task.indentedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ).toList(),
                onChanged: (task) => setState(() => _selectedTask = task),
              ),
            const SizedBox(height: 24),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('cancel')),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedTask != null ? _createDependency : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalVariables.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(tr('add')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _createDependency() {
    if (_selectedTask == null) return;
    
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(tr('dependency_created')),
              content: Text(tr('task_auto_scheduled', namedArgs: {
                'gap': '${violation.gap}',
              })),
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
