import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/tasks/services/activity_log_service.dart';
import 'package:frontend/features/tasks/widgets/activity_log_item.dart';
import 'package:frontend/models/activity_log.dart';

/// Widget hiển thị Activity Log section trong Project Detail
/// Chỉ hiển thị project-level actions (đã filter ở backend)
class ProjectActivitySection extends StatefulWidget {
  final String projectId;

  const ProjectActivitySection({super.key, required this.projectId});

  @override
  State<ProjectActivitySection> createState() => ProjectActivitySectionState();
}

class ProjectActivitySectionState extends State<ProjectActivitySection> {
  List<ActivityLog> _activityLogs = [];
  bool _isLoading = true;
  bool _hasMore = false;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  void refreshActivity() {
    if (!mounted) return;
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _activityLogs = [];
    });

    await ActivityLogService.getProjectActivity(
      context: context,
      projectId: widget.projectId,
      page: 1,
      limit: 5,
      onSuccess: (logs, hasMore) {
        if (mounted) {
          setState(() {
            _activityLogs = logs;
            _hasMore = hasMore;
            _isLoading = false;
          });
        }
      },
    );

    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;

    await ActivityLogService.getProjectActivity(
      context: context,
      projectId: widget.projectId,
      page: nextPage,
      limit: 5,
      onSuccess: (logs, hasMore) {
        if (mounted) {
          setState(() {
            _activityLogs.addAll(logs);
            _hasMore = hasMore;
            _currentPage = nextPage;
            _isLoadingMore = false;
          });
        }
      },
    );

    if (mounted && _isLoadingMore) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          tr('activity'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? GlobalVariables.darkTextPrimary
                : GlobalVariables.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Content
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_activityLogs.isEmpty)
          _buildEmptyState(isDarkMode, theme)
        else
          _buildActivityList(isDarkMode),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 40,
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              tr('activity_no_logs'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(bool isDarkMode) {
    return Column(
      children: [
        ..._activityLogs.map(
          (log) => ActivityLogItem(log: log, isDarkMode: isDarkMode),
        ),
        // "View more" button
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _isLoadingMore
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _loadMore,
                    child: Text(
                      tr('activity_view_more'),
                      style: TextStyle(
                        color: GlobalVariables.primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}
