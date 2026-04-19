import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/account/screens/feedback_history_screen.dart';
import 'package:frontend/features/account/services/account_service.dart';

class HelpSupportScreen extends StatefulWidget {
  static const String routeName = '/help-support';

  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final AccountService _accountService = AccountService();

  String _selectedType = 'bug';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _feedbackTypeLabel(String type) {
    switch (type) {
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

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final isSuccess = await _accountService.submitFeedback(
      context: context,
      type: _selectedType,
      subject: _subjectController.text,
      message: _messageController.text,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (isSuccess) {
      Navigator.pop(context);
      showSnackBar(context, tr('feedback_submit_success'));
    }
  }

  InputDecoration _inputDecoration(String hintText) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: tr('help_support_title'),
        actions: [
          IconButton(
            tooltip: tr('feedback_history_title'),
            onPressed: () {
              Navigator.pushNamed(context, FeedbackHistoryScreen.routeName);
            },
            icon: const Icon(Icons.history_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('help_support_description'),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr('feedback_type'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const ['bug', 'payment', 'feature_request', 'other'].map(
                  (type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(_feedbackTypeLabel(type)),
                    );
                  },
                ).toList(),
                decoration: _inputDecoration(''),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              Text(
                tr('feedback_subject'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                maxLength: 150,
                decoration: _inputDecoration(tr('feedback_subject_hint')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('validation_feedback_subject_required');
                  }
                  if (value.trim().length < 5) {
                    return tr('validation_feedback_subject_min');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                tr('feedback_message'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLength: 3000,
                minLines: 5,
                maxLines: 9,
                decoration: _inputDecoration(tr('feedback_message_hint')),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return tr('validation_feedback_message_required');
                  }
                  if (value.trim().length < 10) {
                    return tr('validation_feedback_message_min');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: GlobalVariables.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          tr('feedback_submit'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
