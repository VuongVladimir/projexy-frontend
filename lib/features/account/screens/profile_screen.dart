// frontend/lib/features/account/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/account/screens/edit_profile_screen.dart';
import 'package:frontend/features/account/services/account_service.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';
  final String? userId; // Nếu null, hiển thị profile của user hiện tại
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (profileUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: Center(
          child: Text(
            'Không thể tải thông tin người dùng',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom AppBar với avatar
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            iconTheme: IconThemeData(color: GlobalVariables.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? GlobalVariables.darkPrimaryGradient
                        : GlobalVariables.primaryGradient,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    // Avatar lớn
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GlobalVariables.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        backgroundImage:
                            profileUser!.avatar != null &&
                                profileUser!.avatar!.isNotEmpty
                            ? NetworkImage(profileUser!.avatar!)
                            : null,
                        child:
                            profileUser!.avatar == null ||
                                profileUser!.avatar!.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              )
                            : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Tên
                    Text(
                      profileUser!.name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: GlobalVariables.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Email
                    Text(
                      profileUser!.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: GlobalVariables.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (isCurrentUser)
                IconButton(
                  icon: Icon(Icons.edit, color: GlobalVariables.white),
                  onPressed: () {
                    Navigator.pushNamed(context, EditProfileScreen.routeName);
                  },
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
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
          ),
        ],
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
