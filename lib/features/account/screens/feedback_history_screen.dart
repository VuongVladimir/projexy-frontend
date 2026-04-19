import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/account/services/account_service.dart';
import 'package:frontend/models/feedback_item.dart';
import 'package:intl/intl.dart';

class FeedbackHistoryScreen extends StatefulWidget {
  static const String routeName = '/feedback-history';

  const FeedbackHistoryScreen({super.key});

  @override
  State<FeedbackHistoryScreen> createState() => _FeedbackHistoryScreenState();
}

class _FeedbackHistoryScreenState extends State<FeedbackHistoryScreen> {
  final AccountService _accountService = AccountService();

  static const int _pageSize = 20;

  List<FeedbackItem> _feedbacks = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String _selectedType = 'all';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _reloadFeedbacks();
  }

  Future<void> _reloadFeedbacks() async {
    setState(() => _isLoading = true);
    _page = 1;
    await _fetchFeedbackPage(reset: true);
  }

  Future<void> _fetchFeedbackPage({required bool reset}) async {
    final response = await _accountService.getMyFeedbacks(
      context: context,
      page: _page,
      limit: _pageSize,
      type: _selectedType,
      status: _selectedStatus,
    );

    if (!mounted) return;

    final fetched = (response['feedbacks'] as List<FeedbackItem>?) ?? const [];
    final pagination =
        (response['pagination'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final currentPage = (pagination['current'] as num?)?.toInt() ?? _page;
    final totalPages = (pagination['pages'] as num?)?.toInt() ?? currentPage;
    final hasMore = totalPages > currentPage;

    setState(() {
      if (reset) {
        _feedbacks = fetched;
      } else {
        _feedbacks.addAll(fetched);
      }

      _hasMore = hasMore;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
      _page += 1;
    });

    await _fetchFeedbackPage(reset: false);
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'all':
        return tr('feedback_all_types');
      case 'bug':
        return tr('feedback_type_bug');
      case 'payment':
        return tr('feedback_type_payment');
      case 'feature_request':
        return tr('feedback_type_feature_request');
      default:
        return tr('feedback_type_other');
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'all':
        return tr('feedback_all_statuses');
      case 'open':
        return tr('feedback_status_open');
      case 'in_progress':
        return tr('feedback_status_in_progress');
      case 'resolved':
        return tr('feedback_status_resolved');
      case 'closed':
        return tr('feedback_status_closed');
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return GlobalVariables.infoBlue;
      case 'in_progress':
        return GlobalVariables.warningAmber;
      case 'resolved':
        return GlobalVariables.successGreen;
      case 'closed':
        return GlobalVariables.textTertiary;
      default:
        return GlobalVariables.textTertiary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'bug':
        return Icons.bug_report_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'feature_request':
        return Icons.lightbulb_outline;
      default:
        return Icons.support_agent_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  void _showFeedbackDetails(FeedbackItem feedback) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDarkMode
            ? GlobalVariables.darkSurfaceDialog
            : Colors.white,
        title: Text(
          tr('feedback_details_title'),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDarkMode
                ? GlobalVariables.darkTextPrimary
                : GlobalVariables.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                feedback.subject,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildDetailItem(
                tr('feedback_type'),
                _typeLabel(feedback.type),
                isDarkMode,
              ),
              _buildDetailItem(
                tr('feedback_status_label'),
                _statusLabel(feedback.status),
                isDarkMode,
              ),
              _buildDetailItem(
                tr('feedback_submitted_at'),
                _formatDate(feedback.createdAt),
                isDarkMode,
              ),
              if (feedback.resolvedAt != null)
                _buildDetailItem(
                  tr('feedback_resolved_at'),
                  _formatDate(feedback.resolvedAt!),
                  isDarkMode,
                ),
              const SizedBox(height: 6),
              Text(
                feedback.message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDarkMode
                      ? GlobalVariables.darkTextSecondary
                      : GlobalVariables.textSecondary,
                ),
              ),
              if (feedback.adminNote.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  tr('feedback_admin_note'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : GlobalVariables.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? GlobalVariables.darkBackgroundElevated
                        : GlobalVariables.backgroundSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    feedback.adminNote,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDarkMode
                          ? GlobalVariables.darkTextSecondary
                          : GlobalVariables.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode
                ? GlobalVariables.darkTextSecondary
                : GlobalVariables.textSecondary,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 64,
            color: isDarkMode
                ? GlobalVariables.darkTextTertiary
                : GlobalVariables.textTertiary,
          ),
          const SizedBox(height: 14),
          Text(
            tr('feedback_history_empty'),
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDarkMode) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDarkMode
          ? GlobalVariables.darkSurfaceCard
          : GlobalVariables.surfaceCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              isExpanded: true,
              decoration: inputDecoration.copyWith(
                labelText: tr('feedback_filter_type'),
              ),
              items: const ['all', 'bug', 'payment', 'feature_request', 'other']
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        _typeLabel(type),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _selectedType = value);
                await _reloadFeedbacks();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              isExpanded: true,
              decoration: inputDecoration.copyWith(
                labelText: tr('feedback_filter_status'),
              ),
              items: const ['all', 'open', 'in_progress', 'resolved', 'closed']
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        _statusLabel(status),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _selectedStatus = value);
                await _reloadFeedbacks();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: OutlinedButton(
          onPressed: _loadMore,
          child: Text(tr('feedback_load_more')),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackItem feedback, bool isDarkMode) {
    final statusColor = _statusColor(feedback.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showFeedbackDetails(feedback),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDarkMode
                ? GlobalVariables.darkSurfaceCard
                : GlobalVariables.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDarkMode
                  ? GlobalVariables.darkBorderPrimary
                  : GlobalVariables.borderPrimary,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _typeIcon(feedback.type),
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? GlobalVariables.darkTextPrimary
                            : GlobalVariables.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_typeLabel(feedback.type)} · ${_formatDate(feedback.createdAt)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDarkMode
                            ? GlobalVariables.darkTextTertiary
                            : GlobalVariables.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      feedback.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDarkMode
                            ? GlobalVariables.darkTextSecondary
                            : GlobalVariables.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _statusLabel(feedback.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      appBar: CustomAppBar(title: tr('feedback_history_title')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(isDarkMode),
                Expanded(
                  child: _feedbacks.isEmpty
                      ? _buildEmptyState(isDarkMode)
                      : RefreshIndicator(
                          onRefresh: _reloadFeedbacks,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _feedbacks.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              if (index >= _feedbacks.length) {
                                return _buildLoadMoreFooter();
                              }
                              return _buildFeedbackCard(
                                _feedbacks[index],
                                isDarkMode,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
