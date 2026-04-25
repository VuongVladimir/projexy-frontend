import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:frontend/features/chat/screens/chat_info_screen.dart';
import 'package:frontend/features/chat/widgets/channel_avatar_widget.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChatRoomScreen extends StatefulWidget {
  static const String routeName = '/chat-room';

  final String? projectId;
  final String? projectTitle;
  final Channel? channel;

  const ChatRoomScreen({
    super.key,
    this.projectId,
    this.projectTitle,
    this.channel,
  }) : assert(
         channel != null || (projectId != null && projectTitle != null),
         'Either channel or projectId/projectTitle must be provided.',
       );

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  Channel? _channel;
  bool _isLoading = true;
  String? _error;
  late final StreamMessageInputController _messageInputController;
  late final FocusNode _messageInputFocusNode;

  @override
  void initState() {
    super.initState();
    _messageInputController = StreamMessageInputController();
    _messageInputFocusNode = FocusNode();
    _initializeChannel();
  }

  Future<void> _initializeChannel() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Đảm bảo Stream Chat đã được khởi tạo
      if (StreamChatService.client == null) {
        throw Exception('Stream Chat chưa được khởi tạo');
      }

      Channel? channel;
      if (widget.channel != null) {
        channel = widget.channel!;
        if (channel.isProjectChannel) {
          await StreamChatService.ensureProjectChannelAccess(channel.id!);
        }
        if (channel.isDirectChannel) {
          final recoveredChannel =
              await StreamChatService.recoverAndWatchDirectChannel(channel);
          if (recoveredChannel != null) {
            channel = recoveredChannel;
          } else {
            await channel.watch();
          }
        } else {
          await channel.watch();
        }

        // Đảm bảo channel được hiện nếu đang bị ẩn
        try {
          await channel.show();
        } catch (_) {
          // Ignore error nếu channel đã được hiện
        }
      } else if (widget.projectId != null) {
        // Watch channel theo project
        channel = await StreamChatService.watchProjectChannel(
          widget.projectId!,
          projectTitle: widget.projectTitle,
        );
      }

      if (channel == null) {
        throw Exception('Không thể kết nối đến channel');
      }

      setState(() {
        _channel = channel;
        _isLoading = false;
      });
    } on ProjectChatPremiumRequiredException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
      debugPrint('Project chat blocked by premium gate: ${e.message}');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error initializing channel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appLocale = Localizations.localeOf(context);
    final chatSafeLocale = appLocale.languageCode == 'vi'
        ? const Locale('en')
        : appLocale;

    // Lấy displayTitle dựa trên loại channel
    final displayTitle = _resolveChannelTitle(
      _channel,
      fallbackTitle: widget.projectTitle,
    );

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: AppBar(title: Text(displayTitle), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: AppBar(title: Text(displayTitle), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: GlobalVariables.errorRed,
                ),
                const SizedBox(height: 16),
                Text(
                  tr('error_loading_chat'),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _initializeChannel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalVariables.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(tr('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Bọc màn chat bằng StreamChat với custom theme để customize avatar
    return Localizations.override(
      context: context,
      locale: chatSafeLocale,
      child: StreamChat(
        client: StreamChatService.client!,
        streamChatThemeData: _buildCustomTheme(context, isDarkMode),
        child: Scaffold(
          backgroundColor: isDarkMode
              ? GlobalVariables.darkBackgroundPrimary
              : GlobalVariables.backgroundPrimary,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                tooltip: tr('info'),
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
                onPressed: () {
                  if (_channel == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatInfoScreen(channel: _channel!),
                    ),
                  );
                },
              ),
            ],
            title: _buildAppBarTitle(isDarkMode),
            centerTitle: true,
            backgroundColor: isDarkMode
                ? GlobalVariables.darkSurfaceCard
                : GlobalVariables.surfaceCard,
            elevation: 0,
          ),
          body: StreamChannel(
            channel: _channel!,
            child: Column(
              children: [
                Expanded(
                  child: StreamMessageListView(
                    // Custom message để thêm avatar builder và reaction picker
                    // NHƯNG vẫn giữ nguyên default message với tất cả các actions
                    messageBuilder:
                        (context, details, messageList, defaultMessage) {
                          return _buildMessageWithCustomizations(
                            context,
                            details,
                            defaultMessage,
                          );
                        },
                  ),
                ),
                // Typing indicators hiển thị đang nhập
                const StreamTypingIndicator(),
                // Bọc input với SafeArea để tránh overflow khi mở bàn phím / bottom sheets
                SafeArea(
                  top: false,
                  child: StreamMessageInput(
                    focusNode: _messageInputFocusNode,
                    messageInputController: _messageInputController,
                    onQuotedMessageCleared:
                        _messageInputController.clearQuotedMessage,
                    attachmentLimit: 5,
                    preMessageSending: (message) async {
                      return message;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build AppBar title với StreamBuilder cho direct channel
  Widget _buildAppBarTitle(bool isDarkMode) {
    final channel = _channel;
    if (channel == null) {
      return Text(
        widget.projectTitle ?? 'Chat',
        style: TextStyle(
          color: isDarkMode
              ? GlobalVariables.darkTextPrimary
              : GlobalVariables.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final isDirect = _isDirectChannel(channel);

    // Nếu không phải direct channel, hiển thị title tĩnh
    if (!isDirect) {
      final displayTitle = _resolveChannelTitle(
        channel,
        fallbackTitle: widget.projectTitle,
      );
      return Text(
        displayTitle,
        style: TextStyle(
          color: isDarkMode
              ? GlobalVariables.darkTextPrimary
              : GlobalVariables.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // Cho direct channel, sử dụng StreamBuilder để theo dõi members
    return StreamBuilder<List<Member>>(
      stream: channel.state?.membersStream,
      initialData: channel.state?.members ?? const <Member>[],
      builder: (context, snapshot) {
        final members = snapshot.data ?? const <Member>[];
        final title = _resolveDirectChannelTitleFromMembers(members);
        return Text(
          title,
          style: TextStyle(
            color: isDarkMode
                ? GlobalVariables.darkTextPrimary
                : GlobalVariables.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }

  /// Resolve title cho direct channel từ danh sách members
  String _resolveDirectChannelTitleFromMembers(List<Member> members) {
    return _channel?.getDirectDisplayName(members: members) ?? 'Chat';
  }

  /// Build custom theme với avatar builder và reaction builder
  StreamChatThemeData _buildCustomTheme(BuildContext context, bool isDarkMode) {
    final defaultTheme = isDarkMode
        ? StreamChatThemeData.dark()
        : StreamChatThemeData.light();

    return defaultTheme;
  }

  Widget _buildMessageWithCustomizations(
    BuildContext context,
    MessageDetails details,
    Widget defaultMessage,
  ) {
    if (defaultMessage is! StreamMessageWidget) {
      return defaultMessage;
    }

    return defaultMessage.copyWith(
      userAvatarBuilder: (context, user) => _buildCustomAvatar(user),
      showUserAvatar: details.isMyMessage
          ? DisplayWidget.hide
          : DisplayWidget.show,
      onReplyTap: _handleReply,
    );
  }

  /// Build custom avatar thống nhất với style ở project_detail_screen
  Widget _buildCustomAvatar(User user) {
    final name = user.name;
    final image = user.image;
    final userColorHex = (user.extraData['color'] as String?) ?? '#3443FD';

    return CircleAvatar(
      radius: 16,
      backgroundColor: userColorHex.toColor(),
      backgroundImage: (image != null && image.isNotEmpty)
          ? NetworkImage(image)
          : null,
      child: (image == null || image.isEmpty)
          ? Text(
              (name.isNotEmpty) ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
          : null,
    );
  }

  void _handleReply(Message message) {
    _messageInputController.quotedMessage = message;
    if (!_messageInputFocusNode.hasFocus) {
      _messageInputFocusNode.requestFocus();
    }
  }

  String _resolveChannelTitle(Channel? channel, {String? fallbackTitle}) {
    if (fallbackTitle != null && fallbackTitle.isNotEmpty) {
      return fallbackTitle;
    }

    if (channel == null) return 'Chat';

    final isDirect = _isDirectChannel(channel);
    if (isDirect) {
      return channel.getDisplayName();
    }

    final displayName = channel.getDisplayName();
    if (displayName.trim().isNotEmpty) return displayName;

    return 'Chat';
  }

  bool _isDirectChannel(Channel channel) {
    return channel.isDirectChannel;
  }

  @override
  void dispose() {
    _messageInputController.dispose();
    _messageInputFocusNode.dispose();
    // Không dispose channel ở đây vì có thể cần reuse
    super.dispose();
  }
}
