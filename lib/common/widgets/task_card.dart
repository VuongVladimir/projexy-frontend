import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final Function(bool)? onStatusChanged;
  final bool showMenu;
  final bool showSubtaskCount;
  final bool isHomeScreen;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusChanged,
    this.showMenu = true,
    this.showSubtaskCount = true,
    this.isHomeScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? GlobalVariables.darkSurfaceCard
            : GlobalVariables.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isHomeScreen) ...[
                  GestureDetector(
                    onTap: () {
                      if (onStatusChanged != null) {
                        onStatusChanged!(!task.isCompleted);
                      }
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? GlobalVariables.primaryBlue
                            : Colors.transparent,
                        border: Border.all(
                          color: task.isCompleted
                              ? GlobalVariables.primaryBlue
                              : (isDarkMode
                                    ? GlobalVariables.darkBorderSecondary
                                    : GlobalVariables.borderSecondary),
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: task.isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 23,
                          color: isDarkMode
                              ? GlobalVariables.darkTextPrimary
                              : GlobalVariables.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Subtask count
                      if (task.subTaskCount > 0)
                        Text(
                          tr(
                            'subtask_count',
                            namedArgs: {'count': task.subTaskCount.toString()},
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDarkMode
                                ? GlobalVariables.darkTextSecondary
                                : GlobalVariables.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 10),
                      _buildCompactPriorityChip(context),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: Stack(
                        children: [
                          CircularProgressIndicator(
                            value: task.progressPercentage,
                            backgroundColor: isDarkMode
                                ? GlobalVariables.darkBorderPrimary
                                : GlobalVariables.borderPrimary,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              GlobalVariables.secondaryCoral,
                            ),
                            strokeWidth: 3,
                          ),
                          Center(
                            child: Text(
                              '${task.progress}%',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? GlobalVariables.darkTextPrimary
                                    : GlobalVariables.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 21),
                    if (task.assignedTo.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showAssigneesBottomSheet(context),
                        child: _buildAvatarStack(isDarkMode),
                      )
                    else
                      Text(
                        tr('no_assignment'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDarkMode
                              ? GlobalVariables.darkTextTertiary
                              : GlobalVariables.textTertiary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarStack(bool isDarkMode) {
    final maxDisplay = 4;
    final totalAssignees = task.assignedTo.length;
    final displayCount = totalAssignees > maxDisplay
        ? maxDisplay
        : totalAssignees;
    final remaining = totalAssignees - displayCount;

    if (totalAssignees == 0) {
      // Trả về một widget trống nếu không có ai được gán, thay vì Stack trống
      return const SizedBox.shrink();
    }

    // ----- PHẦN THAY ĐỔI -----
    // Công thức tính toán chiều rộng mới, đơn giản và chính xác
    final totalItemsOnStack = displayCount + (remaining > 0 ? 1 : 0);
    final avatarDiameter =
        24.0; // Đường kính thực tế của CircleAvatar (radius * 2)
    final overlap = 20.0; // Khoảng cách chồng lên nhau

    // Chiều rộng = (tổng số mục - 1) * khoảng cách chồng + đường kính của một mục
    final double stackWidth =
        (totalItemsOnStack - 1) * overlap + avatarDiameter;
    // -------------------------

    return SizedBox(
      height: 28, // Giữ chiều cao để đảm bảo căn chỉnh dọc
      width: stackWidth,
      child: Stack(
        children: [
          ...List.generate(displayCount, (index) {
            final user = task.assignedTo[index];
            return Positioned(
              left: index * overlap, // Sử dụng biến overlap
              child: CircleAvatar(
                radius: 12, // Bán kính là 12 -> đường kính 24
                backgroundColor: user['avatarColor'].toString().toColor(),
                backgroundImage:
                    user['avatar'] != null && user['avatar'].isNotEmpty
                    ? NetworkImage(user['avatar'])
                    : null,
                child: user['avatar'] == null || user['avatar'].isEmpty
                    ? Text(
                        (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            );
          }),
          // +n indicator
          if (remaining > 0)
            Positioned(
              left: displayCount * overlap, // Sử dụng biến overlap
              child: CircleAvatar(
                radius: 12,
                backgroundColor: GlobalVariables.secondaryCoral,
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAssigneesBottomSheet(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? GlobalVariables.darkBorderPrimary
                    : GlobalVariables.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('assigned_to'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? GlobalVariables.darkTextPrimary
                          : GlobalVariables.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...task.assignedTo.map((user) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: user['avatarColor']
                                .toString()
                                .toColor(),
                            backgroundImage:
                                user['avatar'] != null &&
                                    user['avatar'].isNotEmpty
                                ? NetworkImage(user['avatar'])
                                : null,
                            child:
                                user['avatar'] == null || user['avatar'].isEmpty
                                ? Text(
                                    (user['name'] ?? 'U')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'] ?? tr('unknown'),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: isDarkMode
                                        ? GlobalVariables.darkTextPrimary
                                        : GlobalVariables.textPrimary,
                                  ),
                                ),
                                if (user['email'] != null &&
                                    user['email'].isNotEmpty)
                                  Text(
                                    user['email'],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDarkMode
                                          ? GlobalVariables.darkTextSecondary
                                          : GlobalVariables.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPriorityChip(BuildContext context) {
    final priorityColor = GlobalVariables.getPriorityColor(task.priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        task.priorityDisplayName,
        style: TextStyle(
          color: GlobalVariables.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
