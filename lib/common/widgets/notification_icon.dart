import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/notifications/services/notification_service.dart';
import 'package:frontend/features/notifications/screens/notifications_screen.dart';

class NotificationIcon extends StatefulWidget {
  final Color? iconColor;
  final double? iconSize;
  final VoidCallback? onTap;
  final bool autoRefresh;
  final Duration refreshInterval;

  const NotificationIcon({
    super.key,
    this.iconColor,
    this.iconSize,
    this.onTap,
    this.autoRefresh = true,
    this.refreshInterval = const Duration(seconds: 30),
  });

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon>
    with SingleTickerProviderStateMixin {
  int _unreadCount = 0;
  Timer? _refreshTimer;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.8,
      upperBound: 1.2,
    );

    _loadUnreadCount();

    if (widget.autoRefresh) {
      _refreshTimer = Timer.periodic(widget.refreshInterval, (timer) {
        _loadUnreadCount();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    if (!mounted) return;

    final count = await NotificationService.getUnreadCount(context: context);

    if (mounted) {
      if (count > _unreadCount) {
        // Animation khi có thông báo mới
        _animController.forward().then((_) => _animController.reverse());
      }
      setState(() {
        _unreadCount = count;
      });
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      Navigator.pushNamed(context, NotificationsScreen.routeName).then((_) {
        _loadUnreadCount();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chromeBackground = Theme.of(context).appBarTheme.backgroundColor;

    return Container(
      padding: EdgeInsets.only(right: 16, top: 5),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: _handleTap,
            child: SvgPicture.asset(
              _unreadCount > 0
                  ? 'assets/icons/bell-icon.svg'
                  : 'assets/icons/bell-line-icon.svg',
              colorFilter: ColorFilter.mode(
                widget.iconColor ?? Colors.white,
                BlendMode.srcIn,
              ),
              width: 26,
              height: 26,
            ),
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -9,
              top: -5,
              child: ScaleTransition(
                scale: _animController.drive(Tween(begin: 1.0, end: 1.2)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 1,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: GlobalVariables.errorRed,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: chromeBackground ?? Theme.of(context).canvasColor,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 6),
                  child: Center(
                    child: Text(
                      _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void refresh() {
    _loadUnreadCount();
  }
}
