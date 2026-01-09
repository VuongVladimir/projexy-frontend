import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/projects/services/projects_service.dart';
import 'package:frontend/models/project.dart';

class PermissionsDialog extends StatefulWidget {
  final ProjectMember member;
  final ProjectMember currentUserMember;
  final String projectId;
  final VoidCallback onPermissionsUpdated;

  const PermissionsDialog({
    super.key,
    required this.member,
    required this.currentUserMember,
    required this.projectId,
    required this.onPermissionsUpdated,
  });

  @override
  State<PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<PermissionsDialog> {
  late String _selectedRole;
  late ProjectPermissions _permissions;
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.member.role;
    _permissions = widget.member.permissions;
    _isCustomMode = _selectedRole == 'Custom Role';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('manage_role_permissions', namedArgs: {'name': widget.member.userName ?? 'thành viên'})),
          Text(
            widget.member.userEmail ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role Selection Section
            Text(
              tr('select_role'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildRoleSelector(),
            const SizedBox(height: 20),

            // Custom Permissions Section (chỉ hiện khi Custom Mode)
            if (_isCustomMode) ...[
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: GlobalVariables.warningAmber),
                  const SizedBox(width: 8),
                  Text(
                    tr('custom_permissions'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? GlobalVariables.darkTextPrimary
                          : GlobalVariables.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPermissionTile(
                tr('create_task'),
                tr('permission_create_task'),
                Icons.add_task_rounded,
                _permissions.createTask,
                (value) => setState(() => _permissions = _permissions.copyWith(createTask: value)),
              ),
              _buildPermissionTile(
                tr('edit_task'),
                tr('permission_edit_task'),
                Icons.edit_rounded,
                _permissions.editTask,
                (value) => setState(() => _permissions = _permissions.copyWith(editTask: value)),
              ),
              _buildPermissionTile(
                tr('assign_task'),
                tr('permission_assign_task'),
                Icons.person_add_alt_rounded,
                _permissions.assignTask,
                (value) => setState(() => _permissions = _permissions.copyWith(assignTask: value)),
              ),
              _buildPermissionTile(
                tr('delete_task'),
                tr('permission_delete_task'),
                Icons.delete_rounded,
                _permissions.deleteTask,
                (value) => setState(() => _permissions = _permissions.copyWith(deleteTask: value)),
              ),
              _buildPermissionTile(
                tr('mark_complete_task'),
                tr('permission_mark_complete_task'),
                Icons.check_circle_rounded,
                _permissions.markCompleteTask,
                (value) => setState(() => _permissions = _permissions.copyWith(markCompleteTask: value)),
              ),
              _buildPermissionTile(
                tr('edit_project'),
                tr('permission_edit_project'),
                Icons.settings_rounded,
                _permissions.editProject,
                (value) => setState(() => _permissions = _permissions.copyWith(editProject: value)),
              ),
              _buildPermissionTile(
                tr('add_member'),
                tr('permission_add_member'),
                Icons.person_add_rounded,
                _permissions.addMember,
                (value) => setState(() => _permissions = _permissions.copyWith(addMember: value)),
              ),
              _buildPermissionTile(
                tr('remove_member'),
                tr('permission_remove_member'),
                Icons.person_remove_rounded,
                _permissions.removeMember,
                (value) => setState(() => _permissions = _permissions.copyWith(removeMember: value)),
              ),
              _buildPermissionTile(
                tr('edit_role'),
                tr('permission_edit_role'),
                Icons.admin_panel_settings_rounded,
                _permissions.editRole,
                (value) => setState(() => _permissions = _permissions.copyWith(editRole: value)),
              ),
            ] else ...[
              // Display permissions preview for predefined roles
              _buildPermissionsPreview(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _savePermissions,
          style: ElevatedButton.styleFrom(
            backgroundColor: GlobalVariables.primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: Text(tr('save')),
        ),
      ],
    );
  }

  Widget _buildPermissionTile(
    String title,
    String description,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (newValue) => onChanged(newValue ?? false),
        title: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: value 
                  ? GlobalVariables.primaryBlue
                  : (isDarkMode
                      ? GlobalVariables.darkTextSecondary
                      : GlobalVariables.textSecondary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
        ),
        activeColor: GlobalVariables.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final roles = [
      {'value': 'Manager', 'label': tr('manager'), 'icon': Icons.supervisor_account_rounded},
      {'value': 'Member', 'label': tr('member'), 'icon': Icons.person_rounded},
      {'value': 'Viewer', 'label': tr('viewer'), 'icon': Icons.visibility_rounded},
      {'value': 'Custom Role', 'label': tr('custom_role'), 'icon': Icons.tune_rounded},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles.map((role) {
        final isSelected = _selectedRole == role['value'];
        return InkWell(
          onTap: () {
            setState(() {
              _selectedRole = role['value'] as String;
              _isCustomMode = _selectedRole == 'Custom Role';
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? GlobalVariables.primaryBlue.withValues(alpha: 0.1)
                  : (isDarkMode
                      ? GlobalVariables.darkSurfaceCard
                      : GlobalVariables.surfaceCard),
              border: Border.all(
                color: isSelected
                    ? GlobalVariables.primaryBlue
                    : (isDarkMode
                        ? GlobalVariables.darkBorderPrimary
                        : GlobalVariables.borderPrimary),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  role['icon'] as IconData,
                  size: 20,
                  color: isSelected
                      ? GlobalVariables.primaryBlue
                      : (isDarkMode
                          ? GlobalVariables.darkTextSecondary
                          : GlobalVariables.textSecondary),
                ),
                const SizedBox(width: 8),
                Text(
                  role['label'] as String,
                  style: TextStyle(
                    color: isSelected
                        ? GlobalVariables.primaryBlue
                        : (isDarkMode
                            ? GlobalVariables.darkTextPrimary
                            : GlobalVariables.textPrimary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionsPreview() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Mô tả permissions theo role
    Map<String, List<String>> rolePermissions = {
      'Manager': [
        tr('create_task'),
        tr('edit_task'),
        tr('assign_task'),
        tr('delete_task'),
        tr('edit_project'),
        tr('add_member'),
        tr('remove_member'),
        tr('edit_role'),
        tr('mark_complete_task'),
      ],
      'Member': [tr('mark_complete_task')],
      'Viewer': [tr('view_only')],
    };

    final permissions = rolePermissions[_selectedRole] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlobalVariables.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: GlobalVariables.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: GlobalVariables.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                tr('role_permissions'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: GlobalVariables.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...permissions.map((perm) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: GlobalVariables.successGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    perm,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDarkMode
                          ? GlobalVariables.darkTextPrimary
                          : GlobalVariables.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  void _savePermissions() {
    print('Role current user: ${widget.currentUserMember.role}');
    if (_isCustomMode) {
      // Lưu custom permissions
      if(widget.currentUserMember.role == 'Manager') {
        // Chỉ có owner mới có thể cấp permissions thủ công
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            //title: Text(tr('error')),
            content: Text(tr('only_owner_can_set_custom_permissions')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('ok')),
              ),
            ],
          ),
        );
        return;
      }
      ProjectsService.updateMemberPermissions(
        context: context,
        projectId: widget.projectId,
        userId: widget.member.userId,
        permissions: _permissions.toMap().cast<String, bool>(),
        onSuccess: () {
          Navigator.of(context).pop();
          widget.onPermissionsUpdated();
        },
      );
    } else {
      // Lưu role mới
      ProjectsService.updateMemberRole(
        context: context,
        projectId: widget.projectId,
        userId: widget.member.userId,
        role: _selectedRole,
        onSuccess: () {
          Navigator.of(context).pop();
          widget.onPermissionsUpdated();
        },
      );
    }
  }
}
