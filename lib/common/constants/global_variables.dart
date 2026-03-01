import 'package:flutter/material.dart';
import 'package:frontend/features/account/screens/account_screen.dart';
import 'package:frontend/features/chat/screens/channel_messages_screen.dart';
import 'package:frontend/features/home/screens/home_screen.dart';
import 'package:frontend/features/tasks/screens/tasks_screen.dart';

//String uri = "https://projexy-backend.me";
String uri = "http://192.168.1.14:3000";
const webScreenSize = 600;
List<Widget> bottomBarItems = [
  const HomeScreen(),
  const TasksScreen(),
  const ChannelMessagesScreen(),
  const AccountScreen(),
];

extension HexColor on String {
  Color toColor() {
    String hex = replaceAll('#', '').trim(); // bỏ '#' và khoảng trắng nếu có

    if (hex.isEmpty) {
      // fallback về màu xám hoặc màu mặc định
      return Colors.grey;
    }

    if (hex.length == 6) {
      // nếu không có alpha, thêm 'FF' cho full opacity
      hex = 'FF$hex';
    } else if (hex.length == 8) {
      // đã có alpha -> giữ nguyên
    } else {
      throw FormatException("Invalid hex color format: $this");
    }

    return Color(int.parse(hex, radix: 16));
  }
}

class GlobalVariables {
  static const Color primaryBlue = Color(0xFF274BFF); // #3443FD
  static const Color primaryBlueLight = Color(0xFF4B58F0);
  static const Color primaryBlueDark = Color(0xFF2B38D3);

  


  static const Color secondaryCoral = Color(0xFFEF736B); // #EF736B
  static const Color secondaryAlternate = Color(0xFFD5502B);

  // Badge Colors
  static const Color backgroundBlueLight = Color(0xFF007FFF);
  static const Color blueAvatar = Color(0xFF4285F4);
  static const Color blueFresh = Color(0xFF0D6EFD);
  static const Color yellowBadge = Color(0xFFFBB849);
  static const Color greenBadge = Color(0xFF25D366);
  static const Color orangeBadge = Color(0xFFFF7643);
  static const Color pinkBadge = Color(0xFFFF7295);
  static const Color redPinkBadge = Color(0xFFD81B60);
  static const Color purpleBadge = Color(0xFF7E64EE);
  static const Color grayBadge = Color(0xFF9FA8B8);
  static const Color blueBadge = Color(0xFF2196F3);

  // Background Colors (Light Theme)
  static const Color backgroundPrimary = Color(
    0xFFFFFFFF,
  ); // Nền chính (Trắng tinh)
  static const Color backgroundSecondary = Color(
    0xFFF8FAFC,
  ); // Nền phụ (Xám rất nhạt, tông lạnh)
  static const Color backgroundTertiary = Color(
    0xFFF0F5FF,
  ); // Nền card (Xanh dương rất nhạt)
  static const Color backgroundElevated = Color(0xFFFFFFFF); // Nền elevated

  // Surface Colors (Light Theme)
  static const Color surfacePrimary = Color(0xFFFFFFFF); // Surface chính
  static const Color surfaceSecondary = Color(0xFFF8FAFC); // Surface phụ
  static const Color surfaceCard = Color(0xFFFFFFFF); // Card surface
  static const Color surfaceDialog = Color(0xFFFFFFFF); // Dialog surface

  // Text Colors (Light Theme)
  // Văn bản chính theo style guide: gần #202020
  static const Color textPrimary = Color(0xFF202020);
  static const Color textSecondary = Color(0xFF475569); // Chữ phụ
  static const Color textTertiary = Color(0xFF94A3B8); // Chữ mờ
  static const Color textDisabled = Color(0xFFCBD5E1); // Chữ vô hiệu
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Chữ trên nền primary

  // Border Colors (Light Theme)
  static const Color borderPrimary = Color(0xFFE2E8F0); // Viền chính
  static const Color borderSecondary = Color(0xFFCBD5E1); // Viền phụ
  static const Color borderFocus = Color(0xFF3B82F6); // Viền focus
  static const Color divider = Color(0xFFE2E8F0); // Đường phân cách

  // ==================== DARK THEME COLORS ====================
  // Ghi chú: Dark theme được xây dựng trên nền màu Xám-Xanh đậm (Slate) thay vì đen tuyền,
  // giúp giảm mỏi mắt và tạo chiều sâu cho giao diện. Các màu sắc được tăng độ sáng để nổi bật trên nền tối.

  // Primary Colors (Dark Theme)
  static const Color darkPrimaryBlue = Color(
    0xFF5161FF,
  ); // phiên bản sáng của #2B38D3 cho dark
  static const Color darkPrimaryBlueLight = Color(0xFF8090FF);
  static const Color darkPrimaryBlueDark = Color(0xFF2B38D3);

  // Secondary Colors (Dark Theme)
  static const Color darkSecondaryCoral = Color(
    0xFFFF8B82,
  ); // sáng hơn của #EF746B
  static const Color darkSecondaryAlternate = Color(
    0xFFEB6334,
  ); // sáng hơn của #D4502A

  // Background Colors (Dark Theme)
  static const Color darkBackgroundPrimary = Color(
    0xFF020617,
  ); // Nền chính (Slate 950 - rất tối)
  static const Color darkBackgroundSecondary = Color(
    0xFF0F172A,
  ); // Nền phụ (Slate 900)
  static const Color darkBackgroundTertiary = Color(
    0xFF1E293B,
  ); // Nền card (Slate 800)
  static const Color darkBackgroundElevated = Color(
    0xFF1E293B,
  ); // Nền elevated tối

  // Surface Colors (Dark Theme)
  static const Color darkSurfacePrimary = Color(
    0xFF0F172A,
  ); // Surface chính tối
  static const Color darkSurfaceSecondary = Color(
    0xFF1E293B,
  ); // Surface phụ tối
  static const Color darkSurfaceCard = Color(0xFF1E293B); // Card surface tối
  static const Color darkSurfaceDialog = Color(
    0xFF1E293B,
  ); // Dialog surface tối

  // Text Colors (Dark Theme)
  static const Color darkTextPrimary = Color(
    0xFFF1F5F9,
  ); // Chữ chính sáng (Slate 100)
  static const Color darkTextSecondary = Color(
    0xFF94A3B8,
  ); // Chữ phụ sáng (Slate 400)
  static const Color darkTextTertiary = Color(
    0xFF64748B,
  ); // Chữ mờ sáng (Slate 500)
  static const Color darkTextDisabled = Color(
    0xFF475569,
  ); // Chữ vô hiệu sáng (Slate 600)
  static const Color darkTextOnPrimary = Color(
    0xFFFFFFFF,
  ); // Chữ trên nền primary

  // Border Colors (Dark Theme)
  static const Color darkBorderPrimary = Color(
    0xFF334155,
  ); // Viền chính tối (Slate 700)
  static const Color darkBorderSecondary = Color(
    0xFF475569,
  ); // Viền phụ tối (Slate 600)
  static const Color darkBorderFocus = Color(0xFF3B82F6); // Viền focus tối
  static const Color darkDivider = Color(0xFF334155); // Đường phân cách tối

  // ==================== LEGACY COLORS (Backward Compatibility) ====================

  // Màu trắng và xám cơ bản
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1F1F1F);
  static const Color greyLight = Color(0xFFE2E8F0);
  static const Color greyDark = Color(0xFF475569);

  // Background màu sáng (legacy)
  static const Color backgroundLight = Color(0xFFF8FAFC);

  // Accent colors (legacy)
  static const Color accentIndigo = Color(
    0xFF2B38D3,
  ); // dùng primary mới làm accent mặc định

  // ==================== STATUS COLORS (Universal) ====================
  // Ghi chú: Các màu trạng thái được chọn lọc lại để tươi tắn, rõ ràng và nhất quán hơn.
  // Ví dụ: màu đỏ lỗi được thay bằng màu "Rose" hiện đại hơn, màu vàng cảnh báo thay bằng "Orange" nổi bật hơn.

  // Success Colors
  static const Color successGreen = Color(0xFF16A34A); // Xanh thành công
  static const Color successGreenLight = Color(
    0xFF22C55E,
  ); // Xanh thành công nhạt
  static const Color successGreenDark = Color(
    0xFF15803D,
  ); // Xanh thành công đậm
  static const Color successBackground = Color(0xFFF0FDF4); // Nền thành công
  static const Color darkSuccessBackground = Color(
    0xFF14532D,
  ); // Nền thành công tối

  // Warning Colors
  static const Color warningAmber = Color(
    0xFFEA580C,
  ); // Cam cảnh báo (thay cho Vàng)
  static const Color warningAmberLight = Color(0xFFF97316); // Cam cảnh báo nhạt
  static const Color warningAmberDark = Color(0xFFC2410C); // Cam cảnh báo đậm
  static const Color warningBackground = Color(0xFFFFF7ED); // Nền cảnh báo
  static const Color darkWarningBackground = Color(
    0xFF7C2D12,
  ); // Nền cảnh báo tối

  // Error Colors
  static const Color errorRed = Color(0xFFE11D48); // Đỏ lỗi (Rose-Red)
  static const Color errorRedLight = Color(0xFFF43F5E); // Đỏ lỗi nhạt
  static const Color errorRedDark = Color(0xFFBE123C); // Đỏ lỗi đậm
  static const Color errorBackground = Color(0xFFFFF1F2); // Nền lỗi
  static const Color darkErrorBackground = Color(0xFF881337); // Nền lỗi tối

  // Info Colors
  static const Color infoBlue = Color(0xFF0284C7); // Xanh thông tin (Sky Blue)
  static const Color infoBlueLight = Color(0xFF0EA5E9); // Xanh thông tin nhạt
  static const Color infoBlueDark = Color(0xFF0369A1); // Xanh thông tin đậm
  static const Color infoBackground = Color(0xFFF0F9FF); // Nền thông tin
  static const Color darkInfoBackground = Color(
    0xFF082F49,
  ); // Nền thông tin tối

  // ==================== PROJECT STATUS COLORS ====================
  // Ghi chú: Đồng bộ hóa với các màu trạng thái universal để tạo sự nhất quán.

  // Project/Task Status
  static const Color statusPlanning = Color(0xFF6F42C1);
  static const Color statusInProgress = Color(0xFF007BFF);
  static const Color statusReview = Color(0xFFFD7E14);
  static const Color statusCompleted = Color(0xFF28A745);
  static const Color statusCancelled = Color(0xFFE11D48); // Hủy bỏ (Error Rose)
  static const Color statusOverdue = Color(
    0xFFBE123C,
  ); // Quá hạn (Error Rose Dark)

  // Priority Colors
  static const Color priorityLow = Color(0xFF20C997); // Ưu tiên thấp
  static const Color priorityMedium = Color(0xFFFFC107); // Ưu tiên trung bình
  static const Color priorityHigh = Color(0xFFDC3545); // Ưu tiên cao

  // ==================== GRADIENT COLORS ====================

  // Primary Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF3A47E2),
    Color(0xFF2B38D3),
  ];

  static const List<Color> darkPrimaryGradient = [
    Color(0xFF5161FF),
    Color(0xFF8090FF),
  ];

  // Success Gradient
  static const List<Color> successGradient = [
    Color(0xFF16A34A),
    Color(0xFF22C55E),
  ];

  // Warning Gradient
  static const List<Color> warningGradient = [
    Color(0xFFEA580C),
    Color(0xFFF97316),
  ];

  // Cool Gradient
  static const List<Color> coolGradient = [
    Color(0xFFEF746B),
    Color(0xFFD4502A),
  ];

  // ==================== ACCENT COLORS ====================
  // Ghi chú: Giữ lại các màu accent hiện đại, chúng đã rất tốt và phù hợp với xu hướng.

  // Modern Accent Colors
  static const Color accentTeal = Color(0xFF14B8A6); // Xanh ngọc hiện đại
  static const Color accentViolet = Color(0xFF8B5CF6); // Tím violet
  static const Color accentEmerald = Color(0xFF10B981); // Xanh emerald
  static const Color accentOrange = Color(0xFFF97316); // Cam hiện đại
  static const Color accentPink = Color(0xFFEC4899); // Hồng hiện đại
  static const Color accentCyan = Color(0xFF06B6D4); // Xanh cyan

  // ==================== CHART COLORS ====================
  // Ghi chú: Cập nhật lại danh sách màu biểu đồ để đảm bảo sự khác biệt rõ ràng và hài hòa.

  // Màu cho biểu đồ và data visualization
  static const List<Color> chartColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF22C55E), // Green
    Color(0xFFF97316), // Orange
    Color(0xFFF43F5E), // Rose
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEAB308), // Yellow
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo
  ];

  // ==================== UTILITY FUNCTIONS ====================

  // Hàm lấy màu theo theme
  static Color getTextPrimary(bool isDarkMode) {
    return isDarkMode ? darkTextPrimary : textPrimary;
  }

  static Color getTextSecondary(bool isDarkMode) {
    return isDarkMode ? darkTextSecondary : textSecondary;
  }

  static Color getBackgroundPrimary(bool isDarkMode) {
    return isDarkMode ? darkBackgroundPrimary : backgroundPrimary;
  }

  static Color getSurfacePrimary(bool isDarkMode) {
    return isDarkMode ? darkSurfacePrimary : surfacePrimary;
  }

  static Color getBorderPrimary(bool isDarkMode) {
    return isDarkMode ? darkBorderPrimary : borderPrimary;
  }

  static Color getPrimaryBlue(bool isDarkMode) {
    return isDarkMode ? darkPrimaryBlue : primaryBlue;
  }

  // Hàm lấy màu theo trạng thái
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'planning':
      case 'lên kế hoạch':
        return statusPlanning;
      case 'in-progress':
      case 'đang thực hiện':
        return statusInProgress;
      case 'review':
      case 'đánh giá':
        return statusReview;
      case 'completed':
      case 'hoàn thành':
        return statusCompleted;
      case 'cancelled':
      case 'hủy bỏ':
        return statusCancelled;
      case 'overdue':
      case 'quá hạn':
        return statusOverdue;
      default:
        return statusPlanning;
    }
  }

  // Hàm lấy màu theo độ ưu tiên
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
      case 'thấp':
        return priorityLow;
      case 'medium':
      case 'trung bình':
        return priorityMedium;
      case 'high':
      case 'cao':
        return priorityHigh;
      default:
        return priorityMedium;
    }
  }
}
