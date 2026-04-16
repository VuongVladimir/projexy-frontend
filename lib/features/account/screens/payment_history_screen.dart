import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/account/services/premium_service.dart';
import 'package:frontend/models/payment_history.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentHistoryScreen extends StatefulWidget {
  static const String routeName = '/payment-history';
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<PaymentHistory> _payments = [];
  bool _isLoading = true;
  // ignore: unused_field
  int _total = 0;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    await PremiumService.getPaymentHistory(
      context: context,
      page: _page,
      onSuccess: (payments, total) {
        if (mounted) {
          setState(() {
            _payments = payments;
            _total = total;
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

    return Scaffold(
      backgroundColor: isDarkMode
          ? GlobalVariables.darkBackgroundPrimary
          : GlobalVariables.backgroundPrimary,
      appBar: CustomAppBar(title: tr('payment_history_title')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
          ? _buildEmpty(isDarkMode)
          : RefreshIndicator(
              onRefresh: _loadPayments,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildPaymentCard(_payments[index], isDarkMode),
              ),
            ),
    );
  }

  Widget _buildEmpty(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: isDarkMode
                ? GlobalVariables.darkTextTertiary
                : GlobalVariables.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            tr('payment_history_empty'),
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(PaymentHistory payment) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final canOpenCheckout =
        payment.status == 'pending' &&
        payment.checkoutUrl != null &&
        payment.checkoutUrl!.isNotEmpty;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDarkMode
            ? GlobalVariables.darkSurfaceDialog
            : Colors.white,
        title: Text(
          tr('payment_history_detail_title'),
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
              _buildDetailItem(
                tr('payment_history_order_code'),
                payment.orderCode.toString(),
                isDarkMode,
              ),
              _buildDetailItem(
                tr('payment_history_plan'),
                payment.planDisplayName,
                isDarkMode,
              ),
              _buildDetailItem(
                tr('payment_history_amount'),
                payment.formattedAmount,
                isDarkMode,
              ),
              _buildDetailItem(
                tr('payment_history_status'),
                payment.statusDisplayName,
                isDarkMode,
              ),
              _buildDetailItem(
                tr('payment_history_created_time'),
                DateFormat('dd/MM/yyyy HH:mm:ss').format(payment.createdAt),
                isDarkMode,
              ),
              if (payment.paidAt != null)
                _buildDetailItem(
                  tr('payment_history_paid_time'),
                  DateFormat('dd/MM/yyyy HH:mm:ss').format(payment.paidAt!),
                  isDarkMode,
                ),
              if (payment.payosTransactionId != null &&
                  payment.payosTransactionId!.isNotEmpty)
                _buildDetailItem(
                  tr('payment_history_payos_transaction_id'),
                  payment.payosTransactionId!,
                  isDarkMode,
                ),
              if (canOpenCheckout)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InkWell(
                    onTap: () async {
                      final checkoutUri = Uri.tryParse(payment.checkoutUrl!);
                      if (checkoutUri == null) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tr('payment_history_invalid_checkout_url'),
                            ),
                          ),
                        );
                        return;
                      }

                      if (await canLaunchUrl(checkoutUri)) {
                        await launchUrl(
                          checkoutUri,
                          mode: LaunchMode.externalApplication,
                        );
                        return;
                      }

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr('payment_history_cannot_open_checkout_url'),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF6A00).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.open_in_new,
                            color: Color(0xFFFF6A00),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr('payment_history_reopen_checkout'),
                              style: TextStyle(
                                color: isDarkMode
                                    ? GlobalVariables.darkTextPrimary
                                    : GlobalVariables.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
      padding: const EdgeInsets.only(bottom: 8),
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
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentHistory payment, bool isDarkMode) {
    Color statusColor;
    IconData statusIcon;
    switch (payment.status) {
      case 'paid':
        statusColor = GlobalVariables.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = GlobalVariables.errorRed;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
        statusColor = GlobalVariables.warningAmber;
        statusIcon = Icons.hourglass_top;
        break;
      default:
        statusColor = GlobalVariables.textTertiary;
        statusIcon = Icons.help_outline;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showPaymentDetails(payment),
        child: Container(
          padding: const EdgeInsets.all(16),
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.planDisplayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? GlobalVariables.darkTextPrimary
                            : GlobalVariables.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? GlobalVariables.darkTextTertiary
                            : GlobalVariables.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    payment.formattedAmount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode
                          ? GlobalVariables.darkTextPrimary
                          : GlobalVariables.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      payment.statusDisplayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
