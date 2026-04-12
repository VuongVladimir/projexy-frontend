import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;

    final appBar = AppBar(
      title: title != null
          ? Text(
              title!,
              style:
                  titleStyle ??
                  TextStyle(
                    color: appBarTheme.foregroundColor,
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
            iconColor: appBarTheme.foregroundColor,
            iconSize: 30,
          ),
        ...?actions,
      ],
      backgroundColor: backgroundColor ?? appBarTheme.backgroundColor,
      centerTitle: centerTitle,
      surfaceTintColor: Colors.transparent,
      shadowColor: theme.shadowColor.withValues(alpha: 0.12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    );

    return appBar;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
