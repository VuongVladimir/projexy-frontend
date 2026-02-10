import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/common/widgets/custom_button.dart';
import 'package:frontend/common/widgets/custom_textfield.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/features/tasks/widgets/task_form_widgets.dart';

class EditTaskScreen extends StatefulWidget {
  static const String routeName = '/edit-task';
  final Task task;
  final Project? project;

  const EditTaskScreen({super.key, required this.task, this.project});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPriority = 'medium';
  int _selectedWeight = 3;
  bool _isLoading = false;
  bool _isSchedulable = true;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _checkTaskType();
  }

  void _initializeForm() {
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description ?? '';
    _selectedPriority = widget.task.priority;
    _selectedWeight = widget.task.weight;
    _startDate = widget.task.startDate;
    _endDate = widget.task.endDate;
  }

  void _checkTaskType() {
    // Check nếu task có children
    final hasChildren = widget.task.subTaskCount > 0;
    setState(() {
      _isSchedulable = !hasChildren;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      appBar: CustomAppBar(title: tr('edit_task')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Name
              Text(
                tr('task_name'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _titleController,
                hintText: tr('enter_task_name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('validation_enter_task_name');
                  }
                  if (value.trim().length < 3) {
                    return tr('validation_task_name_min');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                tr('description'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _descriptionController,
                hintText: tr('enter_task_description'),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Choose Priority
              Text(
                tr('choose_priority'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TaskFormWidgets.buildModernPrioritySelector(
                selectedPriority: _selectedPriority,
                onPriorityChanged: (priority) {
                  setState(() {
                    _selectedPriority = priority;
                  });
                },
                context: context,
              ),
              const SizedBox(height: 24),

              // Weight
              Text(
                tr('task_weight'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TaskFormWidgets.buildWeightSelector(
                selectedWeight: _selectedWeight,
                onWeightChanged: (weight) {
                  setState(() {
                    _selectedWeight = weight;
                  });
                },
                context: context,
              ),
              const SizedBox(height: 24),

              // Schedule Dates - Chỉ hiện nếu là schedulable task
              if (_isSchedulable) ...[
                Text(
                  tr('schedule_dates_optional'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : GlobalVariables.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TaskFormWidgets.buildDateRangeFields(
                  startDate: _startDate,
                  endDate: _endDate,
                  onStartDateChanged: (date) => setState(() => _startDate = date),
                  onEndDateChanged: (date) => setState(() => _endDate = date),
                  context: context,
                ),
                const SizedBox(height: 35),
              ] else ...[
                // Summary task: hiển thị dates read-only
                // Text(
                //   tr('schedule_dates'),
                //   style: theme.textTheme.titleMedium?.copyWith(
                //     fontWeight: FontWeight.w600,
                //     color: isDarkMode
                //         ? GlobalVariables.darkTextPrimary
                //         : GlobalVariables.textPrimary,
                //   ),
                // ),
                // const SizedBox(height: 12),
                // _buildReadOnlyDates(isDarkMode, theme),
                const SizedBox(height: 24),
              ],

              CustomButton(
                text: tr('update_task'),
                onTap: () => _updateTask(),
                isLoading: _isLoading,
                width: double.infinity,
                height: 56,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildReadOnlyDates(bool isDarkMode, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? GlobalVariables.darkSurfaceCard.withValues(alpha: 0.5)
            : GlobalVariables.surfaceCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: GlobalVariables.warningAmber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('summary_task_dates_readonly'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: GlobalVariables.primaryBlue),
              const SizedBox(width: 8),
              Text(
                '${tr('start')}: ${_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : tr('not_set')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event, size: 18, color: GlobalVariables.primaryBlue),
              const SizedBox(width: 8),
              Text(
                '${tr('end')}: ${_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : tr('not_set')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validation cho schedulable tasks
    if (_isSchedulable) {
      if ((_startDate != null && _endDate == null) || 
          (_startDate == null && _endDate != null)) {
        showSnackBar(context, tr('both_dates_required'));
        return;
      }
      
      if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
        showSnackBar(context, tr('start_must_be_before_end'));
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    await TasksService.updateTask(
      context: context,
      taskId: widget.task.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _selectedPriority,
      weight: _selectedWeight,
      startDate: _isSchedulable ? _startDate : null,
      endDate: _isSchedulable ? _endDate : null,
      onSuccess: () {
        Navigator.of(context).pop(true); // Return true để báo có cập nhật
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
