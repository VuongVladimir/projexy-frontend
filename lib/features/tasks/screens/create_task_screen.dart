import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/common/widgets/custom_button.dart';
import 'package:frontend/common/widgets/custom_textfield.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/features/tasks/widgets/task_form_widgets.dart';

class CreateTaskScreen extends StatefulWidget {
  static const String routeName = '/create-task';
  final String projectId;
  final String? parentTaskId;
  final Project? project;

  const CreateTaskScreen({
    super.key,
    required this.projectId,
    this.parentTaskId,
    this.project,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPriority = 'medium';
  int _selectedWeight = 3;
  bool _isLoading = false;

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
      appBar: CustomAppBar(
        title: widget.parentTaskId != null ? tr('new_subtask') : tr('new_task'),
      ),
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

              // Start & End Date
              Text(
                tr('schedule_dates'),
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

              CustomButton(
                text: tr('create_task'),
                onTap: () => _createTask(),
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


  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validation: nếu có startDate thì phải có endDate và ngược lại
    if ((_startDate != null && _endDate == null) || 
        (_startDate == null && _endDate != null)) {
      showSnackBar(context, tr('both_dates_required'));
      return;
    }
    
    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      showSnackBar(context, tr('start_must_be_before_end'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await TasksService.createTask(
      context: context,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      projectId: widget.projectId,
      parentTaskId: widget.parentTaskId,
      priority: _selectedPriority,
      weight: _selectedWeight,
      startDate: _startDate,
      endDate: _endDate,
      schedulingMode: 'AUTO',
      onSuccess: (task) {
        Navigator.of(context).pop(true); // Return true để báo có tạo mới
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
