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
    final category = channel.resolvedCategory;
    final isDirect = category == 'direct';

    // Nếu channel có avatar image đã được set (không áp dụng cho direct channel)
    if (!isDirect && channelImage != null && channelImage.isNotEmpty) {
      return _buildImageAvatar(channelImage);
    }

    // Nếu là Direct Channel -> sử dụng StreamBuilder để theo dõi members stream
    if (isDirect) {
      return _buildDirectChannelAvatarStream();
    }

    // Project channel không có avatar -> hiển thị avatarColor + chữ cái đầu
    final channelName = channel.getDisplayName();
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

  /// Build avatar cho Direct Channel sử dụng StreamBuilder
  /// Để đảm bảo cập nhật khi members stream thay đổi
  Widget _buildDirectChannelAvatarStream() {
    return StreamBuilder<List<Member>>(
      stream: channel.state?.membersStream,
      initialData: channel.state?.members ?? const <Member>[],
      builder: (context, snapshot) {
        final members = snapshot.data ?? const <Member>[];
        return _buildDirectChannelAvatarFromMembers(members);
      },
    );
  }

  /// Build avatar cho Direct Channel từ danh sách members
  Widget _buildDirectChannelAvatarFromMembers(List<Member> members) {
    final otherMember = channel.getDirectOtherMember(members: members);
    final otherUser = otherMember?.user;
    final userImage = otherUser?.image;
    final userName = otherUser?.name ?? otherMember?.userId ?? '';
    final userColorHex =
        (otherUser?.extraData['color'] as String?) ?? '#4B58F0';

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
                fontSize: radius - 4,
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

  Member? getDirectOtherMember({String? currentUserId, List<Member>? members}) {
    final userId = (currentUserId ?? StreamChatService.currentUserId)?.trim();
    if (userId == null || userId.isEmpty) return null;

    final sourceMembers = members ?? state?.members ?? const <Member>[];
    for (final member in sourceMembers) {
      final memberUserId = member.userId ?? member.user?.id;
      if (memberUserId != null && memberUserId != userId) {
        return member;
      }
    }

    return null;
  }

  String getDirectDisplayName({String? currentUserId, List<Member>? members}) {
    final otherMember = getDirectOtherMember(
      currentUserId: currentUserId,
      members: members,
    );
    final userName = otherMember?.user?.name ?? otherMember?.userId ?? '';
    if (userName.trim().isNotEmpty) return userName.trim();
    return 'Chat';
  }

  /// Lấy tên hiển thị của channel
  String getDisplayName({String? currentUserId, List<Member>? members}) {
    // Direct channel -> t??n user c??n l???i
    if (isDirectChannel) {
      return getDirectDisplayName(
        currentUserId: currentUserId,
        members: members,
      );
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
      // App không sử dụng team, chuyển team về project
      if (category.trim() == 'team') return 'project';
      return category.trim();
    }

    if (isDirectChannel) return 'direct';

    // Nếu có project_id hoặc project_title hoặc type là 'team' -> project channel
    if (extraData['project_id'] != null ||
        (extraData['project_title'] is String &&
            (extraData['project_title'] as String).trim().isNotEmpty) ||
        type == 'team') {
      return 'project';
    }

    return 'project';
  }
}
