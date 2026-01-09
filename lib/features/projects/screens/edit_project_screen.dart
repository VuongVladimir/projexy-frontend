import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/common/widgets/custom_button.dart';
import 'package:frontend/common/widgets/custom_textfield.dart';
import 'package:frontend/features/projects/services/projects_service.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/features/projects/widgets/project_form_widgets.dart';

class EditProjectScreen extends StatefulWidget {
  static const String routeName = '/edit-project';
  final Project project;

  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  String _priority = 'Medium';
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _tags = [];
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = widget.project.title;
    _descriptionController.text = widget.project.description ?? '';
    _priority = widget.project.priority;
    _startDate = widget.project.startDate;
    _endDate = widget.project.endDate;
    _tags = List.from(widget.project.tags);
    _tagsController.text = _tags.join(', ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
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
        title: tr('edit_project'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Name
              Text(
                tr('project_name'),
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
                hintText: tr('enter_project_name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('validation_enter_project_name');
                  }
                  if (value.trim().length < 3) {
                    return tr('validation_project_name_min');
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
                hintText: tr('enter_project_description'),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('validation_enter_project_desc');
                  }
                  if (value.trim().length < 10) {
                    return tr('validation_project_desc_min');
                  }
                  return null;
                },
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
              ProjectFormWidgets.buildModernPrioritySelector(
                selectedPriority: _priority,
                onPriorityChanged: (priority) {
                  setState(() {
                    _priority = priority;
                  });
                },
                context: context,
              ),
              const SizedBox(height: 24),

              // Due Date
              Text(
                tr('due_date'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ProjectFormWidgets.buildModernDateField(
                      label: tr('start_date'),
                      date: _startDate,
                      onTap: () => _selectStartDate(),
                      context: context,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ProjectFormWidgets.buildModernDateField(
                      label: tr('end_date'),
                      date: _endDate,
                      onTap: () => _selectEndDate(),
                      context: context,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tags
              Text(
                tr('tags'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ProjectFormWidgets.buildTagsInput(
                controller: _tagsController,
                onTagAdded: (tag) {
                  final trimmedTag = tag.trim();
                  if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
                    setState(() {
                      _tags.add(trimmedTag);
                      _tagsController.clear();
                    });
                  }
                },
                context: context,
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                ProjectFormWidgets.buildTagsDisplay(
                  tags: _tags,
                  onTagRemoved: _removeTag,
                ),
              ],
              const SizedBox(height: 48),
              CustomButton(
                text: tr('update_project'),
                onTap: () => _updateProject(),
                isLoading: _isUpdating,
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


  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _tagsController.text = _tags.join(', ');
    });
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _endDate ?? DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
        // Nếu ngày bắt đầu sau ngày kết thúc, reset ngày kết thúc
        if (_endDate != null && pickedDate.isAfter(_endDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _endDate ??
          _startDate?.add(const Duration(days: 7)) ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }

  void _updateProject() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('validation_select_start_end_dates')),
          backgroundColor: GlobalVariables.errorRed,
        ),
      );
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('validation_start_before_end')),
          backgroundColor: GlobalVariables.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    ProjectsService.updateProject(
      context: context,
      projectId: widget.project.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      priority: _priority,
      tags: _tags,
      onSuccess: () {
        Navigator.pop(context, true); // Return true để báo có cập nhật
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    });
  }
}
