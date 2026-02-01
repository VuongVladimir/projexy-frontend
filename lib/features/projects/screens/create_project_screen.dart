import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/common/widgets/custom_button.dart';
import 'package:frontend/common/widgets/custom_textfield.dart';
import 'package:frontend/features/projects/services/projects_service.dart';
import 'package:frontend/features/notifications/services/invitation_service.dart';
import 'package:frontend/features/projects/widgets/member_invitation_form.dart';
import 'package:frontend/features/projects/widgets/project_form_widgets.dart';
import 'package:easy_localization/easy_localization.dart';

class CreateProjectScreen extends StatefulWidget {
  static const String routeName = '/create-project';

  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPriority = 'Medium';
  List<String> _tags = [];
  List<String> _invitedEmails = [];
  String _invitationMessage = '';
  bool _isLoading = false;

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
      appBar: CustomAppBar(title: tr('create_new_project')),
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
                selectedPriority: _selectedPriority,
                onPriorityChanged: (priority) {
                  setState(() {
                    _selectedPriority = priority;
                  });
                },
                context: context,
              ),
              const SizedBox(height: 24),

              // Due Date
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
                onTagAdded: _addTag,
                context: context,
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                ProjectFormWidgets.buildTagsDisplay(
                  tags: _tags,
                  onTagRemoved: _removeTag,
                ),
              ],
              const SizedBox(height: 24),

              // Member Invitation
              Text(
                tr('invite_members'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              MemberInvitationForm(
                onSubmit: (emails, message) {
                  setState(() {
                    _invitedEmails = emails;
                  });
                },
                onEmailsChanged: (emails, message) {
                  setState(() {
                    _invitedEmails = emails;
                    _invitationMessage = message;
                  });
                },
              ),
              const SizedBox(height: 48),

              CustomButton(
                text: tr('create_project'),
                onTap: () => _createProject(),
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


  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
        // Reset end date if it's before start date
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final firstDate = _startDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? firstDate.add(const Duration(days: 30)),
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('validation_select_start_date'))),
      );
      return;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('validation_select_end_date'))));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Đầu tiên tạo project
    await ProjectsService.createProject(
      context: context,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      priority: _selectedPriority,
      tags: _tags,
      members: [],
      onSuccess: (projectId) async {
        // Sau khi tạo project thành công, lấy project ID và gửi lời mời
        if (_invitedEmails.isNotEmpty) {
          await _sendInvitations(projectId);
        } else {
          Navigator.of(context).pop();
        }
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendInvitations(String projectId) async {
    int successCount = 0;

    for (String email in _invitedEmails) {
      await InvitationService.sendInvitation(
        context: context,
        email: email,
        projectId: projectId,
        message: _invitationMessage.isNotEmpty ? _invitationMessage : null,
        onSuccess: () {
          successCount++;
        },
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'success_invitations_sent',
              namedArgs: {
                'count': '$successCount',
                'total': '${_invitedEmails.length}',
              },
            ),
          ),
          backgroundColor: GlobalVariables.successGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}
