import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/models/project.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class TaskFormWidgets {
  /// Widget chọn độ ưu tiên hiện đại cho task
  static Widget buildModernPrioritySelector({
    required String selectedPriority,
    required Function(String) onPriorityChanged,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildPriorityButton(
            'low',
            GlobalVariables.successGreen,
            selectedPriority,
            onPriorityChanged,
            context,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPriorityButton(
            'medium',
            GlobalVariables.warningAmber,
            selectedPriority,
            onPriorityChanged,
            context,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPriorityButton(
            'high',
            GlobalVariables.errorRed,
            selectedPriority,
            onPriorityChanged,
            context,
          ),
        ),
      ],
    );
  }

  static Widget _buildPriorityButton(
    String value,
    Color color,
    String selectedPriority,
    Function(String) onPriorityChanged,
    BuildContext context,
  ) {
    final isSelected = selectedPriority == value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String getDisplayText(String value) {
      switch (value) {
        case 'high':
          return tr('high');
        case 'medium':
          return tr('medium');
        case 'low':
          return tr('low');
        default:
          return value;
      }
    }

    return GestureDetector(
      onTap: () => onPriorityChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDarkMode
                    ? GlobalVariables.darkSurfaceCard
                    : GlobalVariables.surfaceCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : (GlobalVariables.darkBorderPrimary.withValues(alpha: 0.5)),
          ),
        ),
        child: Center(
          child: Text(
            getDisplayText(value),
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : GlobalVariables.textPrimary),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  /// Widget chọn trọng số cho task
  static Widget buildWeightSelector({
    required int selectedWeight,
    required Function(int) onWeightChanged,
    required BuildContext context,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildWeightButton(
                1,
                selectedWeight,
                onWeightChanged,
                context,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildWeightButton(
                2,
                selectedWeight,
                onWeightChanged,
                context,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildWeightButton(
                3,
                selectedWeight,
                onWeightChanged,
                context,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildWeightButton(
                4,
                selectedWeight,
                onWeightChanged,
                context,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildWeightButton(
                5,
                selectedWeight,
                onWeightChanged,
                context,
              ),
            ),
          ],
        ),
        // const SizedBox(height: 8),
        // Text(
        //   _getWeightDescription(selectedWeight),
        //   style: TextStyle(
        //     color: isDarkMode
        //         ? GlobalVariables.darkTextSecondary
        //         : GlobalVariables.textSecondary,
        //     fontSize: 13,
        //     fontStyle: FontStyle.italic,
        //   ),
        //   textAlign: TextAlign.center,
        // ),
      ],
    );
  }

  static Widget _buildWeightButton(
    int weight,
    int selectedWeight,
    Function(int) onWeightChanged,
    BuildContext context,
  ) {
    final isSelected = selectedWeight == weight;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Màu gradient dựa trên weight
    Color getWeightColor(int weight) {
      switch (weight) {
        case 1:
          return GlobalVariables.successGreen;
        case 2:
          return GlobalVariables.successGreenLight;
        case 3:
          return GlobalVariables.warningAmber;
        case 4:
          return GlobalVariables.errorRed;
        case 5:
          return GlobalVariables.errorRedDark;
        default:
          return GlobalVariables.primaryBlue;
      }
    }

    return GestureDetector(
      onTap: () => onWeightChanged(weight),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? getWeightColor(weight)
              : (isDarkMode
                    ? GlobalVariables.darkSurfaceCard
                    : GlobalVariables.surfaceCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? getWeightColor(weight)
                : (GlobalVariables.darkBorderPrimary.withValues(alpha: 0.5)),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '$weight',
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : GlobalVariables.textPrimary),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  static String _getWeightDescription(int weight) {
    switch (weight) {
      case 1:
        return tr('weight_very_low');
      case 2:
        return tr('weight_low');
      case 3:
        return tr('weight_medium');
      case 4:
        return tr('weight_high');
      case 5:
        return tr('weight_very_high');
      default:
        return '';
    }
  }

  /// Widget chọn ngày hiện đại cho task
  static Widget buildModernDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GlobalVariables.darkBorderPrimary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDarkMode
                          ? GlobalVariables.darkTextSecondary
                          : GlobalVariables.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : tr('select_date'),
                    style: TextStyle(
                      color: isDarkMode
                          ? GlobalVariables.darkTextPrimary
                          : GlobalVariables.textPrimary,
                      fontSize: 16,
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

  /// Widget chọn date range cho task
  static Widget buildDateRangeFields({
    required DateTime? startDate,
    required DateTime? endDate,
    required Function(DateTime?) onStartDateChanged,
    required Function(DateTime?) onEndDateChanged,
    required BuildContext context,
  }) {
    return Column(
      children: [
        buildModernDateField(
          label: tr('start_date'),
          date: startDate,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: startDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) onStartDateChanged(date);
          },
          context: context,
        ),
        const SizedBox(height: 16),
        buildModernDateField(
          label: tr('end_date'),
          date: endDate,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: endDate ?? startDate?.add(Duration(days: 7)) ?? DateTime.now(),
              firstDate: startDate ?? DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) onEndDateChanged(date);
          },
          context: context,
        ),
      ],
    );
  }

  /// Widget chọn người được gán
  static Widget buildAssigneeSelector({
    required List<String> selectedAssignees,
    required Function(List<String>) onAssigneesChanged,
    required Project? project,
    required BuildContext context,
  }) {
    // Logic lấy danh sách tất cả người dùng
    final List<Map<String, dynamic>> allUsers = [];
    if (project != null && project.createdBy['id'] != null) {
      allUsers.add({
        'id': project.createdBy['id'],
        'name': project.createdBy['name'] ?? tr('owner'),
        'email': project.createdBy['email'] ?? '',
        'avatar': project.createdBy['avatar'] ?? '',
        'avatarColor': project.createdBy['avatarColor'] ?? '#2196F3',
      });
    }
    for (var member in project?.members ?? []) {
      if (member.userId != project?.createdBy['id']) {
        allUsers.add({
          'id': member.userId,
          'name': member.userName ?? tr('user'),
          'email': member.userEmail ?? '',
          'avatar': member.avatar ?? '',
          'avatarColor': member.avatarColor ?? '#2196F3',
        });
      }
    }

    return SizedBox(
      height: 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddAssigneeButton(
            allUsers,
            selectedAssignees,
            onAssigneesChanged,
            context,
          ),
          const SizedBox(width: 16),
          if (selectedAssignees.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildSelectedAssigneesList(
                  allUsers,
                  selectedAssignees,
                  context,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildAddAssigneeButton(
    List<Map<String, dynamic>> allUsers,
    List<String> selectedAssignees,
    Function(List<String>) onAssigneesChanged,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => _showAssigneeBottomSheet(
        allUsers,
        selectedAssignees,
        onAssigneesChanged,
        context,
      ),
      child: DottedBorder(
        options: CircularDottedBorderOptions(
          color: Colors.grey,
          strokeWidth: 2,
          dashPattern: const [5, 5],
          padding: EdgeInsets.zero,
        ),
        child: SizedBox(
          height: 44,
          width: 44,
          child: Icon(Icons.add, color: Colors.grey.shade600),
        ),
      ),
    );
  }

  static Widget _buildSelectedAssigneesList(
    List<Map<String, dynamic>> allUsers,
    List<String> selectedAssignees,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final maxDisplay = 4;
    final totalAssignees = selectedAssignees.length;

    final displayCount = totalAssignees > maxDisplay
        ? maxDisplay
        : totalAssignees;
    final remaining = totalAssignees - displayCount;

    List<Widget> userWidgets = List.generate(displayCount, (index) {
      final userId = selectedAssignees[index];
      final user = allUsers.firstWhere(
        (u) => u['id'] == userId,
        orElse: () => {
          'id': '',
          'name': '?',
          'avatar': '',
          'avatarColor': '#9E9E9E',
        },
      );
      final String fullName = user['name'] as String? ?? 'User';
      final String firstName = fullName.trim().split(' ').first;
      return Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: (user['avatarColor'] as String).toColor(),
              backgroundImage:
                  user['avatar'] != null &&
                      (user['avatar'] as String).isNotEmpty
                  ? NetworkImage(user['avatar'] as String)
                  : null,
              child:
                  (user['avatar'] == null || (user['avatar'] as String).isEmpty)
                  ? Text(
                      (user['name'] as String).substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              firstName,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    });

    if (remaining > 0) {
      userWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: GlobalVariables.secondaryCoral,
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(' ', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: userWidgets,
    );
  }

  static void _showAssigneeBottomSheet(
    List<Map<String, dynamic>> allUsers,
    List<String> selectedAssignees,
    Function(List<String>) onAssigneesChanged,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? GlobalVariables.darkSurfaceCard
                  : GlobalVariables.surfaceCard,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        tr('select_assignees'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? GlobalVariables.darkTextPrimary
                              : GlobalVariables.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...allUsers.map((user) {
                        final isSelected = selectedAssignees.contains(
                          user['id'],
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: GestureDetector(
                            onTap: () {
                              setBottomSheetState(() {
                                List<String> newAssignees = List.from(
                                  selectedAssignees,
                                );
                                if (isSelected) {
                                  newAssignees.remove(user['id']);
                                } else {
                                  newAssignees.add(user['id']);
                                }
                                onAssigneesChanged(newAssignees);
                              });
                            },
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
                                      user['avatar'] == null ||
                                          user['avatar'].isEmpty
                                      ? Text(
                                          (user['name'] ?? 'U')
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['name'] ?? tr('unknown'),
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: isDarkMode
                                                  ? GlobalVariables
                                                        .darkTextPrimary
                                                  : GlobalVariables.textPrimary,
                                            ),
                                      ),
                                      if (user['email'] != null &&
                                          user['email'].isNotEmpty)
                                        Text(
                                          user['email'],
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: isDarkMode
                                                    ? GlobalVariables
                                                          .darkTextSecondary
                                                    : GlobalVariables
                                                          .textSecondary,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? GlobalVariables.primaryBlue
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? GlobalVariables.primaryBlue
                                          : (isDarkMode
                                                ? GlobalVariables
                                                      .darkBorderSecondary
                                                : GlobalVariables
                                                      .borderSecondary),
                                      width: 2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
