import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/account/screens/notifications_management.dart';
import 'package:frontend/features/account/screens/profile_screen.dart';
import 'package:frontend/features/account/screens/edit_profile_screen.dart';
import 'package:frontend/features/account/screens/setting_screen.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class AccountScreen extends StatelessWidget {
  static const String routeName = '/account';
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final authService = AuthService();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Kiểm tra nếu user chưa đăng nhập hoặc đang logout
    if (user.id.isEmpty || user.token.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: tr('account'), centerTitle: false),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 80,
                color: GlobalVariables.textTertiary,
              ),
              SizedBox(height: 16),
              Text(
                tr('unknown_user'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: GlobalVariables.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: tr('account'),
        centerTitle: false,
        actions: [
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                position: PopupMenuPosition.under,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'logout':
                    authService.logOut(context);
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: GlobalVariables.errorRed,
                        ),
                        const SizedBox(width: 8),
                        Text(tr('logout')),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ),
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
                padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor:
                            user.avatarColor?.toColor() ??
                            GlobalVariables.primaryBlue,
                        backgroundImage:
                            user.avatar != null && user.avatar!.isNotEmpty
                            ? NetworkImage(user.avatar!)
                            : null,
                        child: user.avatar == null || user.avatar!.isEmpty
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name.substring(0, 1).toUpperCase()
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
                    SizedBox(height: 16),
                    // Tên user
                    Text(
                      user.name.isNotEmpty ? user.name : tr('unknown_user'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: GlobalVariables.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Email
                    Text(
                      user.email.isNotEmpty ? user.email : tr('no_email'),
                      style: TextStyle(
                        fontSize: 16,
                        color: GlobalVariables.black.withValues(alpha: 0.8),
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

            // Menu options
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Symbols.person,
                    title: tr('view_profile'),
                    subtitle: tr('view_detailed_info'),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        ProfileScreen.routeName,
                        arguments: user.id,
                      );
                    },
                  ),

                  _buildMenuItem(
                    context,
                    icon: Symbols.edit,
                    title: tr('edit_profile'),
                    subtitle: tr('update_personal_info'),
                    onTap: () {
                      Navigator.pushNamed(context, EditProfileScreen.routeName);
                    },
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    svgIcon: SvgPicture.asset(
                      'assets/icons/bell-icon.svg',
                      colorFilter: ColorFilter.mode(
                        GlobalVariables.white,
                        BlendMode.srcIn,
                      ),
                      width: 28,
                      height: 28,
                    ),
                    title: tr('notifications'),
                    subtitle: tr('manage_notifications'),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        NotificationsManagement.routeName,
                      );
                    },
                  ),

                  _buildMenuItem(
                    context,
                    icon: Symbols.settings,
                    title: tr('settings'),
                    subtitle: tr('app_configuration'),
                    onTap: () {
                      Navigator.pushNamed(context, SettingScreen.routeName);
                    },
                  ),
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => authService.logOut(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: GlobalVariables.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text(
                      tr('logout'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    SvgPicture? svgIcon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: GlobalVariables.backgroundBlueLight,
          borderRadius: BorderRadius.circular(8.5),
        ),
        child:
            svgIcon ??
            Icon(icon, color: GlobalVariables.white, size: 28, fill: 1),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
