import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:frontend/features/chat/screens/chat_info_screen.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ProjectChatScreen extends StatefulWidget {
  static const String routeName = '/project-chat';

  final String projectId;
  final String projectTitle;

  const ProjectChatScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<ProjectChatScreen> createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends State<ProjectChatScreen> {
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

      // Watch channel
      final channel = await StreamChatService.watchProjectChannel(
        widget.projectId,
      );

      if (channel == null) {
        throw Exception('Không thể kết nối đến channel');
      }

      setState(() {
        _channel = channel;
        _isLoading = false;
      });
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: AppBar(title: Text(widget.projectTitle), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: AppBar(title: Text(widget.projectTitle), centerTitle: true),
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
    return StreamChat(
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
                    builder: (_) => ChatInfoScreen(
                      channel: _channel!,
                      projectTitle: widget.projectTitle,
                    ),
                  ),
                );
              },
            ),
          ],
          title: Text(
            widget.projectTitle,
            style: TextStyle(
              color: isDarkMode
                  ? GlobalVariables.darkTextPrimary
                  : GlobalVariables.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    );
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


  @override
  void dispose() {
    _messageInputController.dispose();
    _messageInputFocusNode.dispose();
    // Không dispose channel ở đây vì có thể cần reuse
    super.dispose();
  }
}
