import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/notifications/services/notification_service.dart';
import 'package:frontend/models/notification.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NotificationsManagement extends StatefulWidget {
  static const String routeName = '/notifications-management';
  const NotificationsManagement({super.key});

  @override
  State<NotificationsManagement> createState() =>
      _NotificationsManagementState();
}

class _NotificationsManagementState extends State<NotificationsManagement> {
  NotificationSettings _notificationSettings = NotificationSettings(
    pushNotifications: true,
    emailNotifications: true,
    preferences: NotificationPreferences(),
  );
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    await NotificationService.getNotificationSettings(
      context: context,
      onSuccess: (settings) {
        setState(() {
          _notificationSettings = settings;
          _isLoadingSettings = false;
        });
      },
    );

    if (mounted) {
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'notifications_management'.tr()),
      body: _isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nhóm Cài đặt Thông báo Chung
                    _buildSectionHeader(context, 'notifications'.tr()),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      context,
                      children: [
                        _buildSwitchTile(
                          context,
                          icon: Icons.notifications_outlined,
                          svgIcon: SvgPicture.asset(
                            'assets/icons/bell-icon.svg',
                            colorFilter: ColorFilter.mode(
                              GlobalVariables.white,
                              BlendMode.srcIn,
                            ),
                            width: 24,
                            height: 24,
                          ),
                          title: 'push_notifications'.tr(),
                          subtitle: 'receive_app_notifications'.tr(),
                          value: _notificationSettings.pushNotifications,
                          onChanged: _updatePushNotifications,
                        ),
                        const _StyledDivider(),
                        _buildSwitchTile(
                          context,
                          icon: Symbols.email,
                          title: 'email_notifications'.tr(),
                          subtitle: 'receive_email_notifications'.tr(),
                          value: _notificationSettings.emailNotifications,
                          onChanged: _updateEmailNotifications,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 24,
                    ),
                    // Nhóm Tùy chỉnh Thông báo
                    _buildSectionHeader(context, tr('customize_notifications')),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      context,
                      children: [
                        _buildSwitchTile(
                          context,
                          icon: Symbols.alarm,
                          title: tr('notif_pref_deadline'),
                          subtitle: tr('notif_pref_deadline_desc'),
                          value: _notificationSettings
                              .preferences
                              .projectDeadlineWarnings,
                          onChanged: (value) {
                            _updatePreference('projectDeadlineWarnings', value);
                          },
                        ),
                        const _StyledDivider(),
                        _buildSwitchTile(
                          context,
                          icon: Symbols.schedule,
                          title: tr('notif_pref_task_deadline'),
                          subtitle: tr('notif_pref_task_deadline_desc'),
                          value: _notificationSettings
                              .preferences
                              .taskDeadlineWarnings,
                          onChanged: (value) {
                            _updatePreference('taskDeadlineWarnings', value);
                          },
                        ),
                        const _StyledDivider(),
                        _buildSwitchTile(
                          context,
                          icon: Symbols.task_alt,
                          title: tr('notif_pref_task_assigned'),
                          subtitle: tr('notif_pref_task_assigned_desc'),
                          value:
                              _notificationSettings.preferences.taskAssignments,
                          onChanged: (value) {
                            _updatePreference('taskAssignments', value);
                          },
                        ),
                        const _StyledDivider(),
                        _buildSwitchTile(
                          context,
                          icon: Symbols.group_add,
                          title: tr('notif_pref_invitation'),
                          subtitle: tr('notif_pref_invitation_desc'),
                          value: _notificationSettings
                              .preferences
                              .projectInvitations,
                          onChanged: (value) {
                            _updatePreference('projectInvitations', value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Tiêu đề cho mỗi nhóm cài đặt
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  // Widget 'Card' tùy chỉnh cho mỗi nhóm
  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        // Clip để các góc của ListTile cũng được bo tròn
        borderRadius: BorderRadius.circular(10),
        child: Column(children: children),
      ),
    );
  }

  // Widget SwitchListTile nhất quán cho tất cả cài đặt
  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    SvgPicture? svgIcon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: GlobalVariables.backgroundBlueLight,
          borderRadius: BorderRadius.circular(8.5),
        ),
        child:
        svgIcon ?? Icon(icon, color: GlobalVariables.white, size: 24, fill: 1),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: GlobalVariables.white,
      activeTrackColor: GlobalVariables.backgroundBlueLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  // Các hàm logic (không thay đổi)
  Future<void> _updatePushNotifications(bool value) async {
    setState(() {
      _notificationSettings = _notificationSettings.copyWith(
        pushNotifications: value,
      );
    });

    await NotificationService.updateNotificationSettings(
      context: context,
      pushNotifications: value,
      onSuccess: () {},
    );
  }

  Future<void> _updateEmailNotifications(bool value) async {
    setState(() {
      _notificationSettings = _notificationSettings.copyWith(
        emailNotifications: value,
      );
    });

    await NotificationService.updateNotificationSettings(
      context: context,
      emailNotifications: value,
      onSuccess: () {},
    );
  }

  Future<void> _updatePreference(String key, bool value) async {
    NotificationPreferences updatedPreferences;

    switch (key) {
      case 'projectDeadlineWarnings':
        updatedPreferences = _notificationSettings.preferences.copyWith(
          projectDeadlineWarnings: value,
        );
        break;
      case 'taskDeadlineWarnings':
        updatedPreferences = _notificationSettings.preferences.copyWith(
          taskDeadlineWarnings: value,
        );
        break;
      case 'taskAssignments':
        updatedPreferences = _notificationSettings.preferences.copyWith(
          taskAssignments: value,
        );
        break;
      case 'projectInvitations':
        updatedPreferences = _notificationSettings.preferences.copyWith(
          projectInvitations: value,
        );
        break;
      default:
        return;
    }

    setState(() {
      _notificationSettings = _notificationSettings.copyWith(
        preferences: updatedPreferences,
      );
    });

    await NotificationService.updateNotificationSettings(
      context: context,
      preferences: updatedPreferences,
      onSuccess: () {},
    );
  }
}

class _StyledDivider extends StatelessWidget {
  const _StyledDivider({super.key}); // ignore: unused_element_parameter

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
      indent: 20, // Thụt lề trái
      endIndent: 20, // Thụt lề phải
    );
  }
}
