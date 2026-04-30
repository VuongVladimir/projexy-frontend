import 'dart:async';
import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:frontend/features/chat/widgets/channel_avatar_widget.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChatInfoScreen extends StatefulWidget {
  final Channel channel;

  const ChatInfoScreen({super.key, required this.channel});

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  bool _isUploadingAvatar = false;
  bool _isProcessingImage = false;
  dynamic _selectedAvatar;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDirect = widget.channel.isDirectChannel;
    final channelName = widget.channel.getDisplayName();
    final category = widget.channel.resolvedCategory;

    return StreamChannel(
      channel: widget.channel,
      child: Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Symbols.arrow_back,
              color: isDarkMode
                  ? GlobalVariables.darkTextPrimary
                  : GlobalVariables.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const SizedBox.shrink(),
          backgroundColor: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(21, 0, 21, 32),
          children: [
            if (isDirect)
              StreamBuilder<List<Member>>(
                stream: widget.channel.state?.membersStream,
                initialData: widget.channel.state?.members ?? const <Member>[],
                builder: (context, snapshot) {
                  final members = snapshot.data ?? const <Member>[];
                  return _buildHeaderSection(
                    context,
                    isDarkMode: isDarkMode,
                    channelName: widget.channel.getDisplayName(
                      members: members,
                    ),
                    category: category,
                    isDirect: isDirect,
                  );
                },
              )
            else
              _buildHeaderSection(
                context,
                isDarkMode: isDarkMode,
                channelName: channelName,
                category: category,
                isDirect: isDirect,
              ),
            const SizedBox(height: 18),
            if (!isDirect) ...[
              _buildSectionHeader(context, tr('chat_info')),
              const SizedBox(height: 12),
              _buildActionRow(
                context: context,
                icon: Symbols.group,
                fill: 1,
                title: tr('see_chat_members'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _ChatMembersScreen(channel: widget.channel),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            _buildSectionHeader(context, tr('more_actions')),
            const SizedBox(height: 12),
            _buildActionRow(
              context: context,
              icon: Symbols.image,
              weight: 900,
              title: tr('view_media_files_links'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ChannelMediaScreen(channel: widget.channel),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionRow(
              context: context,
              icon: Symbols.push_pin,
              fill: 1,
              title: tr('pinned_messages'),
              onTap: () async {
                final messageId = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) =>
                        _PinnedMessagesScreen(channel: widget.channel),
                  ),
                );
                if (!mounted || messageId == null || messageId.isEmpty) return;
                Navigator.of(this.context).pop(messageId);
              },
            ),
            const SizedBox(height: 16),
            _buildActionRow(
              context: context,
              icon: Symbols.search,
              fill: 1,
              title: tr('search_in_conversation'),
              onTap: () async {
                final messageId = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) =>
                        _SearchInConversationScreen(channel: widget.channel),
                  ),
                );
                if (!mounted || messageId == null || messageId.isEmpty) return;
                Navigator.of(this.context).pop(messageId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context, {
    required bool isDarkMode,
    required String channelName,
    required String category,
    required bool isDirect,
  }) {
    final canEditAvatar = !isDirect;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: _selectedAvatar != null
                    ? CircleAvatar(
                        radius: 64,
                        backgroundColor: widget.channel.avatarColor,
                        backgroundImage: _getAvatarImage(),
                      )
                    : ChannelAvatarWidget(channel: widget.channel, radius: 64),
              ),
              if (_isUploadingAvatar || _isProcessingImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: GlobalVariables.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              if (canEditAvatar)
                Positioned(
                  bottom: 0,
                  right: 6,
                  child: GestureDetector(
                    onTap: (_isUploadingAvatar || _isProcessingImage)
                        ? null
                        : _selectAndUploadAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: GlobalVariables.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: GlobalVariables.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            channelName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? GlobalVariables.darkTextPrimary
                  : GlobalVariables.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (!isDirect) _buildCategoryBadge(context, category),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context, String category) {
    final label = category == 'project' ? tr('project') : tr('direct_chat');
    final bgColor = category == 'project'
        ? GlobalVariables.primaryBlue.withValues(alpha: 0.12)
        : GlobalVariables.accentViolet.withValues(alpha: 0.12);
    final textColor = category == 'project'
        ? GlobalVariables.primaryBlue
        : GlobalVariables.accentViolet;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Future<void> _selectAndUploadAvatar() async {
    try {
      setState(() => _isProcessingImage = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessingImage = false);
        return;
      }

      setState(() {
        if (kIsWeb) {
          _selectedAvatar = result.files.first.bytes;
        } else {
          _selectedAvatar = File(result.files.single.path!);
        }
        _isProcessingImage = false;
        _isUploadingAvatar = true;
      });

      final cloudinary = CloudinaryPublic('dkwp4prjj', 'projexy_preset');
      late final CloudinaryResponse response;

      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes == null) throw Exception('Cannot read file bytes');

        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            bytes,
            identifier:
                'channel_avatar_${widget.channel.id}_${DateTime.now().millisecondsSinceEpoch}',
            folder: 'channel_avatars',
          ),
        );
      } else {
        final path = result.files.single.path;
        if (path == null) throw Exception('Cannot get file path');

        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(path, folder: 'channel_avatars'),
        );
      }

      final avatarUrl = response.secureUrl;
      final previousImage = widget.channel.image;
      final previousAvatarColor =
          widget.channel.extraData['avatarColor'] as String?;

      await StreamChatService.updateChannelAvatarDirect(
        channel: widget.channel,
        avatarUrl: avatarUrl,
      );

      final success = await StreamChatService.updateChannelAvatar(
        channelId: widget.channel.id!,
        channelType: widget.channel.type,
        avatarUrl: avatarUrl,
      );

      if (success) {
        setState(() => _selectedAvatar = null);
        if (mounted) showSnackBar(context, tr('channel_avatar_updated'));
      } else {
        await StreamChatService.updateChannelAvatarDirect(
          channel: widget.channel,
          avatarUrl: (previousImage != null && previousImage.isNotEmpty)
              ? previousImage
              : null,
          avatarColor: previousAvatarColor,
          clearImage: previousImage == null || previousImage.isEmpty,
        );
        setState(() => _selectedAvatar = null);
        if (mounted) {
          showSnackBar(context, tr('error_updating_channel_avatar'));
        }
      }
    } catch (e) {
      debugPrint('Error uploading channel avatar: $e');
      setState(() => _selectedAvatar = null);
      if (mounted) showSnackBar(context, tr('error_uploading_image'));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
          _isProcessingImage = false;
        });
      }
    }
  }

  ImageProvider? _getAvatarImage() {
    if (_selectedAvatar != null) {
      if (kIsWeb) {
        return MemoryImage(_selectedAvatar as Uint8List);
      }
      return FileImage(_selectedAvatar as File);
    }
    return null;
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: isDarkMode
            ? GlobalVariables.darkTextSecondary
            : GlobalVariables.textSecondary,
      ),
    );
  }

  Widget _buildActionRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    double fill = 0,
    double weight = 600,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode
        ? GlobalVariables.darkTextPrimary
        : GlobalVariables.textPrimary;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 28, fill: fill, weight: weight, grade: 210),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: row,
      ),
    );
  }
}

class _ChatMembersScreen extends StatelessWidget {
  final Channel channel;

  const _ChatMembersScreen({required this.channel});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamChannel(
      channel: channel,
      child: Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: AppBar(
          title: Text(tr('members')),
          centerTitle: true,
          backgroundColor: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          elevation: 0,
        ),
        body: StreamBuilder<List<Member>>(
          stream: channel.state?.membersStream,
          initialData: channel.state?.members ?? const <Member>[],
          builder: (context, snapshot) {
            final members = snapshot.data ?? const <Member>[];
            if (members.isEmpty) {
              return Center(
                child: Text(
                  tr('no_members'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: members.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = members[index];
                final user = member.user;
                final name = ((user?.name ?? user?.id) ?? '').trim();
                final image = user?.image;
                final colorHex =
                    (user?.extraData['color'] as String?) ?? '#4B58F0';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: colorHex.toColor(),
                    backgroundImage: image != null && image.isNotEmpty
                        ? NetworkImage(image)
                        : null,
                    child: (image == null || image.isEmpty)
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    tr('member'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDarkMode
                          ? GlobalVariables.darkTextSecondary
                          : GlobalVariables.textSecondary,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PinnedMessagesScreen extends StatelessWidget {
  final Channel channel;

  const _PinnedMessagesScreen({required this.channel});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamChannel(
      channel: channel,
      child: Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: AppBar(
          title: Text(tr('pinned_messages')),
          centerTitle: true,
          backgroundColor: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          elevation: 0,
        ),
        body: StreamBuilder<List<Message>>(
          stream: channel.state?.pinnedMessagesStream,
          initialData: channel.state?.pinnedMessages ?? const <Message>[],
          builder: (context, snapshot) {
            final pinnedMessages = [...(snapshot.data ?? const <Message>[])];
            pinnedMessages.sort(
              (a, b) => (b.pinnedAt ?? b.createdAt).compareTo(
                a.pinnedAt ?? a.createdAt,
              ),
            );

            if (pinnedMessages.isEmpty) {
              return Center(
                child: Text(
                  tr('no_pinned_messages'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: pinnedMessages.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final message = pinnedMessages[index];
                final userName =
                    message.user?.name ?? message.user?.id ?? tr('member');
                final previewText = _messagePreview(message, context);
                final pinnedAt = message.pinnedAt ?? message.createdAt;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  leading: const Icon(Symbols.push_pin),
                  title: Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        previewText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(pinnedAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDarkMode
                                    ? GlobalVariables.darkTextSecondary
                                    : GlobalVariables.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Symbols.chevron_right),
                  onTap: () => Navigator.of(context).pop(message.id),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _messagePreview(Message message, BuildContext context) {
    final text = (message.text ?? '').trim();
    if (text.isNotEmpty) return text;

    if (message.attachments.isNotEmpty) {
      final first = message.attachments.first;
      if (first.isImage) return tr('image');
      if (first.isFile || first.isVideo || first.isAudio) {
        return first.title ?? first.file?.name ?? tr('file');
      }
      if (first.isUrlPreview) {
        return first.title ??
            first.titleLink ??
            first.ogScrapeUrl ??
            tr('links');
      }
    }

    return tr('message_with_attachments');
  }
}

class _ChannelMediaScreen extends StatefulWidget {
  final Channel channel;

  const _ChannelMediaScreen({required this.channel});

  @override
  State<_ChannelMediaScreen> createState() => _ChannelMediaScreenState();
}

class _ChannelMediaScreenState extends State<_ChannelMediaScreen> {
  static final RegExp _urlRegex = RegExp(
    r'((https?:\/\/)|(www\.))[^\s]+',
    caseSensitive: false,
  );

  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamChannel(
      channel: widget.channel,
      child: Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: AppBar(
          title: Text(tr('media_and_files')),
          centerTitle: true,
          backgroundColor: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          elevation: 0,
        ),
        body: StreamBuilder<List<Message>>(
          stream: widget.channel.state?.messagesStream,
          initialData: widget.channel.state?.messages ?? const <Message>[],
          builder: (context, snapshot) {
            final messages = snapshot.data ?? const <Message>[];
            final imageItems = <_AttachmentWithMessage>[];
            final fileItems = <_AttachmentWithMessage>[];
            final linkItems = <_LinkItem>[];
            final seenLinks = <String>{};

            for (final message in messages) {
              for (final attachment in message.attachments) {
                if (attachment.isImage) {
                  imageItems.add(
                    _AttachmentWithMessage(
                      message: message,
                      attachment: attachment,
                    ),
                  );
                } else if (attachment.isFile ||
                    attachment.isVideo ||
                    attachment.isAudio) {
                  fileItems.add(
                    _AttachmentWithMessage(
                      message: message,
                      attachment: attachment,
                    ),
                  );
                }

                if (attachment.isUrlPreview) {
                  final url = _normalizeUrl(
                    attachment.titleLink ??
                        attachment.ogScrapeUrl ??
                        attachment.assetUrl,
                  );
                  if (url != null && seenLinks.add(url)) {
                    linkItems.add(
                      _LinkItem(
                        url: url,
                        title: attachment.title ?? url,
                        subtitle: attachment.text,
                      ),
                    );
                  }
                }
              }

              final text = message.text ?? '';
              for (final match in _urlRegex.allMatches(text)) {
                final raw = text.substring(match.start, match.end);
                final url = _normalizeUrl(raw);
                if (url != null && seenLinks.add(url)) {
                  linkItems.add(_LinkItem(url: url, title: url));
                }
              }
            }

            if (imageItems.isEmpty && fileItems.isEmpty && linkItems.isEmpty) {
              return Center(
                child: Text(
                  tr('no_shared_media'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (imageItems.isNotEmpty) ...[
                  Text(
                    tr('images'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                    itemCount: imageItems.length,
                    itemBuilder: (context, index) {
                      final imageAttachment = imageItems[index].attachment;
                      final url =
                          imageAttachment.imageUrl ??
                          imageAttachment.assetUrl ??
                          imageAttachment.thumbUrl ??
                          '';

                      if (url.isEmpty) {
                        return Container(
                          color: GlobalVariables.borderPrimary,
                          child: const Icon(Symbols.broken_image),
                        );
                      }

                      return GestureDetector(
                        onTap: () => _openImagePreview(
                          imageUrl: url,
                          title:
                              imageAttachment.title ??
                              imageAttachment.file?.name,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: GlobalVariables.borderPrimary,
                              child: const Icon(Symbols.broken_image),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                if (fileItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    tr('files'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...fileItems.map((fileItem) {
                    final attachment = fileItem.attachment;
                    final title =
                        attachment.title ?? attachment.file?.name ?? tr('file');
                    final size = attachment.file?.size;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
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
                      child: ListTile(
                        leading: const Icon(Symbols.insert_drive_file),
                        title: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: size != null
                            ? Text(
                                '${(size / (1024 * 1024)).toStringAsFixed(2)} MB',
                              )
                            : null,
                        trailing: _isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Symbols.download),
                        onTap: _isDownloading
                            ? null
                            : () => _downloadFileAttachment(attachment),
                      ),
                    );
                  }),
                ],
                if (linkItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    tr('links'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...linkItems.map((linkItem) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
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
                      child: ListTile(
                        leading: const Icon(Symbols.link),
                        title: Text(
                          linkItem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          linkItem.subtitle ?? linkItem.url,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Symbols.open_in_new),
                        onTap: () => _openExternalLink(linkItem.url),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String? _normalizeUrl(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('www.')) return 'https://$value';
    return null;
  }

  Future<void> _openExternalLink(String rawUrl) async {
    final url = _normalizeUrl(rawUrl);
    if (url == null) {
      if (mounted) showSnackBar(context, tr('cannot_open_file'));
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) showSnackBar(context, tr('cannot_open_file'));
      return;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) showSnackBar(context, tr('cannot_open_file'));
    }
  }

  void _openImagePreview({required String imageUrl, String? title}) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        title ?? tr('image'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadFileAttachment(Attachment attachment) async {
    final rawUrl =
        attachment.assetUrl ??
        attachment.titleLink ??
        attachment.ogScrapeUrl ??
        attachment.file?.path;
    final url = _normalizeUrl(rawUrl);

    if (url == null) {
      if (mounted) showSnackBar(context, tr('cannot_open_file'));
      return;
    }

    if (kIsWeb) {
      await _openExternalLink(url);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) showSnackBar(context, tr('cannot_open_file'));
      return;
    }

    try {
      setState(() => _isDownloading = true);

      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            if (mounted) {
              showSnackBar(context, tr('storage_permission_required'));
            }
            return;
          }
        }
      }

      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      } else {
        downloadDir = await getDownloadsDirectory();
      }

      if (downloadDir == null) {
        if (mounted) showSnackBar(context, tr('cannot_access_storage'));
        return;
      }

      final fileName = _extractFileName(attachment, uri);
      final filePath = '${downloadDir.path}/$fileName';
      await Dio().download(url, filePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('file_downloaded', namedArgs: {'fileName': fileName}),
          ),
          action: SnackBarAction(
            label: tr('open'),
            onPressed: () async {
              await OpenFile.open(filePath);
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error downloading chat attachment: $e');
      if (mounted) showSnackBar(context, tr('error_downloading_file'));
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  String _extractFileName(Attachment attachment, Uri uri) {
    final title = (attachment.title ?? '').trim();
    if (title.isNotEmpty) return title;

    final fileName = (attachment.file?.name ?? '').trim();
    if (fileName.isNotEmpty) return fileName;

    final lastSegment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    if (lastSegment.trim().isNotEmpty) return lastSegment;

    return 'file_${DateTime.now().millisecondsSinceEpoch}';
  }
}

class _SearchInConversationScreen extends StatefulWidget {
  final Channel channel;

  const _SearchInConversationScreen({required this.channel});

  @override
  State<_SearchInConversationScreen> createState() =>
      _SearchInConversationScreenState();
}

class _SearchInConversationScreenState
    extends State<_SearchInConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  String _query = '';
  String? _error;
  List<Message> _results = const <Message>[];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller
      ..removeListener(_onQueryChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamChannel(
      channel: widget.channel,
      child: Scaffold(
        backgroundColor: isDarkMode
            ? GlobalVariables.darkBackgroundPrimary
            : GlobalVariables.backgroundPrimary,
        appBar: AppBar(
          title: Text(tr('search_in_conversation')),
          centerTitle: true,
          backgroundColor: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: tr('search_messages_hint'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _query = '';
                              _results = const <Message>[];
                              _error = null;
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: isDarkMode
                      ? GlobalVariables.darkSurfaceCard
                      : GlobalVariables.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? GlobalVariables.darkBorderPrimary
                          : GlobalVariables.borderPrimary,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? GlobalVariables.darkBorderPrimary
                          : GlobalVariables.borderPrimary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: GlobalVariables.primaryBlue),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(isDarkMode)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
        ),
      );
    }

    if (_query.isEmpty) {
      return Center(
        child: Text(
          tr('start_typing_to_search'),
          style: TextStyle(
            color: isDarkMode
                ? GlobalVariables.darkTextSecondary
                : GlobalVariables.textSecondary,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          tr('no_search_results'),
          style: TextStyle(
            color: isDarkMode
                ? GlobalVariables.darkTextSecondary
                : GlobalVariables.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final message = _results[index];
        final sender = message.user?.name ?? message.user?.id ?? tr('member');
        final content = _messagePreview(message, context);

        return ListTile(
          leading: const Icon(Symbols.chat),
          title: Text(sender, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Symbols.chevron_right),
          onTap: () => Navigator.of(context).pop(message.id),
        );
      },
    );
  }

  void _onQueryChanged() {
    final nextQuery = _controller.text.trim();
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (nextQuery == _query) return;
      _searchMessages(nextQuery);
    });
  }

  Future<void> _searchMessages(String query) async {
    setState(() {
      _query = query;
      _error = null;
      if (query.isEmpty) {
        _results = const <Message>[];
      }
    });

    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      List<Message> results;

      if (widget.channel.canSearchMessages) {
        final response = await widget.channel.search(
          query: query,
          sort: [SortOption<Message>.desc('created_at')],
          paginationParams: const PaginationParams(limit: 50),
        );

        results = response.results.map((item) => item.message).toList();
      } else {
        final lowerQuery = query.toLowerCase();
        final loadedMessages =
            widget.channel.state?.messages ?? const <Message>[];
        results = loadedMessages.where((message) {
          final text = (message.text ?? '').toLowerCase();
          return text.contains(lowerQuery);
        }).toList();
      }

      if (!mounted) return;
      setState(() {
        _results = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = tr('search_error_try_again');
        _results = const <Message>[];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _messagePreview(Message message, BuildContext context) {
    final text = (message.text ?? '').trim();
    if (text.isNotEmpty) return text;

    if (message.attachments.isNotEmpty) {
      final first = message.attachments.first;
      if (first.isImage) return tr('image');
      if (first.isFile || first.isVideo || first.isAudio) {
        return first.title ?? first.file?.name ?? tr('file');
      }
      if (first.isUrlPreview) {
        return first.title ??
            first.titleLink ??
            first.ogScrapeUrl ??
            tr('links');
      }
    }

    return tr('message_with_attachments');
  }
}

class _AttachmentWithMessage {
  final Message message;
  final Attachment attachment;

  const _AttachmentWithMessage({
    required this.message,
    required this.attachment,
  });
}

class _LinkItem {
  final String url;
  final String title;
  final String? subtitle;

  const _LinkItem({required this.url, required this.title, this.subtitle});
}
