import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChatInfoScreen extends StatelessWidget {
  final Channel channel;
  final String projectTitle;

  const ChatInfoScreen({
    super.key,
    required this.channel,
    required this.projectTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final members = channel.state?.members ?? [];

    return StreamChannel(
      channel: channel,
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
          centerTitle: true,
          title: Text(
            tr('chat_info'),
            style: TextStyle(
              color: isDarkMode
                  ? GlobalVariables.darkTextPrimary
                  : GlobalVariables.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? GlobalVariables.darkSurfaceCard
                    : GlobalVariables.surfaceCard,
                border: Border.all(
                  color: isDarkMode
                      ? GlobalVariables.darkBorderPrimary
                      : GlobalVariables.borderPrimary,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.forum_outlined,
                    color: GlobalVariables.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? GlobalVariables.darkTextPrimary
                                    : GlobalVariables.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr('members_count', namedArgs: {'count': '${members.length}'}),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDarkMode
                                    ? GlobalVariables.darkTextSecondary
                                    : GlobalVariables.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildNavTile(
              context: context,
              icon: Icons.people_alt_outlined,
              title: tr('members'),
              subtitle: tr('view_all_members'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ChatMembersScreen(channel: channel),
                ),
              ),
            ),
            _buildNavTile(
              context: context,
              icon: Icons.push_pin_outlined,
              title: tr('pinned_messages'),
              subtitle: tr('view_pinned_messages'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _PinnedMessagesScreen(channel: channel),
                ),
              ),
            ),
            _buildNavTile(
              context: context,
              icon: Icons.perm_media_outlined,
              title: tr('media_and_files'),
              subtitle: tr('view_shared_media_files'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ChannelMediaScreen(channel: channel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? GlobalVariables.darkSurfaceCard
            : GlobalVariables.surfaceCard,
        border: Border.all(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GlobalVariables.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: GlobalVariables.primaryBlue),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDarkMode
              ? GlobalVariables.darkTextSecondary
              : GlobalVariables.textSecondary,
        ),
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
                final colorHex = (user?.extraData['color'] as String?) ?? '#4B58F0';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                  leading: const Icon(Icons.push_pin_outlined),
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final img = images[index];
                      final url = img.imageUrl ?? img.assetUrl ?? img.thumbUrl ?? '';
                      if (url.isEmpty) {
                        return Container(
                          color: GlobalVariables.borderPrimary,
                          child: const Icon(Icons.broken_image_outlined),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                        ),
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
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(title),
                        subtitle: size != null
                            ? Text('${(size / (1024 * 1024)).toStringAsFixed(2)} MB')
                            : null,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          final url = f.assetUrl ?? f.file?.path ?? f.titleLink ?? '';
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


