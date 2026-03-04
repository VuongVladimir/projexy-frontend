import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/models/activity_log.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// Widget hiển thị một Activity Log entry
/// Không có container/viền - hiển thị dạng timeline nhẹ nhàng
class ActivityLogItem extends StatelessWidget {
  final ActivityLog log;
  final bool isDarkMode;

  const ActivityLogItem({
    super.key,
    required this.log,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actor avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: log.actorAvatarColor.toColor(),
            backgroundImage: log.actorAvatar.isNotEmpty
                ? NetworkImage(log.actorAvatar)
                : null,
            child: log.actorAvatar.isEmpty
                ? Text(
                    log.actorName.isNotEmpty
                        ? log.actorName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action description + time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDescription(context)),
                    const SizedBox(width: 8),
                  ],
                ),

                if (log.action == 'task_completed' ||
                    log.action == 'subtask_completed') ...[
                  const SizedBox(height: 4),
                  Icon(
                    Symbols.check_circle_rounded,
                    size: 21,
                    weight: 900,
                    color: GlobalVariables.successGreenLight,
                  ),
                ],

                // Old/New value (cho update actions)
                if (_shouldShowValues()) ...[
                  const SizedBox(height: 4),
                  _buildValueChange(context),
                ],
                // Extra info (assigned users, etc.)
                if (_shouldShowExtraInfo()) ...[
                  const SizedBox(height: 4),
                  _buildExtraInfo(context),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(context, log.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? GlobalVariables.darkTextTertiary
                        : GlobalVariables.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final text = _getDescriptionText();
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: isDarkMode
            ? GlobalVariables.darkTextSecondary
            : GlobalVariables.textSecondary,
        height: 1.3,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getDescriptionText() {
    final actor = log.actorName;
    final meta = log.metadata;

    switch (log.action) {
      case 'task_updated':
      case 'project_updated':
        final fieldKey = log.field != null
            ? tr('activity_field_${log.field}')
            : '';
        return log.action == 'task_updated'
            ? tr(
                'activity_task_updated',
                namedArgs: {'actor': actor, 'field': fieldKey},
              )
            : tr(
                'activity_project_updated',
                namedArgs: {'actor': actor, 'field': fieldKey},
              );

      case 'task_created':
        return tr(
          'activity_task_created',
          namedArgs: {
            'actor': actor,
            'taskTitle': _truncate(meta?['taskTitle'] ?? '', 30),
          },
        );

      case 'task_deleted':
        return tr(
          'activity_task_deleted',
          namedArgs: {
            'actor': actor,
            'taskTitle': _truncate(meta?['taskTitle'] ?? '', 30),
          },
        );

      case 'subtask_created':
        return tr(
          'activity_subtask_created',
          namedArgs: {
            'actor': actor,
            'subtaskTitle': _truncate(meta?['subtaskTitle'] ?? '', 30),
          },
        );

      case 'subtask_deleted':
        return tr(
          'activity_subtask_deleted',
          namedArgs: {
            'actor': actor,
            'subtaskTitle': _truncate(meta?['subtaskTitle'] ?? '', 30),
          },
        );

      case 'task_completed':
        return tr(
          'activity_task_completed',
          namedArgs: {
            'actor': actor,
            'taskTitle': _truncate(meta?['taskTitle'] ?? '', 30),
          },
        );

      case 'task_incompleted':
        return tr(
          'activity_task_incompleted',
          namedArgs: {
            'actor': actor,
            'taskTitle': _truncate(meta?['taskTitle'] ?? '', 30),
          },
        );

      case 'subtask_completed':
        return tr(
          'activity_subtask_completed',
          namedArgs: {
            'actor': actor,
            'subtaskTitle': _truncate(meta?['subtaskTitle'] ?? '', 30),
          },
        );

      case 'subtask_incompleted':
        return tr(
          'activity_subtask_incompleted',
          namedArgs: {
            'actor': actor,
            'subtaskTitle': _truncate(meta?['subtaskTitle'] ?? '', 30),
          },
        );

      case 'task_assigned':
        return tr('activity_task_assigned', namedArgs: {'actor': actor});

      case 'dependency_added':
        return tr(
          'activity_dependency_added',
          namedArgs: {
            'actor': actor,
            'predecessorTitle': _truncate(meta?['predecessorTitle'] ?? '', 20),
            'successorTitle': _truncate(meta?['successorTitle'] ?? '', 20),
          },
        );

      case 'dependency_shifted':
        return tr(
          'activity_dependency_shifted',
          namedArgs: {
            'actor': actor,
            'deltaDays': (meta?['deltaDays'] ?? 0).toString(),
            'predecessorTitle': _truncate(meta?['predecessorTitle'] ?? '', 20),
            'successorTitle': _truncate(meta?['successorTitle'] ?? '', 20),
          },
        );

      case 'dependency_removed':
        return tr(
          'activity_dependency_removed',
          namedArgs: {
            'actor': actor,
            'predecessorTitle': _truncate(meta?['predecessorTitle'] ?? '', 20),
            'successorTitle': _truncate(meta?['successorTitle'] ?? '', 20),
          },
        );

      case 'task_shifted':
        return tr(
          'activity_task_shifted',
          namedArgs: {
            'actor': actor,
            'deltaDays': (meta?['deltaDays'] ?? 0).toString(),
          },
        );

      case 'attachment_uploaded':
        return tr(
          'activity_attachment_uploaded',
          namedArgs: {
            'actor': actor,
            'fileType': meta?['fileType'] ?? 'file',
            'fileName': _truncate(meta?['fileName'] ?? '', 25),
          },
        );

      case 'attachment_deleted':
        return tr(
          'activity_attachment_deleted',
          namedArgs: {
            'actor': actor,
            'fileType': meta?['fileType'] ?? 'file',
            'fileName': _truncate(meta?['fileName'] ?? '', 25),
          },
        );

      case 'comment_added':
        return tr('activity_comment_added', namedArgs: {'actor': actor});

      case 'member_added':
        return tr(
          'activity_member_added',
          namedArgs: {
            'actor': actor,
            'memberName':
                meta?['memberName'] ?? log.targetUserName ?? 'Unknown',
          },
        );

      case 'member_removed':
        return tr(
          'activity_member_removed',
          namedArgs: {
            'actor': actor,
            'memberName':
                meta?['memberName'] ?? log.targetUserName ?? 'Unknown',
          },
        );

      case 'role_updated':
        return tr(
          'activity_role_updated',
          namedArgs: {
            'actor': actor,
            'targetUser': log.targetUserName ?? 'Unknown',
          },
        );

      case 'permissions_updated':
        return tr(
          'activity_permissions_updated',
          namedArgs: {
            'actor': actor,
            'targetUser': log.targetUserName ?? 'Unknown',
          },
        );

      case 'project_shifted':
        return tr(
          'activity_project_shifted',
          namedArgs: {
            'actor': actor,
            'deltaDays': (meta?['deltaDays'] ?? 0).toString(),
          },
        );

      default:
        return '$actor performed ${log.action}';
    }
  }

  bool _shouldShowValues() {
    return (log.action == 'task_updated' || log.action == 'project_updated') &&
        (log.oldValue != null || log.newValue != null) &&
        log.field !=
            'description'; // Description quá dài, không hiển thị chi tiết
  }

  Widget _buildValueChange(BuildContext context) {
    final oldVal = _formatValue(log.oldValue, log.field);
    final newVal = _formatValue(log.newValue, log.field);

    return Row(
      children: [
        // Old value
        if (oldVal.isNotEmpty)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: GlobalVariables.secondaryCoral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _truncate(oldVal, 30),
                style: TextStyle(
                  fontSize: 12,
                  color: GlobalVariables.secondaryCoral,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        if (oldVal.isNotEmpty && newVal.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
          ),
        // New value
        if (newVal.isNotEmpty)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: GlobalVariables.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _truncate(newVal, 30),
                style: TextStyle(
                  fontSize: 12,
                  color: GlobalVariables.primaryBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  bool _shouldShowExtraInfo() {
    if (log.action == 'task_assigned') {
      final meta = log.metadata;
      final assigned = meta?['assignedUsers'] as List?;
      final removed = meta?['removedUsers'] as List?;
      return (assigned != null && assigned.isNotEmpty) ||
          (removed != null && removed.isNotEmpty);
    }
    if (log.action == 'role_updated' &&
        log.oldValue != null &&
        log.newValue != null) {
      return true;
    }
    return false;
  }

  Widget _buildExtraInfo(BuildContext context) {
    if (log.action == 'task_assigned') {
      return _buildAssignmentInfo();
    }
    if (log.action == 'role_updated') {
      return _buildValueChange(context);
    }
    return const SizedBox.shrink();
  }

  Widget _buildAssignmentInfo() {
    final meta = log.metadata;
    final assigned =
        (meta?['assignedUsers'] as List?)
            ?.map((u) => u['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList() ??
        [];
    final removed =
        (meta?['removedUsers'] as List?)
            ?.map((u) => u['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (assigned.isNotEmpty)
          Text(
            tr(
              'activity_assigned_users',
              namedArgs: {'users': assigned.join(', ')},
            ),
            style: TextStyle(fontSize: 12, color: GlobalVariables.primaryBlue),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (removed.isNotEmpty)
          Text(
            tr(
              'activity_removed_users',
              namedArgs: {'users': removed.join(', ')},
            ),
            style: TextStyle(
              fontSize: 12,
              color: GlobalVariables.secondaryCoral,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  String _formatValue(dynamic value, String? field) {
    if (value == null) return '';

    final str = value.toString();
    if (str.isEmpty || str == 'null') return '';

    // Format dates
    if (field == 'startDate' || field == 'endDate') {
      try {
        final date = DateTime.parse(str);
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {
        return str;
      }
    }

    // Format status
    if (field == 'status') {
      return _formatStatus(str);
    }

    // Format priority
    if (field == 'priority') {
      return _formatPriority(str);
    }

    return str;
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'todo':
        return tr('todo');
      case 'in-progress':
        return tr('in_progress');
      case 'completed':
        return tr('completed');
      default:
        return status;
    }
  }

  String _formatPriority(String priority) {
    switch (priority) {
      case 'low':
        return tr('low');
      case 'medium':
        return tr('medium');
      case 'high':
        return tr('high');
      default:
        return priority;
    }
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _formatTimestamp(BuildContext context, DateTime dateTime) {
    final locale = context.locale.toString();
    final localTime = dateTime.toUtc().add(const Duration(hours: 7));
    final nowLocal = DateTime.now().toUtc().add(const Duration(hours: 7));
    final sameYear = localTime.year == nowLocal.year;
    final pattern = sameYear ? 'd MMM, H:mm' : 'd MMM yyyy, H:mm';
    return DateFormat(pattern, locale).format(localTime);
  }
}
