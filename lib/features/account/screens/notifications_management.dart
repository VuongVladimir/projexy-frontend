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
                          iconBackgroundColor: GlobalVariables.orangeBadge,
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
                          icon: Symbols.email_rounded,
                          iconBackgroundColor: GlobalVariables.redPinkBadge,
                          title: 'email_notifications'.tr(),
                          subtitle: 'receive_email_notifications'.tr(),
                          value: _notificationSettings.emailNotifications,
                          onChanged: _updateEmailNotifications,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    // Nhóm Tùy chỉnh Thông báo
                    _buildSectionHeader(context, tr('customize_notifications')),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      context,
                      children: _buildNotificationPreferenceTiles(context),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildNotificationPreferenceTiles(BuildContext context) {
    final configs = _buildNotificationPreferenceConfigs(context);
    final tiles = <Widget>[];

    for (var i = 0; i < configs.length; i++) {
      final config = configs[i];
      tiles.add(
        _buildSwitchTile(
          context,
          icon: config.icon,
          iconBackgroundColor: config.color,
          title: config.title,
          subtitle: config.subtitle,
          value: config.value,
          onChanged: (value) => _updatePreference(config.key, value),
        ),
      );

      if (i < configs.length - 1) {
        tiles.add(const _StyledDivider());
      }
    }

    return tiles;
  }

  List<_NotificationPreferenceConfig> _buildNotificationPreferenceConfigs(
    BuildContext context,
  ) {
    final preferences = _notificationSettings.preferences;
    const fullChannels = 'In-app • Push • Email';
    const inAppOnly = 'In-app';

    return [
      _NotificationPreferenceConfig(
        key: 'projectInvitations',
        icon: Symbols.group_add_rounded,
        title: tr('notification_type_invitation'),
        subtitle: fullChannels,
        value: preferences.projectInvitations,
        color: GlobalVariables.blueBadge,
      ),
      _NotificationPreferenceConfig(
        key: 'invitationDeclined',
        icon: Symbols.cancel_rounded,
        title: tr('notification_type_declined'),
        subtitle: inAppOnly,
        value: preferences.invitationDeclined,
        color: GlobalVariables.purpleBadge,
      ),

      _NotificationPreferenceConfig(
        key: 'projectCompleted',
        icon: Symbols.celebration_rounded,
        title: tr('notification_type_project_completed'),
        subtitle: inAppOnly,
        value: preferences.projectCompleted,
        color: GlobalVariables.greenBadge,
      ),

      _NotificationPreferenceConfig(
        key: 'taskDueToday',
        icon: Symbols.watch_later_rounded,
        title: tr('notification_type_due_today'),
        subtitle: fullChannels,
        value: preferences.taskDueToday,
        color: GlobalVariables.orangeBadge,
      ),
      _NotificationPreferenceConfig(
        key: 'taskOverdue',
        icon: Symbols.event_busy_rounded,
        title: tr('notification_type_overdue'),
        subtitle: fullChannels,
        value: preferences.taskOverdue,
        color: GlobalVariables.redPinkBadge,
      ),
      _NotificationPreferenceConfig(
        key: 'projectOverdue',
        icon: Symbols.event_busy_rounded,
        title: tr('notification_type_project_overdue'),
        subtitle: fullChannels,
        value: preferences.projectOverdue,
        color: GlobalVariables.redPinkBadge,
      ),
      _NotificationPreferenceConfig(
        key: 'taskCompleted',
        icon: Symbols.check_circle_rounded,
        title: tr('notification_type_task_completed'),
        subtitle: inAppOnly,
        value: preferences.taskCompleted,
        color: GlobalVariables.greenBadge,
      ),
      _NotificationPreferenceConfig(
        key: 'taskAssignments',
        icon: Symbols.assignment_rounded,
        title: tr('notification_type_assigned'),
        subtitle: fullChannels,
        value: preferences.taskAssignments,
        color: GlobalVariables.pinkBadge,
      ),

      _NotificationPreferenceConfig(
        key: 'commentMention',
        icon: Symbols.chat_bubble_rounded,
        title: tr('notification_type_mention'),
        subtitle: inAppOnly,
        value: preferences.commentMention,
        color: GlobalVariables.greenBadge,
      ),

      _NotificationPreferenceConfig(
        key: 'premiumUpgraded',
        icon: Symbols.diamond_rounded,
        title: tr('notification_type_premium_upgraded'),
        subtitle: fullChannels,
        value: preferences.premiumUpgraded,
        color: GlobalVariables.premiumBadge,
      ),

      _NotificationPreferenceConfig(
        key: 'premiumExpired',
        icon: Symbols.lock_clock_rounded,
        title: tr('notification_type_premium_expired'),
        subtitle: fullChannels,
        value: preferences.premiumExpired,
        color: GlobalVariables.redPinkBadge,
      ),

      _NotificationPreferenceConfig(
        key: 'memberJoined',
        icon: Symbols.person_add_rounded,
        title: tr('notification_type_member_joined'),
        subtitle: inAppOnly,
        value: preferences.memberJoined,
        color: GlobalVariables.blueBadge,
      ),

      _NotificationPreferenceConfig(
        key: 'memberLeft',
        icon: Symbols.person_remove_rounded,
        title: tr('notification_type_member_left'),
        subtitle: inAppOnly,
        value: preferences.memberLeft,
        color: GlobalVariables.purpleBadge,
      ),

      _NotificationPreferenceConfig(
        key: 'memberRemoved',
        icon: Symbols.group_remove_rounded,
        title: tr('notification_type_member_removed'),
        subtitle: inAppOnly,
        value: preferences.memberRemoved,
        color: GlobalVariables.purpleBadge,
      ),
    ];
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
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
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
    required Color iconBackgroundColor,
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
          color: iconBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            svgIcon ??
            Icon(
              icon,
              color: GlobalVariables.white,
              size: 24,
              fill: 1,
              weight: 600,
              grade: 300,
            ),
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
      activeThumbColor: GlobalVariables.white,
      activeTrackColor: GlobalVariables.primaryBlue,
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
    final current = _notificationSettings.preferences;

    final updatedPreferences = switch (key) {
      'projectInvitations' => current.copyWith(projectInvitations: value),
      'invitationDeclined' => current.copyWith(invitationDeclined: value),
      'taskAssignments' => current.copyWith(taskAssignments: value),
      'taskDueToday' => current.copyWith(taskDueToday: value),
      'taskOverdue' => current.copyWith(taskOverdue: value),
      'projectOverdue' => current.copyWith(projectOverdue: value),
      'taskCompleted' => current.copyWith(taskCompleted: value),
      'projectCompleted' => current.copyWith(projectCompleted: value),
      'memberJoined' => current.copyWith(memberJoined: value),
      'memberRemoved' => current.copyWith(memberRemoved: value),
      'memberLeft' => current.copyWith(memberLeft: value),
      'commentMention' => current.copyWith(commentMention: value),
      'premiumUpgraded' => current.copyWith(premiumUpgraded: value),
      'premiumExpired' => current.copyWith(premiumExpired: value),
      _ => current,
    };

    if (identical(updatedPreferences, current)) return;

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

class _NotificationPreferenceConfig {
  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;

  const _NotificationPreferenceConfig({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
  });
}
