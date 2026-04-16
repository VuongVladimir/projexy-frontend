import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/account/services/premium_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class PremiumUpgradeDialog extends StatefulWidget {
  const PremiumUpgradeDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PremiumUpgradeDialog(),
    );
  }

  @override
  State<PremiumUpgradeDialog> createState() => _PremiumUpgradeDialogState();
}

class _PremiumUpgradeDialogState extends State<PremiumUpgradeDialog> {
  String _selectedPlan = '12_months';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'key': '1_month',
      'titleKey': 'premium_plan_1_month',
      'price': 30000,
      'priceDisplayKey': 'premium_plan_1_month_price',
      'perMonthKey': 'premium_plan_1_month_per_month',
      'badgeKey': null,
      'savingsKey': null,
    },
    {
      'key': '6_months',
      'titleKey': 'premium_plan_6_months',
      'price': 150000,
      'priceDisplayKey': 'premium_plan_6_months_price',
      'perMonthKey': 'premium_plan_6_months_per_month',
      'badgeKey': null,
      'savingsKey': 'premium_plan_6_months_savings',
    },
    {
      'key': '12_months',
      'titleKey': 'premium_plan_12_months',
      'price': 200000,
      'priceDisplayKey': 'premium_plan_12_months_price',
      'perMonthKey': 'premium_plan_12_months_per_month',
      'badgeKey': 'premium_plan_best_value',
      'savingsKey': 'premium_plan_12_months_savings',
    },
  ];

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.group_outlined,
      'textKey': 'premium_feature_unlimited_members',
    },
    {
      'icon': Icons.account_tree_outlined,
      'textKey': 'premium_feature_unlimited_subtasks',
    },
    {
      'icon': Icons.link_outlined,
      'textKey': 'premium_feature_dependency_auto_scheduling',
    },
    {
      'icon': Icons.chat_bubble_outline,
      'textKey': 'premium_feature_private_project_chat',
    },
  ];

  Future<void> _handleCheckout() async {
    setState(() => _isLoading = true);

    final checkoutUrl = await PremiumService.createCheckout(
      context: context,
      planType: _selectedPlan,
    );

    if (checkoutUrl != null) {
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        await PremiumService.refreshUserPremiumStatus(context);
        if (mounted) Navigator.of(context).pop(true);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDarkMode ? GlobalVariables.darkSurfaceDialog : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(isDarkMode),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isDarkMode),
                  const SizedBox(height: 20),
                  _buildFeaturesList(isDarkMode),
                  const SizedBox(height: 24),
                  ..._plans.map((plan) => _buildPlanCard(plan, isDarkMode)),
                  const SizedBox(height: 20),
                  _buildCheckoutButton(isDarkMode),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDarkMode) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    const premiumTitleColor = Color(0xFF4A2A00);
    const premiumSubtitleColor = Color(0xFF6B3E09);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD46A),
            Color(0xFFFFCC5C),
            Color(0xFFFFC056),
            Color(0xFFFFB85A),
            Color(0xFFFFAD60),
          ],
          stops: [0.0, 0.36, 0.85, 0.95, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 3),
            child: SvgPicture.asset(
              'assets/images/premium_1.svg',
              width: 42,
              height: 42,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tr('premium_upgrade_title'),
            style: TextStyle(
              color: premiumTitleColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('premium_upgrade_subtitle'),
            style: TextStyle(
              color: premiumSubtitleColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(bool isDarkMode) {
    return Column(
      children: _features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: const Color(0xFFFFA11A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                tr(feature['textKey'] as String),
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isDarkMode) {
    final isSelected = _selectedPlan == plan['key'];
    final hasBadge = plan['badgeKey'] != null;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan['key'] as String),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(
                  0xFFFFA726,
                ).withValues(alpha: isDarkMode ? 0.2 : 0.08)
              : isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFA11A)
                : (isDarkMode
                      ? GlobalVariables.darkBorderPrimary
                      : GlobalVariables.borderPrimary),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFA11A)
                      : (isDarkMode
                            ? GlobalVariables.darkBorderSecondary
                            : GlobalVariables.borderSecondary),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFFFFA11A)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tr(plan['titleKey'] as String),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? GlobalVariables.darkTextPrimary
                              : GlobalVariables.textPrimary,
                        ),
                      ),
                      if (hasBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFC857),
                                Color(0xFFFFB74B),
                                Color(0xFFFFA34A),
                              ],
                              stops: [0.0, 0.58, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tr(plan['badgeKey'] as String),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (plan['savingsKey'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      tr(plan['savingsKey'] as String),
                      style: const TextStyle(
                        color: Color(0xFFFFA11A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tr(plan['priceDisplayKey'] as String),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : GlobalVariables.textPrimary,
                  ),
                ),
                Text(
                  tr(plan['perMonthKey'] as String),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? GlobalVariables.darkTextTertiary
                        : GlobalVariables.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(bool isDarkMode) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFA11A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tr('premium_checkout_now'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
