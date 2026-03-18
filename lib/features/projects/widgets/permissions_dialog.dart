import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/projects/services/projects_service.dart';
import 'package:frontend/models/project.dart';

class PermissionsDialog extends StatefulWidget {
  final ProjectMember member;
  final ProjectMember currentUserMember;
  final String projectId;
  final bool isOwner;
  final VoidCallback onPermissionsUpdated;

  const PermissionsDialog({
    super.key,
    required this.member,
    required this.currentUserMember,
    required this.projectId,
    required this.isOwner,
    required this.onPermissionsUpdated,
  });

  @override
  State<PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<PermissionsDialog> {
  late String _selectedRole;
  late ProjectPermissions _permissions;
  bool _showCustomPermissions = true;
  bool _showRolePermissions = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.member.role;
    _permissions = widget.member.permissions;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Kiểm tra xem member target có phải Manager không
    // Nếu current user không phải Owner thì không được chỉnh cho Manager
    final isTargetManager = widget.member.role == 'Manager';
    final hasManageAccessPermission =
        widget.isOwner ||
        widget.currentUserMember.permissions.manageAccessPermission;
    final canManageTarget =
        hasManageAccessPermission && (widget.isOwner || !isTargetManager);
    final isSelf = widget.member.userId == widget.currentUserMember.userId;
    final isReadOnlyMode = !canManageTarget && isSelf;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(
              'manage_role_permissions_name',
              namedArgs: {'name': widget.member.userName ?? 'thành viên'},
            ),
          ),
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
      content: (canManageTarget || isReadOnlyMode)
          ? SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role Selection Section
                  if (!isReadOnlyMode) ...[
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
                    const SizedBox(height: 16),
                    _buildPermissionsPreview(),
                    const SizedBox(height: 20),
                  ],

                  // Custom Permissions toggle (chỉ cho Member và Manager, không cho Viewer)
                  if (!isReadOnlyMode && _selectedRole != 'Viewer') ...[
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showCustomPermissions = !_showCustomPermissions;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _showCustomPermissions
                              ? GlobalVariables.warningAmber.withValues(
                                  alpha: 0.1,
                                )
                              : (isDarkMode
                                    ? GlobalVariables.darkSurfaceCard
                                    : GlobalVariables.surfaceCard),
                          border: Border.all(
                            color: _showCustomPermissions
                                ? GlobalVariables.warningAmber
                                : (isDarkMode
                                      ? GlobalVariables.darkBorderPrimary
                                      : GlobalVariables.borderPrimary),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: _showCustomPermissions
                                  ? GlobalVariables.warningAmber
                                  : (isDarkMode
                                        ? GlobalVariables.darkTextSecondary
                                        : GlobalVariables.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tr('effective_permissions'),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _showCustomPermissions
                                      ? GlobalVariables.warningAmber
                                      : (isDarkMode
                                            ? GlobalVariables.darkTextPrimary
                                            : GlobalVariables.textPrimary),
                                ),
                              ),
                            ),
                            Icon(
                              _showCustomPermissions
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: isDarkMode
                                  ? GlobalVariables.darkTextSecondary
                                  : GlobalVariables.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (isReadOnlyMode && _selectedRole != 'Viewer') ...[
                    Text(
                      tr('custom_permissions'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? GlobalVariables.darkTextPrimary
                            : GlobalVariables.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if ((isReadOnlyMode || _showCustomPermissions) &&
                      _selectedRole != 'Viewer') ...[
                    _buildPermissionTile(
                      tr('edit_project'),
                      tr('permission_edit_project'),
                      Icons.settings_rounded,
                      _permissions.editProjectPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                editProjectPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('add_member'),
                      tr('permission_add_member'),
                      Icons.person_add_rounded,
                      _permissions.addMemberPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                addMemberPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('remove_member'),
                      tr('permission_remove_member'),
                      Icons.person_remove_rounded,
                      _permissions.removeMemberPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                removeMemberPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('manage_access'),
                      tr('permission_manage_access'),
                      Icons.admin_panel_settings_rounded,
                      _permissions.manageAccessPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                manageAccessPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('create_task'),
                      tr('permission_create_task'),
                      Icons.add_task_rounded,
                      _permissions.createTaskPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                createTaskPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('edit_task'),
                      tr('permission_edit_task'),
                      Icons.edit_rounded,
                      _permissions.editTaskPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                editTaskPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('delete_task'),
                      tr('permission_delete_task'),
                      Icons.delete_rounded,
                      _permissions.deleteTaskPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                deleteTaskPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('assign_task'),
                      tr('permission_assign_task'),
                      Icons.person_add_alt_rounded,
                      _permissions.assignTaskPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                assignTaskPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('mark_complete_task'),
                      tr('permission_mark_complete_task'),
                      Icons.check_circle_rounded,
                      _permissions.markCompleteTaskPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                markCompleteTaskPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('add_attachment'),
                      tr('permission_add_attachment'),
                      Icons.attach_file_rounded,
                      _permissions.addAttachmentPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                addAttachmentPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('delete_attachment'),
                      tr('permission_delete_attachment'),
                      Icons.delete_sweep_rounded,
                      _permissions.deleteAttachmentPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                deleteAttachmentPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('add_comment'),
                      tr('permission_add_comment'),
                      Icons.comment_rounded,
                      _permissions.addCommentPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                addCommentPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                    _buildPermissionTile(
                      tr('delete_comment'),
                      tr('permission_delete_comment'),
                      Icons.delete_outline_rounded,
                      _permissions.deleteCommentPermission,
                      isReadOnlyMode
                          ? null
                          : (value) => setState(
                              () => _permissions = _permissions.copyWith(
                                deleteCommentPermission: value,
                              ),
                            ),
                      enabled: !isReadOnlyMode,
                    ),
                  ],
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                tr('only_owner_can_manage_manager'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: GlobalVariables.warningAmber,
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel')),
        ),
        canManageTarget
            ? ElevatedButton(
                onPressed: _savePermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalVariables.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(tr('save')),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildCurrentRoleView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? GlobalVariables.darkSurfaceCard
            : GlobalVariables.surfaceCard,
        border: Border.all(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        widget.member.roleDisplayName,
        style: TextStyle(
          color: isDarkMode
              ? GlobalVariables.darkTextPrimary
              : GlobalVariables.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool>? onChanged, {
    bool enabled = true,
  }) {
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
      child: IgnorePointer(
        ignoring: !enabled,
        child: CheckboxListTile(
          value: value,
          onChanged: (newValue) => onChanged?.call(newValue ?? false),
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
          activeColor: enabled
              ? GlobalVariables.primaryBlue
              : GlobalVariables.successGreen,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final roles = [
      {
        'value': 'Manager',
        'label': tr('manager'),
        'icon': Icons.admin_panel_settings_outlined,
      },
      {'value': 'Member', 'label': tr('member'), 'icon': Icons.person_outline},
      {
        'value': 'Viewer',
        'label': tr('viewer'),
        'icon': Icons.visibility_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: roles.asMap().entries.map((entry) {
            final index = entry.key;
            final role = entry.value;
            final isSelected = _selectedRole == role['value'];
            // Chỉ Owner mới có thể chọn role Manager
            final isDisabled = role['value'] == 'Manager' && !widget.isOwner;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isDisabled
                      ? null
                      : () {
                          setState(() {
                            _selectedRole = role['value'] as String;
                            // Nếu chọn Viewer, ẩn custom permissions
                            if (_selectedRole == 'Viewer') {
                              _showCustomPermissions = false;
                            }
                          });
                        },
                  child: Opacity(
                    opacity: isDisabled ? 0.45 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GlobalVariables.primaryBlue.withValues(
                                alpha: 0.08,
                              )
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            role['icon'] as IconData,
                            size: 28,
                            color: isSelected
                                ? GlobalVariables.primaryBlue
                                : (isDarkMode
                                      ? GlobalVariables.darkTextSecondary
                                      : GlobalVariables.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (role['label'] as String),
                            style: TextStyle(
                              color: isSelected
                                  ? GlobalVariables.primaryBlue
                                  : (isDarkMode
                                        ? GlobalVariables.darkTextPrimary
                                        : GlobalVariables.textPrimary),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Thông báo nếu không phải Owner
        if (!widget.isOwner)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              tr('only_owner_can_promote_to_manager'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: GlobalVariables.warningAmber,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionsPreview() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Mô tả permissions mặc định theo role
    Map<String, List<String>> rolePermissions = {
      'Manager': [
        tr('edit_project'),
        tr('add_member'),
        tr('remove_member'),
        tr('manage_access'),
        tr('create_task'),
        tr('edit_task'),
        tr('delete_task'),
        tr('assign_task'),
        tr('mark_complete_task'),
        tr('add_attachment'),
        tr('delete_attachment'),
        tr('add_comment'),
        tr('delete_comment'),
      ],
      'Member': [tr('add_attachment'), tr('add_comment')],
      'Viewer': [tr('view_only')],
    };

    final permissions = rolePermissions[_selectedRole] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showRolePermissions = !_showRolePermissions;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _showRolePermissions
                  ? GlobalVariables.primaryBlue.withValues(alpha: 0.06)
                  : (isDarkMode
                        ? GlobalVariables.darkSurfaceCard
                        : GlobalVariables.surfaceCard),
              border: Border.all(
                color: _showRolePermissions
                    ? GlobalVariables.primaryBlue.withValues(alpha: 0.3)
                    : (isDarkMode
                          ? GlobalVariables.darkBorderPrimary
                          : GlobalVariables.borderPrimary),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.manage_accounts_outlined,
                  size: 23,
                  color: _showRolePermissions
                      ? GlobalVariables.primaryBlue
                      : (isDarkMode
                            ? GlobalVariables.darkTextSecondary
                            : GlobalVariables.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${tr('role_permissions')} ',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _showRolePermissions
                          ? GlobalVariables.primaryBlue
                          : (isDarkMode
                                ? GlobalVariables.darkTextPrimary
                                : GlobalVariables.textPrimary),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _showRolePermissions
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: isDarkMode
                      ? GlobalVariables.darkTextSecondary
                      : GlobalVariables.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_showRolePermissions) ...[
          const SizedBox(height: 12),
          ...List.generate((permissions.length / 2).ceil(), (rowIndex) {
            final firstIndex = rowIndex * 2;
            final secondIndex = firstIndex + 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPermissionPreviewChip(
                      permissions[firstIndex],
                      isDarkMode,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: secondIndex < permissions.length
                        ? _buildPermissionPreviewChip(
                            permissions[secondIndex],
                            isDarkMode,
                            theme,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildPermissionPreviewChip(
    String perm,
    bool isDarkMode,
    ThemeData theme,
  ) {
    return Tooltip(
      message: perm,
      waitDuration: const Duration(milliseconds: 90),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDarkMode
                ? GlobalVariables.darkBorderPrimary
                : GlobalVariables.borderPrimary,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_rounded,
              size: 14,
              color: GlobalVariables.successGreen,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                perm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePermissions() {
    final roleChanged = _selectedRole != widget.member.role;

    if (roleChanged) {
      // Cập nhật role trước (permissions sẽ tự động reset theo role mới bên backend)
      ProjectsService.updateMemberRole(
        context: context,
        projectId: widget.projectId,
        userId: widget.member.userId,
        role: _selectedRole,
        onSuccess: () {
          // Nếu có custom permissions, cập nhật sau khi role đã thay đổi
          if (_showCustomPermissions && _selectedRole != 'Viewer') {
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
            Navigator.of(context).pop();
            widget.onPermissionsUpdated();
          }
        },
      );
    } else if (_showCustomPermissions && _selectedRole != 'Viewer') {
      // Chỉ cập nhật permissions (role không thay đổi)
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
      // Không có gì thay đổi
      Navigator.of(context).pop();
    }
  }
}
