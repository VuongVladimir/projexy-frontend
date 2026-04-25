import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/chat/screens/chat_room_screen.dart';
import 'package:frontend/features/chat/widgets/channel_avatar_widget.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

enum ChannelCategoryFilter { all, project, direct }

class ChannelMessagesScreen extends StatefulWidget {
  static const String routeName = '/channel-messages';
  const ChannelMessagesScreen({super.key});

  @override
  State<ChannelMessagesScreen> createState() => _ChannelMessagesScreenState();
}

class _ChannelMessagesScreenState extends State<ChannelMessagesScreen> {
  StreamChannelListController? _listController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  ChannelCategoryFilter _selectedFilter = ChannelCategoryFilter.all;
  String _searchQuery = '';
  int? _nextPageKey;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _searchController.addListener(_handleSearchChanged);
    _scrollController.addListener(_handleScroll);
  }

  void _initializeController() {
    final client = StreamChatService.client;
    final currentUserId =
        StreamChatService.currentUserId ?? client?.state.currentUser?.id;
    if (client == null || currentUserId == null) {
      return;
    }

    _listController = StreamChannelListController(
      client: client,
      filter: Filter.in_('members', [currentUserId]),
      channelStateSort: [SortOption<ChannelState>.desc('last_message_at')],
    )..doInitialLoad();
  }

  void _handleSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  void _handleScroll() {
    if (_nextPageKey == null || _listController == null) return;
    if (_isLoadingMore) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > 240) return;

    _isLoadingMore = true;
    _listController!
        .loadMore(_nextPageKey!)
        .whenComplete(() => _isLoadingMore = false);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _listController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final client = StreamChatService.client;

    if (client == null || _listController == null) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: CustomAppBar(title: tr('messages')),
        body: _buildEmptyState(
          context,
          icon: Icons.cloud_off_rounded,
          title: 'Không thể kết nối chat',
          subtitle: 'Vui lòng đăng nhập lại hoặc kiểm tra kết nối mạng.',
          action: ElevatedButton(
            onPressed: () {
              setState(() {
                _initializeController();
              });
            },
            child: const Text('Thử lại'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      appBar: CustomAppBar(title: tr('messages')),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildSearchBar(context, isDarkMode),
            _buildFilterRow(context, isDarkMode),
            Expanded(
              child: PagedValueListenableBuilder<int, Channel>(
                valueListenable: _listController!,
                builder: (context, pagedValue, child) {
                  return pagedValue.when(
                    (channels, nextPageKey, error) {
                      _nextPageKey = nextPageKey;
                      final visibleChannels = _applySearchAndFilter(channels);

                      if (visibleChannels.isEmpty) {
                        return _buildEmptyState(
                          context,
                          icon: Icons.forum_outlined,
                          title: 'Chưa có cuộc trò chuyện',
                          subtitle:
                              'Bạn sẽ thấy các cuộc trò chuyện dự án, nhóm hoặc trực tiếp ở đây.',
                          action: TextButton(
                            onPressed: _listController!.refresh,
                            child: const Text('Làm mới danh sách'),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: GlobalVariables.primaryBlue,
                        onRefresh: () async {
                          await _listController!.refresh();
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(6, 6, 0, 18),
                          itemCount:
                              visibleChannels.length +
                              (nextPageKey != null ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index >= visibleChannels.length) {
                              return _buildLoadingMore(isDarkMode, error);
                            }

                            final channel = visibleChannels[index];
                            return _ChannelPreviewTile(
                              channel: channel,
                              isDarkMode: isDarkMode,
                              onTap: () => _openChannel(context, channel),
                              onLongPress: () =>
                                  _showChannelActions(context, channel),
                            );
                          },
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e) => _buildEmptyState(
                      context,
                      icon: Icons.error_outline_rounded,
                      title: 'Không tải được danh sách chat',
                      subtitle: e.toString(),
                      action: ElevatedButton(
                        onPressed: _listController!.refresh,
                        child: const Text('Thử lại'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm cuộc trò chuyện',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDarkMode
                  ? GlobalVariables.darkBorderPrimary
                  : GlobalVariables.borderPrimary,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDarkMode
                  ? GlobalVariables.darkBorderPrimary
                  : GlobalVariables.borderPrimary,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: GlobalVariables.primaryBlue,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, bool isDarkMode) {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: ChannelCategoryFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          final selectedColor = isDarkMode
              ? GlobalVariables.darkPrimaryBlue
              : const Color(0xFF6E7CFB);
          final unselectedColor = isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : const Color(0xFFE8E5FA);
          final unselectedTextColor = isDarkMode
              ? GlobalVariables.darkTextSecondary
              : const Color(0xFF6F7192);

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Theme(
              data: Theme.of(context).copyWith(
                chipTheme: Theme.of(context).chipTheme.copyWith(
                  showCheckmark: false,
                  shape: const StadiumBorder(),
                ),
              ),
              child: ChoiceChip(
                label: Text(_filterLabel(filter)),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                selectedColor: selectedColor,
                backgroundColor: unselectedColor,
                surfaceTintColor: Colors.transparent,
                pressElevation: 0,
                elevation: 2,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : unselectedTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.1,
                ),
                shape: const StadiumBorder(),
                shadowColor: selectedColor.withValues(alpha: 0.24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingMore(bool isDarkMode, Object? error) {
    if (error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode
                ? GlobalVariables.darkBorderPrimary
                : GlobalVariables.borderPrimary,
          ),
        ),
        child: TextButton(
          onPressed: _listController?.retry,
          child: Text(
            'Không tải thêm được. Nhấn để thử lại.',
            style: TextStyle(color: GlobalVariables.primaryBlue),
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: GlobalVariables.primaryBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: GlobalVariables.primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }

  List<Channel> _applySearchAndFilter(List<Channel> channels) {
    final filtered = channels.where((channel) {
      final category = _resolveChannelCategory(channel);
      if (_selectedFilter == ChannelCategoryFilter.project &&
          category != 'project') {
        return false;
      }

      if (_selectedFilter == ChannelCategoryFilter.direct &&
          category != 'direct') {
        return false;
      }

      if (_searchQuery.isEmpty) return true;
      final title = _resolveChannelTitle(channel).toLowerCase();
      return title.contains(_searchQuery);
    }).toList();

    return filtered;
  }

  String _resolveChannelCategory(Channel channel) {
    return channel.resolvedCategory;
  }

  String _resolveChannelTitle(Channel channel) {
    final displayName = channel.getDisplayName();
    if (displayName.trim().isNotEmpty) return displayName;

    return 'Chat';
  }

  String _filterLabel(ChannelCategoryFilter filter) {
    switch (filter) {
      case ChannelCategoryFilter.all:
        return 'Tất cả';
      case ChannelCategoryFilter.project:
        return 'Dự án';
      case ChannelCategoryFilter.direct:
        return 'Trực tiếp';
    }
  }

  Future<void> _openChannel(BuildContext context, Channel channel) async {
    if (channel.isProjectChannel) {
      try {
        await StreamChatService.ensureProjectChannelAccess(channel.id!);
      } on ProjectChatPremiumRequiredException catch (e) {
        if (!context.mounted) return;
        showSnackBar(context, e.message);
        return;
      } catch (e) {
        if (!context.mounted) return;
        showSnackBar(context, 'Không thể truy cập phòng chat dự án');
        return;
      }
    }

    if (!context.mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatRoomScreen(channel: channel)));
  }

  void _showChannelActions(BuildContext context, Channel channel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDirectChannel = channel.isDirectChannel;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode
          ? GlobalVariables.darkSurfaceCard
          : GlobalVariables.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? GlobalVariables.darkTextTertiary
                      : GlobalVariables.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Ẩn cuộc trò chuyện
              ListTile(
                leading: Icon(
                  Icons.visibility_off_outlined,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
                title: Text(
                  'Ẩn cuộc trò chuyện',
                  style: TextStyle(
                    color: isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : GlobalVariables.textPrimary,
                  ),
                ),
                subtitle: Text(
                  isDirectChannel
                      ? 'Bạn có thể mở lại từ trang cá nhân của người này'
                      : 'Bạn có thể mở lại từ trang chi tiết dự án',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmHideChannel(channel);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmHideChannel(Channel channel) async {
    final isDirectChannel = channel.isDirectChannel;
    final shouldHide = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ẩn cuộc trò chuyện?'),
          content: Text(
            isDirectChannel
                ? 'Cuộc trò chuyện sẽ được ẩn khỏi danh sách. Bạn có thể mở lại bằng cách nhấn vào biểu tượng chat trong trang cá nhân của người này.'
                : 'Cuộc trò chuyện sẽ được ẩn khỏi danh sách. Bạn có thể mở lại bằng cách nhấn vào biểu tượng chat trong trang chi tiết dự án.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Ẩn',
                style: TextStyle(color: GlobalVariables.primaryBlue),
              ),
            ),
          ],
        );
      },
    );

    if (shouldHide != true) return;

    final success = await StreamChatService.hideChannel(channel);
    if (!mounted) return;

    if (success) {
      showSnackBar(context, 'Đã ẩn cuộc trò chuyện');
      _listController?.refresh();
    } else {
      showSnackBar(context, 'Không thể ẩn cuộc trò chuyện');
    }
  }
}

class _ChannelPreviewTile extends StatelessWidget {
  final Channel channel;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ChannelPreviewTile({
    required this.channel,
    required this.isDarkMode,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final category = channel.resolvedCategory;
    final isDirect = category == 'direct';

    // Sử dụng StreamBuilder cho cả members và lastMessage
    return StreamBuilder<List<Member>>(
      stream: channel.state?.membersStream,
      initialData: channel.state?.members ?? const <Member>[],
      builder: (context, membersSnapshot) {
        final members = membersSnapshot.data ?? const <Member>[];
        final title = _resolveTitleFromMembers(members, isDirect);

        return StreamBuilder<Message?>(
          stream: channel.state?.lastMessageStream,
          initialData: channel.state?.lastMessage,
          builder: (context, messageSnapshot) {
            final message = messageSnapshot.data;
            final subtitle = _buildSubtitle(message);
            final lastMessageAt = message?.createdAt ?? channel.lastMessageAt;

            return Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? GlobalVariables.darkSurfaceCard
                    : GlobalVariables.surfaceCard,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Row(
                      children: [
                        ChannelAvatarWidget(channel: channel, radius: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isDarkMode
                                                ? GlobalVariables
                                                      .darkTextPrimary
                                                : GlobalVariables.textPrimary,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(lastMessageAt),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: isDarkMode
                                              ? GlobalVariables.darkTextTertiary
                                              : GlobalVariables.textTertiary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: isDarkMode
                                                ? GlobalVariables
                                                      .darkTextSecondary
                                                : GlobalVariables.textSecondary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        StreamBuilder<int>(
                          stream: channel.state?.unreadCountStream,
                          initialData: channel.state?.unreadCount ?? 0,
                          builder: (context, snapshot) {
                            final unread = snapshot.data ?? 0;
                            if (unread <= 0) {
                              return Icon(
                                Icons.chevron_right_rounded,
                                color: isDarkMode
                                    ? GlobalVariables.darkTextTertiary
                                    : GlobalVariables.textTertiary,
                              );
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: GlobalVariables.primaryBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unread > 99 ? '99+' : unread.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Resolve title từ danh sách members (cho direct channel)
  String _resolveTitleFromMembers(List<Member> members, bool isDirect) {
    if (isDirect) {
      return channel.getDirectDisplayName(members: members);
    }

    final displayName = channel.getDisplayName();
    if (displayName.trim().isNotEmpty) return displayName;
    return 'Chat';
  }

  String _buildSubtitle(Message? message) {
    if (message == null) {
      return 'Chưa có tin nhắn nào';
    }

    final sender = message.user?.name ?? message.user?.id ?? 'Ai đó';
    final text = (message.text ?? '').trim();
    if (text.isNotEmpty) {
      return '$sender: $text';
    }

    if (message.attachments.isNotEmpty) {
      return '$sender: Đã gửi tệp đính kèm';
    }

    return '$sender: Đã gửi một tin nhắn';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final isToday =
        time.year == now.year && time.month == now.month && time.day == now.day;
    return isToday
        ? DateFormat('HH:mm').format(time)
        : DateFormat('dd/MM').format(time);
  }
}
