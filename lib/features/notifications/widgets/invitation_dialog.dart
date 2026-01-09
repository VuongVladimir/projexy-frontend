import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/notifications/services/invitation_service.dart';
import 'package:frontend/models/invitation.dart';
import 'package:intl/intl.dart';

class InvitationDialog extends StatefulWidget {
  final String invitationId;
  final VoidCallback onActionCompleted;

  const InvitationDialog({
    super.key,
    required this.invitationId,
    required this.onActionCompleted,
  });

  @override
  State<InvitationDialog> createState() => _InvitationDialogState();
}

class _InvitationDialogState extends State<InvitationDialog> {
  Invitation? _invitation;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadInvitation();
  }

  Future<void> _loadInvitation() async {
    setState(() => _isLoading = true);

    await InvitationService.getInvitationById(
      context: context,
      invitationId: widget.invitationId,
      onSuccess: (invitation) {
        if (mounted) {
          setState(() {
            _invitation = invitation;
            _isLoading = false;
          });
        }
      },
    );

    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            : _invitation == null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: GlobalVariables.errorRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy lời mời!',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: GlobalVariables.primaryBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.mail_rounded,
                                  color: GlobalVariables.primaryBlue,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lời mời dự án',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _invitation!.statusDisplayName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: _getStatusColor(_invitation!.status),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Project Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? GlobalVariables.darkSurfaceCard
                                  : GlobalVariables.surfaceCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode
                                    ? GlobalVariables.darkBorderPrimary
                                    : GlobalVariables.borderPrimary,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.folder_rounded,
                                      color: GlobalVariables.primaryBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Dự án',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDarkMode
                                            ? GlobalVariables.darkTextSecondary
                                            : GlobalVariables.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _invitation!.project?.title ?? 'N/A',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_invitation!.project?.description != null &&
                                    _invitation!.project!.description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _invitation!.project!.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDarkMode
                                          ? GlobalVariables.darkTextSecondary
                                          : GlobalVariables.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Inviter Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? GlobalVariables.darkSurfaceCard
                                  : GlobalVariables.surfaceCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode
                                    ? GlobalVariables.darkBorderPrimary
                                    : GlobalVariables.borderPrimary,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: _invitation!.invitedByUser?.avatarColor!.toColor(),
                                  backgroundImage: _invitation!.invitedByUser?.avatar != null && _invitation!.invitedByUser!.avatar!.isNotEmpty
                                      ? NetworkImage(_invitation!.invitedByUser!.avatar!)
                                      : null,
                                  child: _invitation!.invitedByUser?.avatar == null || _invitation!.invitedByUser!.avatar!.isEmpty
                                      ? Text(
                                          _invitation!.invitedByUser?.name != null && _invitation!.invitedByUser!.name.isNotEmpty
                                              ? _invitation!.invitedByUser!.name[0].toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            color: GlobalVariables.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Được mời bởi',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDarkMode
                                              ? GlobalVariables.darkTextSecondary
                                              : GlobalVariables.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        _invitation!.invitedByUser?.name ?? 'N/A',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_invitation!.invitedByUser?.email != null)
                                        Text(
                                          _invitation!.invitedByUser!.email,
                                          style: theme.textTheme.bodySmall?.copyWith(
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
                          ),

                          // Message from inviter
                          if (_invitation!.message != null && _invitation!.message!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: GlobalVariables.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: GlobalVariables.primaryBlue.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.format_quote_rounded,
                                        color: GlobalVariables.primaryBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Lời nhắn',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: GlobalVariables.primaryBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _invitation!.message!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: GlobalVariables.primaryBlue,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Date info
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: isDarkMode
                                    ? GlobalVariables.darkTextTertiary
                                    : GlobalVariables.textTertiary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Gửi lúc ${DateFormat('dd/MM/yyyy HH:mm').format(_invitation!.createdAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDarkMode
                                      ? GlobalVariables.darkTextTertiary
                                      : GlobalVariables.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          if (_invitation!.canAccept) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: _invitation!.daysUntilExpiry <= 2
                                      ? GlobalVariables.warningAmber
                                      : (isDarkMode
                                          ? GlobalVariables.darkTextTertiary
                                          : GlobalVariables.textTertiary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Còn ${_invitation!.daysUntilExpiry} ngày để chấp nhận',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _invitation!.daysUntilExpiry <= 2
                                        ? GlobalVariables.warningAmber
                                        : (isDarkMode
                                            ? GlobalVariables.darkTextTertiary
                                            : GlobalVariables.textTertiary),
                                    fontWeight: _invitation!.daysUntilExpiry <= 2
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Action buttons
                          if (_invitation!.canAccept) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isProcessing ? null : _declineInvitation,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: GlobalVariables.errorRed,
                                      side: BorderSide(color: GlobalVariables.errorRed),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: _isProcessing
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Từ chối'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isProcessing ? null : _acceptInvitation,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: GlobalVariables.successGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: _isProcessing
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Chấp nhận'),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Đóng'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return GlobalVariables.successGreen;
      case 'declined':
        return GlobalVariables.errorRed;
      case 'expired':
        return GlobalVariables.textTertiary;
      default:
        return GlobalVariables.warningAmber;
    }
  }

  Future<void> _acceptInvitation() async {
    setState(() => _isProcessing = true);

    await InvitationService.acceptInvitation(
      context: context,
      token: _invitation!.token,
      onSuccess: () {
        if (mounted) {
          Navigator.pop(context);
          widget.onActionCompleted();
        }
      },
    );

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _declineInvitation() async {
    setState(() => _isProcessing = true);

    await InvitationService.declineInvitation(
      context: context,
      token: _invitation!.token,
      onSuccess: () {
        if (mounted) {
          Navigator.pop(context);
          widget.onActionCompleted();
        }
      },
    );

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}

