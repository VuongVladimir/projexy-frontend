import 'dart:io';
import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
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
            // Header section với Avatar và tên channel
            _buildHeaderSection(
              context,
              isDarkMode: isDarkMode,
              channelName: channelName,
              category: category,
              isDirect: isDirect,
            ),
            const SizedBox(height: 18),

            // Chat info section (chỉ hiển thị cho non-direct channel)
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

            // More actions section
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      _PinnedMessagesScreen(channel: widget.channel),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionRow(
              context: context,
              icon: Symbols.search,
              fill: 1,
              title: tr('search_in_conversation'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build header section với avatar và tên channel (tương tự account_screen)
  Widget _buildHeaderSection(
    BuildContext context, {
    required bool isDarkMode,
    required String channelName,
    required String category,
    required bool isDirect,
  }) {
    final canEditAvatar =
        !isDirect; // Chỉ cho phép edit avatar với project/team channel

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Avatar với edit icon (nếu không phải direct channel)
          Stack(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: _selectedAvatar != null
                    ? CircleAvatar(
                        radius: 64,
                        backgroundColor: widget.channel.avatarColor,
                        backgroundImage: _getAvatarImage(),
                      )
                    : ChannelAvatarWidget(channel: widget.channel, radius: 64),
              ),

              // Loading overlay khi đang upload
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

              // Edit button (chỉ hiển thị cho project/team channel)
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

          // Channel name
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

          // Category badge
          if (isDirect == false) _buildCategoryBadge(context, category),
        ],
      ),
    );
  }

  /// Build category badge
  Widget _buildCategoryBadge(BuildContext context, String category) {
    final label = category == 'project'
        ? tr('project')
        : category == 'direct'
        ? tr('direct_chat')
        : tr('team');

    final bgColor = category == 'project'
        ? GlobalVariables.primaryBlue.withValues(alpha: 0.12)
        : category == 'direct'
        ? GlobalVariables.accentViolet.withValues(alpha: 0.12)
        : GlobalVariables.accentTeal.withValues(alpha: 0.12);

    final textColor = category == 'project'
        ? GlobalVariables.primaryBlue
        : category == 'direct'
        ? GlobalVariables.accentViolet
        : GlobalVariables.accentTeal;

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

  /// Chọn và upload avatar mới cho channel
  Future<void> _selectAndUploadAvatar() async {
    try {
      // Set processing state khi bắt đầu chọn ảnh
      setState(() => _isProcessingImage = true);

      // Chọn ảnh
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessingImage = false);
        return;
      }

      // Lưu selected avatar để preview
      setState(() {
        if (kIsWeb) {
          _selectedAvatar = result.files.first.bytes;
        } else {
          _selectedAvatar = File(result.files.single.path!);
        }
        _isProcessingImage = false;
        _isUploadingAvatar = true; // Bắt đầu upload
      });

      // Upload lên Cloudinary
      final cloudinary = CloudinaryPublic('dkwp4prjj', 'projexy_preset');
      CloudinaryResponse response;

      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes == null) {
          throw Exception('Cannot read file bytes');
        }
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
        if (path == null) {
          throw Exception('Cannot get file path');
        }
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(path, folder: 'channel_avatars'),
        );
      }

      final avatarUrl = response.secureUrl;

      final previousImage = widget.channel.image;
      final previousAvatarColor =
          widget.channel.extraData['avatarColor'] as String?;

      // Optimistic: cập nhật avatar ngay trên UI
      await StreamChatService.updateChannelAvatarDirect(
        channel: widget.channel,
        avatarUrl: avatarUrl,
      );

      // Cập nhật avatar channel qua API
      final success = await StreamChatService.updateChannelAvatar(
        channelId: widget.channel.id!,
        channelType: widget.channel.type,
        avatarUrl: avatarUrl,
      );

      if (success) {
        // Clear selected avatar sau khi upload thành công
        setState(() => _selectedAvatar = null);
        if (mounted) {
          showSnackBar(context, tr('channel_avatar_updated'));
        }
      } else {
        // Rollback nếu backend thất bại
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
      if (mounted) {
        showSnackBar(context, tr('error_uploading_image'));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
          _isProcessingImage = false;
        });
      }
    }
  }

  /// Get avatar image từ selectedAvatar hoặc channel
  ImageProvider? _getAvatarImage() {
    if (_selectedAvatar != null) {
      if (kIsWeb) {
        return MemoryImage(_selectedAvatar as Uint8List);
      } else {
        return FileImage(_selectedAvatar as File);
      }
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
          stream: channel.state?.messagesStream,
          initialData: channel.state?.messages ?? const <Message>[],
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <Message>[];
            final pinned = all.where((m) => m.pinned == true).toList();
            if (pinned.isEmpty) {
              return Center(
                child: Text(
                  tr('no_pinned_messages'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: pinned.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final m = pinned[index];
                final userName = m.user?.name ?? m.user?.id ?? 'User';
                final text = (m.text ?? '').trim();
                return ListTile(
                  leading: const Icon(Symbols.push_pin),
                  title: Text(userName),
                  subtitle: Text(
                    text.isNotEmpty ? text : tr('message_with_attachments'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _ChannelMediaScreen extends StatelessWidget {
  final Channel channel;
  const _ChannelMediaScreen({required this.channel});

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
          title: Text(tr('media_and_files')),
          centerTitle: true,
          backgroundColor: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          elevation: 0,
        ),
        body: StreamBuilder<List<Message>>(
          stream: channel.state?.messagesStream,
          initialData: channel.state?.messages ?? const <Message>[],
          builder: (context, snapshot) {
            final messages = snapshot.data ?? const <Message>[];
            final images = <Attachment>[];
            final files = <Attachment>[];
            for (final m in messages) {
              for (final a in m.attachments) {
                final type = a.type ?? '';
                if (type == 'image') {
                  images.add(a);
                } else if (type == 'file' || type == 'video') {
                  files.add(a);
                }
              }
            }
            if (images.isEmpty && files.isEmpty) {
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
                if (images.isNotEmpty)
                  Text(
                    tr('images'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (images.isNotEmpty) const SizedBox(height: 8),
                if (images.isNotEmpty)
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final img = images[index];
                      final url =
                          img.imageUrl ?? img.assetUrl ?? img.thumbUrl ?? '';
                      if (url.isEmpty) {
                        return Container(
                          color: GlobalVariables.borderPrimary,
                          child: const Icon(Symbols.broken_image),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, fit: BoxFit.cover),
                      );
                    },
                  ),
                if (files.isNotEmpty) const SizedBox(height: 16),
                if (files.isNotEmpty)
                  Text(
                    tr('files'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (files.isNotEmpty) const SizedBox(height: 8),
                if (files.isNotEmpty)
                  ...files.map((f) {
                    final title = f.title ?? f.file?.name ?? tr('file');
                    final size = f.file?.size;
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
                        title: Text(title),
                        subtitle: size != null
                            ? Text(
                                '${(size / (1024 * 1024)).toStringAsFixed(2)} MB',
                              )
                            : null,
                        trailing: const Icon(Symbols.chevron_right),
                        onTap: () {
                          final url =
                              f.assetUrl ?? f.file?.path ?? f.titleLink ?? '';
                          if (url.isNotEmpty) {
                            // Tuỳ ứng dụng có thể mở trình duyệt hoặc viewer
                          }
                        },
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
