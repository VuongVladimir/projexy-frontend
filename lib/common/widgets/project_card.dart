import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/models/project.dart';
import 'package:easy_localization/easy_localization.dart';


class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showMenu;
  final int index; // Thêm index để xác định màu card
  final bool isHomeScreen;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showMenu = true,
    required this.index, // Bắt buộc phải có index
    this.isHomeScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Xác định màu card dựa trên index (xen kẽ giữa primaryBlue và secondaryCoral)
    final isPrimaryCard = index % 2 == 0;
    final cardColor = isPrimaryCard
        ? GlobalVariables.primaryBlue
        : GlobalVariables.secondaryCoral;
    final progressColor = isPrimaryCard
        ? GlobalVariables.secondaryCoral
        : GlobalVariables.primaryBlue;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          //borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status, Priority và Due Days ở đầu
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildPriorityPill(context, isPrimaryCard),
                    ),
                    Expanded(flex: 5, child: _buildDueDays(context)),
                  ],
                ),
                const SizedBox(height: 16),

                // Tên project
                Text(
                  project.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: isHomeScreen ? 22 : 18,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Task count
                Text(
                  tr('task_count', namedArgs: {'count': project.taskCount.toString()}),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(),
                        Text(
                          '${project.progress}% ${tr('done')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: project.progressPercentage,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Avatar thành viên
                    _buildMemberAvatars(progressColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityPill(BuildContext context, bool isPrimaryCard) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimaryCard ? Color(0xFFFFE8E3) : Color(0xFFBAC3FC),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        isHomeScreen ? project.priorityDisplayFullName : project.priorityDisplayName,
        style: TextStyle(
          color: isPrimaryCard
              ? GlobalVariables.secondaryAlternate
              : Color(0xFF4B2E83),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDueDays(BuildContext context) {
    final daysRemaining = project.daysRemaining;
    final isOverdue = project.isOverdue;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        isOverdue
            ? tr('overdue')
            : daysRemaining == 0
            ? tr('today')
            : tr('days_left', namedArgs: {'count': daysRemaining.toString()}),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        softWrap: true,
        maxLines: 2,
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildMemberAvatars(Color progressColor) {
    // Tạo danh sách tất cả thành viên (owner + members)
    final List<Map<String, dynamic>> allMembers = [];
    
    // Thêm owner
    if (project.createdBy['id'] != null) {
      allMembers.add({
        'id': project.createdBy['id'],
        'name': project.createdBy['name'] ?? tr('owner'),
        'avatar': project.createdBy['avatar'] ?? '',
        'avatarColor': project.createdBy['avatarColor'] ?? '#2196F3',
      });
    }
    
    // Thêm members
    for (var member in project.members) {
      if (member.userId != project.createdBy['id']) {
        allMembers.add({
          'id': member.userId,
          'name': member.userName ?? tr('user'),
          'avatar': member.avatar ?? '',
          'avatarColor': member.avatarColor ?? '#2196F3',
        });
      }
    }

    if (allMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxDisplay = 4;
    final totalMembers = allMembers.length;
    final displayCount = totalMembers > maxDisplay ? maxDisplay : totalMembers;
    final remaining = totalMembers - displayCount;

    // Tính toán chiều rộng stack
    final totalItemsOnStack = displayCount + (remaining > 0 ? 1 : 0);
    final avatarDiameter = 32.0; // Đường kính avatar nhỏ hơn cho project card
    final overlap = 24.0; // Khoảng cách chồng lên nhau
    final double stackWidth = (totalItemsOnStack - 1) * overlap + avatarDiameter;

    return SizedBox(
      height: 32, // Chiều cao phù hợp với avatar nhỏ
      width: stackWidth,
      child: Stack(
        children: [
          ...List.generate(displayCount, (index) {
            final member = allMembers[index];
            return Positioned(
              left: index * overlap,
              child: CircleAvatar(
                radius: 16, // Bán kính nhỏ hơn cho project card
                backgroundColor: member['avatarColor'].toString().toColor(),
                backgroundImage: member['avatar'] != null && member['avatar'].isNotEmpty
                    ? NetworkImage(member['avatar'])
                    : null,
                child: member['avatar'] == null || member['avatar'].isEmpty
                    ? Text(
                        (member['name'] ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15, // Font size nhỏ hơn
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
              left: displayCount * overlap,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: progressColor,
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Font size nhỏ hơn
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
