import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/notification_icon.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final bool centerTitle;
  final bool showNotificationIcon;
  final double? leadingWidth;

  const CustomAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.titleStyle,
    this.centerTitle = true,
    this.showNotificationIcon = false,
    this.leadingWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final appBar = AppBar(
      title: title != null
          ? Text(
              title!,
              style:
                  titleStyle ??
                  TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
            )
          : const SizedBox(),
      leading: leading,
      leadingWidth: leadingWidth,
      actions: [
        if (showNotificationIcon)
          NotificationIcon(
            iconColor: Theme.of(context).appBarTheme.foregroundColor,
            iconSize: 30,
          ),
        ...?actions,
      ],
      backgroundColor:
          backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      centerTitle: centerTitle,
      flexibleSpace: isDarkMode
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: GlobalVariables.darkPrimaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            )
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    );

    return appBar;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
