import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';

typedef InvitationEmailValidator = Future<String?> Function(String email);

class MemberInvitationForm extends StatefulWidget {
  final void Function(List<String> emails, String message) onSubmit;
  final void Function(List<String> emails, String message)? onEmailsChanged;
  final InvitationEmailValidator? validateEmailBeforeAdd;
  final bool showSubmitButton;
  final String submitButtonText;

  const MemberInvitationForm({
    super.key,
    required this.onSubmit,
    this.onEmailsChanged,
    this.validateEmailBeforeAdd,
    this.showSubmitButton = false,
    this.submitButtonText = 'Gửi lời mời',
  });

  @override
  State<MemberInvitationForm> createState() => _MemberInvitationFormState();
}

class _MemberInvitationFormState extends State<MemberInvitationForm> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  List<String> _invitedEmails = [];
  bool _isValidatingEmail = false;
  bool _isAddingEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showSingleSnackBar(String message, {required Color backgroundColor}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _addEmail(String email) async {
    if (_isAddingEmail) return;

    final trimmedEmail = email.trim().toLowerCase();

    // Kiểm tra email không rỗng
    if (trimmedEmail.isEmpty) {
      return;
    }

    // Validate email format
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmedEmail)) {
      _showSingleSnackBar(
        tr('validation_invalid_email', namedArgs: {'email': trimmedEmail}),
        backgroundColor: Colors.red,
      );
      return;
    }

    // Kiểm tra email đã tồn tại
    if (_invitedEmails.contains(trimmedEmail)) {
      _showSingleSnackBar(
        tr(
          'validation_email_already_added',
          namedArgs: {'email': trimmedEmail},
        ),
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isAddingEmail = true;
    });

    try {
      if (widget.validateEmailBeforeAdd != null) {
        setState(() {
          _isValidatingEmail = true;
        });

        final validationError = await widget.validateEmailBeforeAdd!(
          trimmedEmail,
        );

        if (!mounted) return;

        setState(() {
          _isValidatingEmail = false;
        });

        if (validationError != null && validationError.isNotEmpty) {
          _showSingleSnackBar(
            validationError,
            backgroundColor: GlobalVariables.warningAmber,
          );
          return;
        }
      }

      // Thêm email vào danh sách
      setState(() {
        _invitedEmails.add(trimmedEmail);
        _emailController.clear();
      });

      // Thông báo về thay đổi danh sách emails
      widget.onEmailsChanged?.call(
        _invitedEmails,
        _messageController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingEmail = false;
          _isValidatingEmail = false;
        });
      }
    }
  }

  void _removeEmail(String email) {
    setState(() {
      _invitedEmails.remove(email);
    });

    // Thông báo về thay đổi danh sách emails
    widget.onEmailsChanged?.call(
      _invitedEmails,
      _messageController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final maxChipWidth = MediaQuery.of(context).size.width * 0.7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tr('email_member'),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDarkMode
                ? GlobalVariables.darkTextPrimary
                : GlobalVariables.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? GlobalVariables.darkSurfaceCard
                : GlobalVariables.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: GlobalVariables.darkBorderPrimary.withValues(alpha: 0.5),
            ),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (value) {
              if (_isAddingEmail) return;
              _addEmail(value);
            },
            decoration: InputDecoration(
              hintText: tr('validation_enter_email'),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
              suffixIcon: IconButton(
                icon: _isValidatingEmail
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDarkMode
                              ? GlobalVariables.darkTextSecondary
                              : GlobalVariables.textSecondary,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                onPressed: (_isValidatingEmail || _isAddingEmail)
                    ? null
                    : () => _addEmail(_emailController.text),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Message for invitation
        Text(
          tr('invitation_message'),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDarkMode
                ? GlobalVariables.darkTextPrimary
                : GlobalVariables.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? GlobalVariables.darkSurfaceCard
                : GlobalVariables.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: GlobalVariables.darkBorderPrimary.withValues(alpha: 0.5),
            ),
          ),
          child: TextField(
            controller: _messageController,
            maxLines: 3,
            onChanged: (value) {
              // Thông báo về thay đổi message
              widget.onEmailsChanged?.call(_invitedEmails, value.trim());
            },
            decoration: InputDecoration(
              hintText: tr('add_message_introduce_project'),
              prefixIcon: Icon(
                Icons.message_outlined,
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        if (_invitedEmails.isNotEmpty) ...[
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tr('list_invited_emails')} (${_invitedEmails.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _invitedEmails
                    .map(
                      (email) => ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxChipWidth),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: GlobalVariables.primaryBlue.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: GlobalVariables.primaryBlue.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: GlobalVariables.primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Tooltip(
                                  message: email,
                                  child: Text(
                                    email,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: GlobalVariables.primaryBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _removeEmail(email),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: GlobalVariables.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],

        if (widget.showSubmitButton) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _invitedEmails.isEmpty
                  ? null
                  : () {
                      widget.onSubmit(
                        _invitedEmails,
                        _messageController.text.trim(),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalVariables.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(widget.submitButtonText),
            ),
          ),
        ],
      ],
    );
  }
}
