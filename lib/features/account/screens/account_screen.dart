import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/account/screens/notifications_management.dart';
import 'package:frontend/features/account/screens/profile_screen.dart';
import 'package:frontend/features/account/screens/edit_profile_screen.dart';
import 'package:frontend/features/account/screens/help_support_screen.dart';
import 'package:frontend/features/account/screens/payment_history_screen.dart';
import 'package:frontend/features/account/screens/setting_screen.dart';
import 'package:frontend/features/account/widgets/premium_upgrade_dialog.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

class AccountScreen extends StatelessWidget {
  static const String routeName = '/account';
  const AccountScreen({super.key});

  Future<void> _reloadAccountData(BuildContext context) async {
    final authService = AuthService();
    await authService.getUserData(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final authService = AuthService();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final premiumIconKey = GlobalKey();
    final premiumValidUntilText = user.premiumValidUntil != null
        ? DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(user.premiumValidUntil!.toLocal())
        : tr('unknown');

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
                color: isDarkMode
                    ? GlobalVariables.darkTextTertiary
                    : GlobalVariables.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                tr('unknown_user'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
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

    return Scaffold(
      appBar: CustomAppBar(
        title: tr('account'),
        centerTitle: false,
        actions: user.isPremiumActive
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    key: premiumIconKey,
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _showPremiumStatusBubble(
                        context,
                        premiumIconKey,
                        premiumValidUntilText,
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/images/premium_1.svg',
                      width: 36,
                      height: 36,
                    ),
                  ),
                ),
              ]
            : [],
      ),
      body: RefreshIndicator(
        onRefresh: () => _reloadAccountData(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                              user.avatarColor?.toColor() ??
                              GlobalVariables.blueAvatar,
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
                      const SizedBox(height: 16),
                      // Tên user
                      Text(
                        user.name.isNotEmpty ? user.name : tr('unknown_user'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        user.email.isNotEmpty ? user.email : tr('no_email'),
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

              // Premium upgrade card
              if (!user.isPremiumActive) _buildPremiumCard(context, isDarkMode),

              // Menu options
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Symbols.person,
                      badgeBackgroundColor: GlobalVariables.blueBadge,
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
                      badgeBackgroundColor: GlobalVariables.yellowBadge,
                      title: tr('edit_profile'),
                      subtitle: tr('update_personal_info'),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          EditProfileScreen.routeName,
                        );
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.receipt_long_outlined,
                      badgeBackgroundColor: GlobalVariables.purpleBadge,
                      title: tr('payment_history_title'),
                      subtitle: tr('payment_history_menu_subtitle'),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          PaymentHistoryScreen.routeName,
                        );
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.notifications_outlined,
                      badgeBackgroundColor: GlobalVariables.orangeBadge,
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
                      icon: Icons.support_agent_outlined,
                      badgeBackgroundColor: GlobalVariables.greenBadge,
                      title: tr('help_support'),
                      subtitle: tr('help_support_subtitle'),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          HelpSupportScreen.routeName,
                        );
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Symbols.settings,
                      badgeBackgroundColor: GlobalVariables.grayBadge,
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
      ),
    );
  }

  Future<void> _showPremiumStatusBubble(
    BuildContext context,
    GlobalKey iconKey,
    String premiumValidUntilText,
  ) async {
    final overlayState = Overlay.of(context);
    if (overlayState == null) return;

    final overlayBox = overlayState.context.findRenderObject() as RenderBox?;
    final iconBox = iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlayBox == null || iconBox == null) return;

    final iconOffset = iconBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final iconSize = iconBox.size;

    await showMenu<void>(
      context: context,
      color: const Color(0xFFFFF8E6),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFFFDE99), width: 1),
      ),
      position: RelativeRect.fromLTRB(
        iconOffset.dx - 190 + iconSize.width,
        iconOffset.dy + iconSize.height + 6,
        overlayBox.size.width - iconOffset.dx - iconSize.width,
        overlayBox.size.height - iconOffset.dy - iconSize.height,
      ),
      items: [
        PopupMenuItem<void>(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(top: 1),
                      child: SvgPicture.asset('assets/images/premium_1.svg'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tr('premium_active_title'),
                            style: const TextStyle(
                              color: Color(0xFF5C3900),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            tr(
                              'premium_active_until',
                              namedArgs: {'date': premiumValidUntilText},
                            ),
                            style: const TextStyle(
                              color: Color(0xFF7A5200),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 21),
                Align(
                  alignment: Alignment.center,
                  child: IntrinsicWidth(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              PremiumUpgradeDialog.show(context);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFD46A),
                                Color(0xFFFFCC5C),
                                Color(0xFFFFC056),
                                Color(0xFFFFB85A),
                                Color(0xFFFFAD60),
                              ],
                              stops: [0.0, 0.36, 0.85, 0.95, 1.0],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFA726,
                                ).withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.autorenew_rounded,
                                color: Color(0xFF4A2A00),
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr('premium_renew_title'),
                                style: const TextStyle(
                                  color: Color(0xFF4A2A00),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumCard(BuildContext context, bool isDarkMode) {
    const premiumTitleColor = Color(0xFF4A2A00);
    const premiumSubtitleColor = Color(0xFF6B3E09);

    return GestureDetector(
      onTap: () => PremiumUpgradeDialog.show(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD46A),
              Color(0xFFFFCC5C),
              Color(0xFFFFC056),
              Color(0xFFFFB85A),
              Color(0xFFFFAD60),
            ],
            stops: [0.0, 0.36, 0.85, 0.95, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA726).withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/images/premium_1.svg',
              width: 42,
              height: 42,
            ),

            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('premium_upgrade_title'),
                    style: TextStyle(
                      color: premiumTitleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('premium_upgrade_card_subtitle'),
                    style: TextStyle(
                      color: premiumSubtitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
    required Color badgeBackgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: badgeBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            svgIcon ??
            Icon(
              icon,
              color: GlobalVariables.white,
              size: 28,
              fill: 1,
              weight: 600,
              grade: 300,
            ),
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
