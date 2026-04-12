import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/account/screens/edit_profile_screen.dart';
import 'package:frontend/features/account/services/account_service.dart';
import 'package:frontend/features/chat/screens/chat_room_screen.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AccountService accountService = AccountService();
  User? profileUser;
  bool isLoading = true;
  bool isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = Provider.of<UserProvider>(
        context,
        listen: false,
      ).user;

      if (widget.userId == null || widget.userId == currentUser.id) {
        setState(() {
          profileUser = currentUser;
          isCurrentUser = true;
          isLoading = false;
        });
      } else {
        _loadUserProfile(widget.userId!);
      }
    });
  }

  void _loadUserProfile(String userId) async {
    try {
      final user = await accountService.getUserProfile(context, userId);
      if (user != null) {
        setState(() {
          profileUser = user;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _openDirectChat() async {
    if (profileUser == null) return;
    if (StreamChatService.client == null) {
      showSnackBar(context, 'Chat chưa được khởi tạo. Vui lòng thử lại.');
      debugPrint(
        'openDirectChat failed: StreamChatService.client is null for user=${profileUser!.id}',
      );
      return;
    }

    final currentUser = Provider.of<UserProvider>(context, listen: false).user;

    if (StreamChatService.currentUserId == null) {
      debugPrint(
        'openDirectChat: currentUserId is null, re-initialize with ${currentUser.id}',
      );
      await StreamChatService.initialize(
        context: context,
        userId: currentUser.id,
      );
    }

    debugPrint('openDirectChat: otherUserId=${profileUser!.id}');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final channel = await StreamChatService.createAndWatchDirectChat(
      profileUser!.id,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    if (channel == null) {
      showSnackBar(context, 'Không thể mở cuộc trò chuyện.');
      debugPrint('openDirectChat failed: channel is null');
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatRoomScreen(channel: channel)));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Profile', centerTitle: false),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (profileUser == null) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Profile', centerTitle: false),
        body: Center(
          child: Text(
            'Không thể tải thông tin người dùng',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          isCurrentUser
              ? IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(context, EditProfileScreen.routeName);
                  },
                )
              : IconButton(icon: Icon(Symbols.sms), onPressed: _openDirectChat),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với thông tin user
            Container(
              width: double.infinity,
              color: Theme.of(context).appBarTheme.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDarkMode ? 0.28 : 0.2,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor:
                            profileUser!.avatarColor?.toColor() ??
                            GlobalVariables.blueAvatar,
                        backgroundImage:
                            profileUser!.avatar != null &&
                                profileUser!.avatar!.isNotEmpty
                            ? NetworkImage(profileUser!.avatar!)
                            : null,
                        child:
                            profileUser!.avatar == null ||
                                profileUser!.avatar!.isEmpty
                            ? Text(
                                profileUser!.name.isNotEmpty
                                    ? profileUser!.name
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : "U",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 60,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tên user
                    Text(
                      profileUser!.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Email
                    Text(
                      profileUser!.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio section
                  if (profileUser!.bio != null && profileUser!.bio!.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'Giới thiệu',
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          profileUser!.bio!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 24),

                  // Skills section
                  if (profileUser!.skills != null &&
                      profileUser!.skills!.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'Kỹ năng',
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profileUser!.skills!
                              .map((skill) => _buildSkillTag(context, skill))
                              .toList(),
                        ),
                      ),
                    ),

                  SizedBox(height: 24),

                  // Contact section
                  _buildSection(
                    context,
                    title: 'Thông tin liên hệ',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildContactItem(
                            context,
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: profileUser!.email,
                          ),
                          Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor,
                          ),
                          _buildContactItem(
                            context,
                            icon: Icons.calendar_today_outlined,
                            title: 'Tham gia từ',
                            value:
                                'Tháng 9, 2024', // TODO: Thêm createdAt vào model
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 100), // Bottom spacing
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildSkillTag(BuildContext context, String skill) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
