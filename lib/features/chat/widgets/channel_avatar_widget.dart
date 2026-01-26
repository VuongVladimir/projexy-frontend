import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/services/stream_chat_service.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';


class ChannelAvatarWidget extends StatelessWidget {
  final Channel channel;
  final double radius;
  final bool showOnlineIndicator;

  const ChannelAvatarWidget({
    super.key,
    required this.channel,
    this.radius = 28,
    this.showOnlineIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final channelImage = channel.image;
    final channelName = channel.getDisplayName();
    final category = channel.resolvedCategory;
    final isDirect = category == 'direct';

    // Nếu channel có avatar image đã được set
    if (channelImage != null && channelImage.isNotEmpty) {
      return _buildImageAvatar(channelImage);
    }

    // Nếu là Direct Channel -> hiển thị avatar của user kia
    if (isDirect) {
      return _buildDirectChannelAvatar();
    }

    // Project/Team channel không có avatar -> hiển thị avatarColor + chữ cái đầu
    return _buildDefaultChannelAvatar(channelName);
  }

  /// Build avatar với image từ URL
  Widget _buildImageAvatar(String imageUrl) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _getAvatarColor(),
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (_, __) {},
    );
  }

  /// Build avatar cho Direct Channel (1-1 chat)
  /// Hiển thị avatar của user còn lại trong channel
  Widget _buildDirectChannelAvatar() {
    final currentUserId = StreamChatService.currentUserId;
    final members = channel.state?.members ?? const <Member>[];

    // Tìm user còn lại (không phải current user)
    Member? otherMember;
    for (final member in members) {
      if (member.user?.id != currentUserId) {
        otherMember = member;
        break;
      }
    }

    final otherUser = otherMember?.user;
    final userImage = otherUser?.image;
    final userName = otherUser?.name ?? otherUser?.id ?? '';
    final userColorHex = (otherUser?.extraData['color'] as String?) ?? '#4B58F0';

    return CircleAvatar(
      radius: radius,
      backgroundColor: userColorHex.toColor(),
      backgroundImage: (userImage != null && userImage.isNotEmpty)
          ? NetworkImage(userImage)
          : null,
      child: (userImage == null || userImage.isEmpty)
          ? Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius -4,
              ),
            )
          : null,
    );
  }

  /// Build default avatar cho Project/Team channel
  /// Hiển thị avatarColor + chữ cái đầu của tên channel
  Widget _buildDefaultChannelAvatar(String channelName) {
    final avatarColor = _getAvatarColor();
    final initial = channelName.isNotEmpty ? channelName[0].toUpperCase() : 'C';

    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius - 4,
        ),
      ),
    );
  }

  /// Lấy avatarColor từ channel extraData
  Color _getAvatarColor() {
    final avatarColorHex =
        (channel.extraData['avatarColor'] as String?) ?? '#4285F4';
    try {
      return avatarColorHex.toColor();
    } catch (_) {
      return GlobalVariables.blueAvatar;
    }
  }

}

/// Extension để lấy các thông tin channel avatar
extension ChannelAvatarExtension on Channel {

  /// Kiểm tra channel có phải là Direct Channel không
  bool get isDirectChannel {
    final category = extraData['category'];
    if (category is String && category == 'direct') {
      return true;
    }

    final isMessaging = type == 'messaging';
    final count = memberCount ?? state?.members.length ?? 0;
    final isExplicitTeam = extraData['is_team'] == true;
    return isMessaging && count <= 2 && !isExplicitTeam;
  }

  /// Kiểm tra channel có phải là Project Channel không
  bool get isProjectChannel {
    final category = extraData['category'];
    if (category is String && category == 'project') {
      return true;
    }
    return extraData['project_id'] != null;
  }

  /// Kiểm tra channel có phải là Team Channel không
  bool get isTeamChannel {
    final category = extraData['category'];
    if (category is String && category == 'team') {
      return true;
    }
    return type == 'team' && extraData['project_id'] == null;
  }

  /// Lấy avatarColor của channel
  Color get avatarColor {
    final colorHex = (extraData['avatarColor'] as String?) ?? '#4285F4';
    try {
      return colorHex.toColor();
    } catch (_) {
      return GlobalVariables.blueAvatar;
    }
  }

  /// Kiểm tra channel có avatar image hay không
  bool get hasAvatarImage => image != null && image!.isNotEmpty;

  /// Lấy tên hiển thị của channel
  String getDisplayName({String? currentUserId}) {
    // Direct channel -> t??n user c??n l???i
    if (isDirectChannel) {
      final userId = currentUserId ?? StreamChatService.currentUserId;
      final members = state?.members ?? const <Member>[];
      for (final member in members) {
        if (member.user?.id != userId) {
          final userName = member.user?.name ?? member.user?.id ?? '';
          if (userName.trim().isNotEmpty) return userName;
        }
      }
    }

    // Project/Team channel -> ưu tiên name, fallback theo extraData
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }

    final projectTitle = extraData['project_title'];
    if (projectTitle is String && projectTitle.trim().isNotEmpty) {
      return projectTitle.trim();
    }

    final teamName = extraData['team_name'];
    if (teamName is String && teamName.trim().isNotEmpty) {
      return teamName.trim();
    }

    final fallbackName = extraData['name'];
    if (fallbackName is String && fallbackName.trim().isNotEmpty) {
      return fallbackName.trim();
    }

    return 'Chat';
  }

  /// Lấy category đã được chuẩn hóa
  String get resolvedCategory {
    final category = extraData['category'];
    if (category is String && category.trim().isNotEmpty) {
      return category.trim();
    }

    if (isDirectChannel) return 'direct';

    if (extraData['project_id'] != null ||
        (extraData['project_title'] is String &&
            (extraData['project_title'] as String).trim().isNotEmpty)) {
      return 'project';
    }

    if (type == 'team') return 'team';

    return 'team';
  }
}
