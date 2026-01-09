import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/models/task.dart';

class AssignTaskDialog extends StatefulWidget {
  final Task task;
  final Project project;
  final VoidCallback onAssigned;

  const AssignTaskDialog({
    super.key,
    required this.task,
    required this.project,
    required this.onAssigned,
  });

  @override
  State<AssignTaskDialog> createState() => _AssignTaskDialogState();
}

class _AssignTaskDialogState extends State<AssignTaskDialog> {
  final List<String> _selectedUserIds = [];

  @override
  void initState() {
    super.initState();
    // Khởi tạo với danh sách đã assign trước đó
    _selectedUserIds.addAll(
      widget.task.assignedTo.map((user) => user['_id'].toString()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Lấy danh sách tất cả members trong project (bao gồm owner)
    final allMembers = <Map<String, dynamic>>[
      {
        // Chuẩn hóa owner sang cấu trúc có _id để đồng nhất
        '_id': widget.project.createdBy['id'],
        'name': widget.project.createdBy['name'] ?? '',
        'email': widget.project.createdBy['email'] ?? '',
        'avatar': widget.project.createdBy['avatar'] ?? '',
        'avatarColor': widget.project.createdBy['avatarColor'] ?? '#2196F3',
      },
      ...widget.project.members
          .map(
            (member) => {
              '_id': member.userId,
              'name': member.userName ?? '',
              'email': member.userEmail ?? '',
              'avatar': member.avatar ?? '',
              'avatarColor': member.avatarColor ?? '#2196F3',
            },
          )
          .toList(),
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('assign_task')),
          const SizedBox(height: 4),
          Text(
            widget.task.title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allMembers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr('no_members_in_project'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDarkMode
                        ? GlobalVariables.darkTextTertiary
                        : GlobalVariables.textTertiary,
                  ),
                ),
              )
            else
              ...allMembers.map((user) {
                final userId = (user['_id'] ?? user['id'] ?? '').toString();
                final isSelected = _selectedUserIds.contains(userId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? GlobalVariables.primaryBlue
                          : (isDarkMode
                                ? GlobalVariables.darkBorderPrimary
                                : GlobalVariables.borderPrimary),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? GlobalVariables.primaryBlue.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedUserIds.add(userId);
                        } else {
                          _selectedUserIds.remove(userId);
                        }
                      });
                    },
                    title: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: user['avatarColor']
                              .toString()
                              .toColor(),
                          backgroundImage:
                              user['avatar'] != null &&
                                  user['avatar'].isNotEmpty
                              ? NetworkImage(user['avatar'])
                              : null,
                          child:
                              user['avatar'] == null || user['avatar'].isEmpty
                              ? Text(
                                  (user['name'] ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] ?? tr('unknown'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? GlobalVariables.darkTextPrimary
                                      : GlobalVariables.textPrimary,
                                ),
                              ),
                              if (user['email'] != null &&
                                  user['email'].isNotEmpty)
                                Text(
                                  user['email'],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDarkMode
                                        ? GlobalVariables.darkTextSecondary
                                        : GlobalVariables.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    activeColor: GlobalVariables.primaryBlue,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _assignTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: GlobalVariables.primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: Text(tr('save')),
        ),
      ],
    );
  }

  void _assignTask() {
    final validIds = _selectedUserIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != 'null')
        .toSet()
        .toList();
    TasksService.assignTask(
      context: context,
      taskId: widget.task.id,
      assignedTo: validIds,
      onSuccess: () {
        Navigator.of(context).pop();
        widget.onAssigned();
      },
    );
  }
}
