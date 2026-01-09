import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
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

  DateTime? _dueDate;
  String _selectedPriority = 'medium';
  int _selectedWeight = 3;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description ?? '';
    _selectedPriority = widget.task.priority;
    _selectedWeight = widget.task.weight;
    _dueDate = widget.task.dueDate;
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

              // Due Date
              Text(
                tr('due_date_optional'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TaskFormWidgets.buildModernDateField(
                label: tr('due_date'),
                date: _dueDate,
                onTap: () => _selectDueDate(),
                context: context,
              ),
              const SizedBox(height: 35),

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


  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
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
      dueDate: _dueDate,
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
