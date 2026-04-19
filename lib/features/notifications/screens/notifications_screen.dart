import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/account/screens/payment_history_screen.dart';
import 'package:frontend/features/notifications/services/notification_service.dart';
import 'package:frontend/models/notification.dart';
import 'package:material_symbols_icons/symbols.dart';

class NotificationsScreen extends StatefulWidget {
  static const String routeName = '/notifications';

  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  List<AppNotification> _notifications = [];
  List<AppNotification> _filteredNotifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  int _total = 0;

  late TabController _tabController;
  String _currentFilter = 'all';
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentFilter = switch (_tabController.index) {
          1 => 'unread',
          2 => 'read',
          _ => 'all',
        };
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    _filteredNotifications = _notifications.where((notification) {
      var matchesReadFilter = true;
      if (_currentFilter == 'unread') {
        matchesReadFilter = !notification.isRead;
      } else if (_currentFilter == 'read') {
        matchesReadFilter = notification.isRead;
      }

      var matchesTypeFilter = true;
      if (_selectedType != null && _selectedType!.isNotEmpty) {
        matchesTypeFilter = notification.type == _selectedType;
      }

      return matchesReadFilter && matchesTypeFilter;
    }).toList();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    await NotificationService.getNotifications(
      context: context,
      onSuccess: (notifications, total, unreadCount, hasMore) {
        setState(() {
          _notifications = notifications;
          _total = total;
          _unreadCount = unreadCount;
          _applyFilters();
          _isLoading = false;
        });
      },
    );

    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDarkMode
        ? GlobalVariables.darkBackgroundPrimary
        : GlobalVariables.backgroundPrimary;

    return Scaffold(
      backgroundColor: screenBg,
      appBar: CustomAppBar(
        title: tr('notifications'),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: tr('notification_mark_all_read'),
              onPressed: _markAllAsRead,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (value) {
              if (value == 'clear_read') {
                _clearReadNotifications();
              } else if (value == 'filter') {
                _showFilterDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    const Icon(Icons.filter_list_rounded),
                    const SizedBox(width: 8),
                    Text(tr('notification_filter_by_type')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_read',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_rounded),
                    const SizedBox(width: 8),
                    Text(tr('notification_clear_read')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(isDarkMode),
          if (_selectedType != null) _buildActiveFilter(isDarkMode),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredNotifications.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 12, bottom: 21),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) => _buildNotificationRow(
                        _filteredNotifications[index],
                        isDarkMode,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDarkMode) {
    return Container(
      color: isDarkMode
          ? GlobalVariables.darkSurfaceCard
          : GlobalVariables.surfaceCard,
      child: TabBar(
        controller: _tabController,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 2.5,
            color: GlobalVariables.primaryBlue,
          ),
        ),
        dividerColor: Colors.transparent,
        labelColor: GlobalVariables.primaryBlue,
        unselectedLabelColor: isDarkMode
            ? GlobalVariables.darkTextSecondary
            : GlobalVariables.textSecondary,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(
            text:
                '${tr('notification_tab_all')} (${_total > 99 ? '99+' : _total})',
          ),
          Tab(
            text:
                '${tr('notification_tab_unread')} (${_unreadCount > 99 ? '99+' : _unreadCount})',
          ),
          Tab(text: tr('notification_tab_read')),
        ],
      ),
    );
  }

  Widget _buildActiveFilter(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkMode
          ? GlobalVariables.darkSurfaceCard
          : GlobalVariables.surfaceCard,
      child: Wrap(
        spacing: 8,
        children: [
          Chip(
            avatar: const Icon(Icons.filter_list_rounded, size: 16),
            label: Text(_getTypeDisplayName(_selectedType!)),
            onDeleted: () {
              setState(() {
                _selectedType = null;
                _applyFilters();
              });
            },
            deleteIcon: const Icon(Icons.close_rounded, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    var message = tr('notification_empty');
    var icon = Icons.notifications_none_rounded;
    if (_currentFilter == 'unread') {
      message = tr('notification_empty_unread');
      icon = Icons.mark_email_read_rounded;
    } else if (_currentFilter == 'read') {
      message = tr('notification_empty_read');
      icon = Icons.drafts_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationRow(AppNotification notification, bool isDarkMode) {
    final rowColor = notification.isRead
        ? (isDarkMode ? GlobalVariables.darkSurfaceCard : GlobalVariables.white)
        : (isDarkMode
              ? GlobalVariables.darkPrimaryBlue.withValues(alpha: 0.12)
              : const Color(0xFFEAF3FF));

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: GlobalVariables.errorRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          color: rowColor,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeading(notification),
              const SizedBox(width: 12),
              Expanded(child: _buildBody(notification, isDarkMode)),
              _buildTrailingMenu(notification),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(AppNotification notification) {
    final fromUser = notification.data.fromUser;
    final label = _buildAvatarLabel(notification);
    final bgColor = _buildAvatarColor(notification);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: bgColor,
          backgroundImage:
              (fromUser?.avatar != null && fromUser!.avatar!.isNotEmpty)
              ? NetworkImage(fromUser.avatar!)
              : null,
          child: (fromUser?.avatar == null || fromUser!.avatar!.isEmpty)
              ? Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        Positioned(
          right: -3,
          bottom: -6,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _getBadgeColor(notification.type),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getBadgeIcon(notification.type),
              fill: 1,
              weight: 600,
              grade: 300,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(AppNotification notification, bool isDarkMode) {
    final subTextColor = isDarkMode
        ? GlobalVariables.darkTextTertiary
        : GlobalVariables.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: isDarkMode
                  ? GlobalVariables.darkTextPrimary
                  : GlobalVariables.textPrimary,
              fontSize: 16,
            ),
            children: _buildMessageSpans(notification),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(notification.createdAt),
          style: TextStyle(color: subTextColor, fontSize: 12),
        ),
        if (_isPendingInvitation(notification)) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptInvitation(notification),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalVariables.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    tr('accept'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineInvitation(notification),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? GlobalVariables.darkBackgroundElevated
                        : const Color(0xFFE4E6EB),
                    foregroundColor: isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : Colors.black87,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    tr('decline'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTrailingMenu(AppNotification notification) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 30,
      height: 30,
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_horiz_rounded,
          color: isDarkMode
              ? GlobalVariables.darkTextSecondary
              : GlobalVariables.textSecondary,
        ),
        padding: EdgeInsets.zero,
        iconSize: 23,
        splashRadius: 16,
        offset: const Offset(-16, 32),
        constraints: const BoxConstraints(),
        onSelected: (value) {
          if (value == 'delete') {
            _deleteNotification(notification);
          } else if (value == 'mark_read') {
            _markNotificationAsRead(notification);
          }
        },
        itemBuilder: (context) => [
          if (!notification.isRead)
            PopupMenuItem(
              value: 'mark_read',
              child: Text(tr('notification_mark_read')),
            ),
          PopupMenuItem(value: 'delete', child: Text(tr('delete'))),
        ],
      ),
    );
  }

  Future<void> _acceptInvitation(AppNotification notification) async {
    await NotificationService.acceptProjectInvitation(
      context: context,
      notificationId: notification.id,
      onSuccess: _loadNotifications,
    );
  }

  Future<void> _declineInvitation(AppNotification notification) async {
    await NotificationService.declineProjectInvitation(
      context: context,
      notificationId: notification.id,
      onSuccess: _loadNotifications,
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    _markNotificationAsRead(notification);

    switch (notification.type) {
      case 'task_assigned':
      case 'task_completed':
      case 'comment_mention':
        _navigateToTask(notification);
        break;
      case 'project_invitation':
      case 'invitation_declined':
      case 'project_completed':
      case 'project_overdue':
      case 'member_joined':
      case 'member_removed':
      case 'member_left':
        _navigateToProject(notification);
        break;
      case 'task_due_today':
      case 'task_overdue':
        // Digest notifications có nhiều items, navigate đến task đầu tiên nếu có
        final extra = notification.data.extra;
        if (extra != null &&
            extra['items'] is List &&
            (extra['items'] as List).isNotEmpty) {
          final firstItem = (extra['items'] as List).first;
          final taskId = firstItem['taskId']?.toString();
          if (taskId != null && taskId.isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/task-detail',
              arguments: {'taskId': taskId},
            );
            return;
          }
        }
        break;
      case 'premium_upgraded':
      case 'premium_expired':
        Navigator.pushNamed(context, PaymentHistoryScreen.routeName);
        break;
      default:
        break;
    }
  }

  void _navigateToTask(AppNotification notification) {
    final taskId = notification.data.taskId;
    if (taskId == null || taskId.isEmpty) return;
    Navigator.pushNamed(context, '/task-detail', arguments: {'taskId': taskId});
  }

  void _navigateToProject(AppNotification notification) {
    final projectId = notification.data.projectId;
    if (projectId == null || projectId.isEmpty) return;
    Navigator.pushNamed(
      context,
      '/project-detail',
      arguments: {'projectId': projectId},
    );
  }

  void _markNotificationAsRead(AppNotification notification) {
    if (notification.isRead) return;
    NotificationService.markAsRead(
      context: context,
      notificationId: notification.id,
      onSuccess: (unreadCount) {
        setState(() {
          _unreadCount = unreadCount;
          final index = _notifications.indexWhere(
            (n) => n.id == notification.id,
          );
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(
              isRead: true,
            );
            _applyFilters();
          }
        });
      },
    );
  }

  void _deleteNotification(AppNotification notification) {
    NotificationService.deleteNotification(
      context: context,
      notificationId: notification.id,
      onSuccess: (unreadCount) {
        setState(() {
          _unreadCount = unreadCount;
          _notifications.removeWhere((n) => n.id == notification.id);
          _applyFilters();
        });
      },
    );
  }

  void _markAllAsRead() {
    NotificationService.markAllAsRead(
      context: context,
      onSuccess: () {
        setState(() {
          _unreadCount = 0;
          _notifications = _notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();
          _applyFilters();
        });
      },
    );
  }

  void _clearReadNotifications() {
    NotificationService.clearReadNotifications(
      context: context,
      onSuccess: () {
        setState(() {
          _notifications.removeWhere((n) => n.isRead);
          _applyFilters();
        });
      },
    );
  }

  bool _isPendingInvitation(AppNotification notification) {
    return notification.type == 'project_invitation' &&
        notification.data.invitationStatus == 'pending';
  }

  List<TextSpan> _buildMessageSpans(AppNotification notification) {
    const boldStyle = TextStyle(fontWeight: FontWeight.w700);
    final actorName =
        notification.data.fromUser?.name ??
        notification.data.fromUserName ??
        '';
    final projectTitle = notification.data.projectTitle;
    final taskTitle = notification.data.taskTitle;

    return switch (notification.type) {
      'project_invitation' => [
        TextSpan(text: actorName, style: boldStyle),
        TextSpan(text: tr('notification_invited_you')),
        TextSpan(
          text: projectTitle ?? tr('notification_a_project'),
          style: boldStyle,
        ),
      ],
      'invitation_declined' => [
        TextSpan(text: actorName, style: boldStyle),
        TextSpan(text: tr('notification_declined_invitation')),
        TextSpan(
          text: projectTitle ?? tr('notification_a_project'),
          style: boldStyle,
        ),
      ],
      'task_assigned' => [
        TextSpan(text: actorName, style: boldStyle),
        TextSpan(text: tr('notification_assigned_task')),
        TextSpan(
          text: taskTitle ?? tr('notification_a_task'),
          style: boldStyle,
        ),
      ],
      'task_completed' => [
        TextSpan(text: actorName, style: boldStyle),
        TextSpan(text: tr('notification_marked_task')),
        TextSpan(
          text: taskTitle ?? tr('notification_a_task'),
          style: boldStyle,
        ),
        TextSpan(text: tr('notification_as_completed')),
      ],
      'project_completed' => [
        TextSpan(text: actorName, style: boldStyle),
        TextSpan(text: tr('notification_marked_project')),
        TextSpan(
          text: projectTitle ?? tr('notification_a_project'),
          style: boldStyle,
        ),
        TextSpan(text: tr('notification_as_completed')),
      ],
      'member_joined' => [
        TextSpan(text: actorName, style: boldStyle),
        TextSpan(text: tr('notification_member_joined')),
        TextSpan(
          text: projectTitle ?? tr('notification_a_project'),
          style: boldStyle,
        ),
      ],
      'member_removed' => _buildMemberRemovedSpans(notification, boldStyle),
      'member_left' => [
        TextSpan(text: actorName, style: boldStyle),
        TextSpan(text: tr('notification_member_left')),
        TextSpan(
          text: projectTitle ?? tr('notification_a_project'),
          style: boldStyle,
        ),
      ],
      'comment_mention' => [
        TextSpan(text: actorName, style: boldStyle),
        TextSpan(text: tr('notification_mentioned_you')),
        TextSpan(
          text: taskTitle ?? tr('notification_a_task'),
          style: boldStyle,
        ),
      ],
      'task_due_today' ||
      'task_overdue' ||
      'project_overdue' => _buildDigestSpans(notification, boldStyle),
      'premium_upgraded' ||
      'premium_expired' => _buildPremiumSpans(notification),
      _ => [TextSpan(text: notification.message)],
    };
  }

  List<TextSpan> _buildMemberRemovedSpans(
    AppNotification notification,
    TextStyle boldStyle,
  ) {
    final actorName =
        notification.data.fromUser?.name ??
        notification.data.fromUserName ??
        '';
    final projectTitle = notification.data.projectTitle;
    final removedUserName =
        notification.data.extra?['removedUserName'] as String?;

    if (removedUserName != null) {
      return [
        TextSpan(text: actorName, style: boldStyle),
        TextSpan(text: tr('notification_has_removed')),
        TextSpan(text: removedUserName, style: boldStyle),
        TextSpan(text: tr('notification_from_project')),
        TextSpan(
          text: projectTitle ?? tr('notification_a_project'),
          style: boldStyle,
        ),
      ];
    } else {
      return [
        TextSpan(text: tr('notification_you_removed_from_project')),
        TextSpan(
          text: projectTitle ?? tr('notification_a_project'),
          style: boldStyle,
        ),
        TextSpan(text: tr('notification_removed_by')),
        TextSpan(text: actorName, style: boldStyle),
      ];
    }
  }

  List<TextSpan> _buildDigestSpans(
    AppNotification notification,
    TextStyle boldStyle,
  ) {
    final extra = notification.data.extra;
    final rawItems = extra?['items'] as List? ?? [];
    final count = (extra?['count'] as num?)?.toInt() ?? rawItems.length;

    if (rawItems.isEmpty) {
      return [TextSpan(text: notification.message)];
    }

    final spans = <TextSpan>[];

    switch (notification.type) {
      case 'task_due_today':
        final taskWord = count == 1
            ? tr('notification_task_word')
            : tr('notification_tasks_word');
        spans.add(
          TextSpan(text: '${tr('notification_you_have')}$count $taskWord '),
        );
        spans.add(
          TextSpan(text: tr('notification_due_today_label'), style: boldStyle),
        );
        spans.add(const TextSpan(text: ': '));
        for (var i = 0; i < rawItems.length; i++) {
          if (i > 0) spans.add(const TextSpan(text: ', '));
          final name = rawItems[i] is Map
              ? (rawItems[i] as Map)['taskTitle']?.toString() ?? ''
              : '';
          spans.add(TextSpan(text: name, style: boldStyle));
        }
        break;
      case 'task_overdue':
        final taskWord = count == 1
            ? tr('notification_task_word')
            : tr('notification_tasks_word');
        spans.add(TextSpan(text: '${tr('notification_you_have')}$count '));
        spans.add(
          TextSpan(text: tr('notification_overdue_label'), style: boldStyle),
        );
        spans.add(TextSpan(text: ' $taskWord: '));
        for (var i = 0; i < rawItems.length; i++) {
          if (i > 0) spans.add(const TextSpan(text: ', '));
          final name = rawItems[i] is Map
              ? (rawItems[i] as Map)['taskTitle']?.toString() ?? ''
              : '';
          spans.add(TextSpan(text: name, style: boldStyle));
        }
        break;
      case 'project_overdue':
        final projectWord = count == 1
            ? tr('notification_project_word')
            : tr('notification_projects_word');
        spans.add(TextSpan(text: '${tr('notification_you_have')}$count '));
        spans.add(
          TextSpan(text: tr('notification_overdue_label'), style: boldStyle),
        );
        spans.add(TextSpan(text: ' $projectWord: '));
        for (var i = 0; i < rawItems.length; i++) {
          if (i > 0) spans.add(const TextSpan(text: ', '));
          final name = rawItems[i] is Map
              ? (rawItems[i] as Map)['projectTitle']?.toString() ?? ''
              : '';
          spans.add(TextSpan(text: name, style: boldStyle));
        }
        break;
    }

    return spans;
  }

  List<TextSpan> _buildPremiumSpans(AppNotification notification) {
    final extra = notification.data.extra;

    if (notification.type == 'premium_upgraded') {
      final rawValidUntil = extra?['premiumValidUntil']?.toString();
      if (rawValidUntil != null) {
        final validUntil = DateTime.tryParse(rawValidUntil);
        if (validUntil != null) {
          final localValidUntil = validUntil.toLocal();
          return [
            TextSpan(
              text: tr(
                'notification_premium_upgraded_until',
                namedArgs: {
                  'date': DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(localValidUntil),
                },
              ),
            ),
          ];
        }
      }

      return [TextSpan(text: tr('notification_premium_upgraded'))];
    }

    if (notification.type == 'premium_expired') {
      final rawExpiredAt = extra?['expiredAt']?.toString();
      if (rawExpiredAt != null) {
        final expiredAt = DateTime.tryParse(rawExpiredAt);
        if (expiredAt != null) {
          final localExpiredAt = expiredAt.toLocal();
          return [
            TextSpan(
              text: tr(
                'notification_premium_expired_at',
                namedArgs: {
                  'date': DateFormat('dd/MM/yyyy HH:mm').format(localExpiredAt),
                },
              ),
            ),
          ];
        }
      }

      return [TextSpan(text: tr('notification_premium_expired'))];
    }

    return [TextSpan(text: notification.message)];
  }

  String _buildAvatarLabel(AppNotification notification) {
    final source =
        notification.data.fromUser?.name ??
        notification.data.projectTitle ??
        notification.data.taskTitle ??
        notification.title;
    if (source.isEmpty) return 'N';
    return source[0].toUpperCase();
  }

  Color _buildAvatarColor(AppNotification notification) {
    final userColor = notification.data.fromUser?.avatarColor;
    if (userColor != null && userColor.isNotEmpty) return userColor.toColor();

    final projectCreatorColor =
        notification.data.project?.createdBy?.avatarColor;
    if (projectCreatorColor != null && projectCreatorColor.isNotEmpty) {
      return projectCreatorColor.toColor();
    }

    final taskCreatorColor = notification.data.task?.createdBy?.avatarColor;
    if (taskCreatorColor != null && taskCreatorColor.isNotEmpty) {
      return taskCreatorColor.toColor();
    }

    return GlobalVariables.backgroundBlueLight;
  }

  IconData _getBadgeIcon(String type) {
    return switch (type) {
      'project_invitation' => Symbols.group_add_rounded,
      'invitation_declined' => Symbols.cancel_rounded,
      'task_assigned' => Symbols.assignment_rounded,
      'task_due_today' => Symbols.watch_later_rounded,
      'task_overdue' => Symbols.event_busy_rounded,
      'project_overdue' => Symbols.event_busy_rounded,
      'task_completed' => Symbols.check_circle_rounded,
      'project_completed' => Symbols.celebration_rounded,
      'member_joined' => Symbols.person_add_rounded,
      'member_removed' => Symbols.group_remove_rounded,
      'member_left' => Symbols.person_remove_rounded,
      'comment_mention' => Symbols.chat_bubble_rounded,
      'premium_upgraded' => Symbols.diamond_rounded,
      'premium_expired' => Symbols.lock_clock_rounded,
      _ => Symbols.notifications_rounded,
    };
  }

  Color _getBadgeColor(String type) {
    return switch (type) {
      'task_assigned' => GlobalVariables.pinkBadge,
      'task_completed' ||
      'project_completed' ||
      'comment_mention' => GlobalVariables.greenBadge,
      'task_due_today' => GlobalVariables.orangeBadge,
      'task_overdue' || 'project_overdue' => GlobalVariables.redPinkBadge,
      'member_removed' ||
      'member_left' ||
      'invitation_declined' => GlobalVariables.purpleBadge,
      'premium_upgraded' => GlobalVariables.premiumBadge,
      'premium_expired' => GlobalVariables.redPinkBadge,
      _ => GlobalVariables.blueBadge,
    };
  }

  String _getTypeDisplayName(String type) {
    return switch (type) {
      'project_invitation' => tr('notification_type_invitation'),
      'invitation_declined' => tr('notification_type_declined'),
      'task_assigned' => tr('notification_type_assigned'),
      'task_due_today' => tr('notification_type_due_today'),
      'task_overdue' => tr('notification_type_overdue'),
      'project_overdue' => tr('notification_type_project_overdue'),
      'task_completed' => tr('notification_type_task_completed'),
      'project_completed' => tr('notification_type_project_completed'),
      'member_joined' => tr('notification_type_member_joined'),
      'member_removed' => tr('notification_type_member_removed'),
      'member_left' => tr('notification_type_member_left'),
      'comment_mention' => tr('notification_type_mention'),
      'premium_upgraded' => tr('notification_type_premium_upgraded'),
      'premium_expired' => tr('notification_type_premium_expired'),
      _ => tr('notification_type_general'),
    };
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return tr('time_just_now');
    if (difference.inHours < 1) {
      return tr(
        'time_minutes',
        namedArgs: {'count': '${difference.inMinutes}'},
      );
    }
    if (difference.inHours < 24) {
      return tr('time_hours', namedArgs: {'count': '${difference.inHours}'});
    }
    if (difference.inDays < 7) {
      return tr('time_days', namedArgs: {'count': '${difference.inDays}'});
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('notification_filter_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption(tr('notification_filter_all'), null),
              _buildFilterOption(
                tr('notification_type_invitation'),
                'project_invitation',
              ),
              _buildFilterOption(
                tr('notification_type_assigned'),
                'task_assigned',
              ),
              _buildFilterOption(
                tr('notification_type_due_today'),
                'task_due_today',
              ),
              _buildFilterOption(
                tr('notification_type_overdue'),
                'task_overdue',
              ),
              _buildFilterOption(
                tr('notification_type_project_overdue'),
                'project_overdue',
              ),
              _buildFilterOption(
                tr('notification_type_task_completed'),
                'task_completed',
              ),
              _buildFilterOption(
                tr('notification_type_project_completed'),
                'project_completed',
              ),
              _buildFilterOption(
                tr('notification_type_member_joined'),
                'member_joined',
              ),
              _buildFilterOption(
                tr('notification_type_premium_upgraded'),
                'premium_upgraded',
              ),
              _buildFilterOption(
                tr('notification_type_premium_expired'),
                'premium_expired',
              ),
              _buildFilterOption(
                tr('notification_type_mention'),
                'comment_mention',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('notification_filter_close')),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String label, String? type) {
    return ListTile(
      title: Text(label),
      leading: Radio<String?>(
        value: type,
        groupValue: _selectedType,
        onChanged: (value) {
          setState(() {
            _selectedType = value;
            _applyFilters();
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}
