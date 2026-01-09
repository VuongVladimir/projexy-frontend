import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class ProjectFormWidgets {
  /// Widget chọn độ ưu tiên hiện đại
  static Widget buildModernPrioritySelector({
    required String selectedPriority,
    required Function(String) onPriorityChanged,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildPriorityButton(
            'Low',
            GlobalVariables.successGreen,
            selectedPriority,
            onPriorityChanged,
            context,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPriorityButton(
            'Medium',
            GlobalVariables.warningAmber,
            selectedPriority,
            onPriorityChanged,
            context,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPriorityButton(
            'High',
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
            tr(value.toLowerCase()),
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

  /// Widget chọn ngày hiện đại
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

  /// Widget nhập tags
  static Widget buildTagsInput({
    required TextEditingController controller,
    required Function(String) onTagAdded,
    required BuildContext context,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? GlobalVariables.darkSurfaceCard
            : GlobalVariables.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GlobalVariables.darkBorderPrimary.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onTagAdded,
        style: TextStyle(
          color: isDarkMode
              ? GlobalVariables.darkTextPrimary
              : GlobalVariables.textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: tr('enter_tags'),
          hintStyle: TextStyle(
            color: isDarkMode
                ? GlobalVariables.darkTextSecondary
                : GlobalVariables.textSecondary,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.label_outline_rounded,
            color: isDarkMode
                ? GlobalVariables.darkTextSecondary
                : GlobalVariables.textSecondary,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => onTagAdded(controller.text),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  /// Widget hiển thị tags
  static Widget buildTagsDisplay({
    required List<String> tags,
    required Function(String) onTagRemoved,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GlobalVariables.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: GlobalVariables.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tag,
                    style: TextStyle(
                      color: GlobalVariables.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onTagRemoved(tag),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: GlobalVariables.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
