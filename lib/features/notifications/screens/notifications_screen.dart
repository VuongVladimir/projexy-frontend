import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/notifications/services/notification_service.dart';
import 'package:frontend/features/notifications/widgets/invitation_dialog.dart';
import 'package:frontend/models/notification.dart';
import 'package:intl/intl.dart';

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
  String _currentFilter = 'all'; // 'all', 'unread', 'read'
  String? _selectedType; // null = all types

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
        switch (_tabController.index) {
          case 0:
            _currentFilter = 'all';
            break;
          case 1:
            _currentFilter = 'unread';
            break;
          case 2:
            _currentFilter = 'read';
            break;
        }
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredNotifications = _notifications.where((notification) {
        // Filter by read/unread
        bool matchesReadFilter = true;
        if (_currentFilter == 'unread') {
          matchesReadFilter = !notification.isRead;
        } else if (_currentFilter == 'read') {
          matchesReadFilter = notification.isRead;
        }

        // Filter by type
        bool matchesTypeFilter = true;
        if (_selectedType != null && _selectedType!.isNotEmpty) {
          matchesTypeFilter = notification.type == _selectedType;
        }

        return matchesReadFilter && matchesTypeFilter;
      }).toList();
    });
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
          // hasMore is not used in UI currently
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

    return Scaffold(
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'Thông báo',
        actions: [
          // Mark all as read button
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Đánh dấu tất cả đã đọc',
              onPressed: _markAllAsRead,
            ),
          // More options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'clear_read') {
                _clearReadNotifications();
              } else if (value == 'filter') {
                _showFilterDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list_rounded),
                    SizedBox(width: 8),
                    Text('Lọc theo loại'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_read',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded),
                    SizedBox(width: 8),
                    Text('Xóa thông báo đã đọc'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            decoration: BoxDecoration(color: Colors.transparent),
            child: TabBar(
              controller: _tabController,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 2.5, // mảnh nhưng vẫn nổi bật
                  color: GlobalVariables.primaryBlue,
                ),
                insets: EdgeInsets.symmetric(horizontal: 12),
              ),
              dividerColor: Colors.transparent,
              labelColor: GlobalVariables.primaryBlue,
              unselectedLabelColor: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Tất cả'),
                      if (_total > 0) ...[
                        const SizedBox(width: 8),
                        _buildBadge(_total, false),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa đọc'),
                      if (_unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        _buildBadge(_unreadCount, true),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Đã đọc'),
              ],
            ),
          ),

          // Active filter chip
          if (_selectedType != null) _buildActiveFilter(),

          // Notifications list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(
                          _filteredNotifications[index],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count, bool isUnread) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isUnread
            ? GlobalVariables.errorRed
            : GlobalVariables.backgroundBlueLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActiveFilter() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
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

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    String message = 'Không có thông báo nào';
    IconData icon = Icons.notifications_none_rounded;

    if (_currentFilter == 'unread') {
      message = 'Bạn không có thông báo chưa đọc';
      icon = Icons.mark_email_read_rounded;
    } else if (_currentFilter == 'read') {
      message = 'Bạn chưa đọc thông báo nào';
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
            Text(
              message,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: GlobalVariables.errorRed,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification);
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDarkMode
                      ? GlobalVariables.darkSurfaceCard
                      : GlobalVariables.surfaceCard)
                : (isDarkMode
                      ? GlobalVariables.primaryBlue.withOpacity(0.15)
                      : GlobalVariables.primaryBlue.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? (isDarkMode
                        ? GlobalVariables.darkBorderPrimary
                        : GlobalVariables.borderPrimary)
                  : GlobalVariables.primaryBlue.withOpacity(0.3),
              width: notification.isRead ? 1 : 2,
            ),
            boxShadow: [
              if (!notification.isRead)
                BoxShadow(
                  color: GlobalVariables.primaryBlue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    _buildNotificationIcon(notification.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: GlobalVariables.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(notification.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDarkMode
                                  ? GlobalVariables.darkTextTertiary
                                  : GlobalVariables.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  notification.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary,
                  ),
                ),

                // Additional info based on type
                if (notification.data.projectTitle != null ||
                    notification.data.taskTitle != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? GlobalVariables.darkBackgroundPrimary
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notification.data.projectTitle != null)
                          _buildInfoRow(
                            Icons.folder_rounded,
                            'Dự án: ${notification.data.projectTitle}',
                          ),
                        if (notification.data.taskTitle != null)
                          _buildInfoRow(
                            Icons.task_alt_rounded,
                            'Task: ${notification.data.taskTitle}',
                          ),
                      ],
                    ),
                  ),
                ],

                // Type badge
                const SizedBox(height: 12),
                _buildTypeBadge(notification.type),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'project_invitation':
        icon = Icons.mail_rounded;
        color = GlobalVariables.primaryBlue;
        break;
      case 'task_assigned':
        icon = Icons.assignment_ind_rounded;
        color = GlobalVariables.successGreen;
        break;
      case 'task_deadline_warning':
        icon = Icons.warning_amber_rounded;
        color = GlobalVariables.warningAmber;
        break;
      case 'project_deadline_warning':
        icon = Icons.event_busy_rounded;
        color = GlobalVariables.errorRed;
        break;
      case 'task_completed':
        icon = Icons.check_circle_rounded;
        color = GlobalVariables.successGreen;
        break;
      case 'project_completed':
        icon = Icons.celebration_rounded;
        color = GlobalVariables.successGreen;
        break;
      case 'comment_mention':
        icon = Icons.alternate_email_rounded;
        color = GlobalVariables.secondaryCoral;
        break;
      case 'comment_reply':
        icon = Icons.reply_rounded;
        color = GlobalVariables.primaryBlue;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = GlobalVariables.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDarkMode
                ? GlobalVariables.darkTextTertiary
                : GlobalVariables.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GlobalVariables.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlobalVariables.primaryBlue.withOpacity(0.3)),
      ),
      child: Text(
        _getTypeDisplayName(type),
        style: TextStyle(
          color: GlobalVariables.primaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'project_invitation':
        return 'Lời mời dự án';
      case 'task_assigned':
        return 'Task được giao';
      case 'task_deadline_warning':
        return 'Task sắp hết hạn';
      case 'project_deadline_warning':
        return 'Dự án sắp hết hạn';
      case 'task_completed':
        return 'Task hoàn thành';
      case 'project_completed':
        return 'Dự án hoàn thành';
      case 'member_joined':
        return 'Thành viên mới';
      case 'comment_mention':
        return 'Được nhắc đến';
      case 'comment_reply':
        return 'Có phản hồi';
      case 'system':
        return 'Hệ thống';
      default:
        return 'Thông báo';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read if unread
    if (!notification.isRead) {
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
            }
            _applyFilters();
          });
        },
      );
    }

    // Navigate based on notification type
    switch (notification.type) {
      case 'project_invitation':
        _handleProjectInvitationTap(notification);
        break;
      case 'task_assigned':
      case 'comment_mention':
      case 'comment_reply':
        _navigateToTask(notification);
        break;
      case 'project_deadline_warning':
        // TODO: Navigate to project detail
        break;
      // Add more cases as needed
      default:
        break;
    }
  }

  void _navigateToTask(AppNotification notification) {
    final taskId = notification.data.taskId;
    
    if (taskId == null || taskId.isEmpty) {
      showSnackBar(context, 'Không tìm thấy thông tin task!');
      return;
    }

    Navigator.pushNamed(
      context,
      '/task-detail',
      arguments: {'taskId': taskId},
    );
  }

  void _handleProjectInvitationTap(AppNotification notification) {
    final invitationId = notification.data.invitationId;
    
    if (invitationId == null || invitationId.isEmpty) {
      showSnackBar(context, 'Không tìm thấy thông tin lời mời!');
      return;
    }

    // Hiển thị dialog accept/decline invitation
    _showInvitationDialog(invitationId);
  }

  void _showInvitationDialog(String invitationId) {
    showDialog(
      context: context,
      builder: (context) => InvitationDialog(
        invitationId: invitationId,
        onActionCompleted: () {
          // Reload notifications after action
          _loadNotifications();
        },
      ),
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

  void _showFilterDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo loại thông báo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('Tất cả', null, isDarkMode),
              _buildFilterOption(
                'Lời mời dự án',
                'project_invitation',
                isDarkMode,
              ),
              _buildFilterOption('Task được giao', 'task_assigned', isDarkMode),
              _buildFilterOption(
                'Task sắp hết hạn',
                'task_deadline_warning',
                isDarkMode,
              ),
              _buildFilterOption(
                'Dự án sắp hết hạn',
                'project_deadline_warning',
                isDarkMode,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String label, String? type, bool isDarkMode) {
    final isSelected = _selectedType == type;

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
      selected: isSelected,
      selectedTileColor: GlobalVariables.primaryBlue.withOpacity(0.1),
    );
  }
}
