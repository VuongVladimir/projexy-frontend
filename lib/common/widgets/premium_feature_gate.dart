import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/account/widgets/premium_upgrade_dialog.dart';

class PremiumFeatureGate {
  static Future<void> show(
    BuildContext context, {
    required String feature,
    String? description,
  }) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDarkMode
            ? GlobalVariables.darkSurfaceDialog
            : Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/premium_1.svg',
              width: 36,
              height: 36,
            ),

            const SizedBox(height: 16),
            Text(
              tr('premium_feature_gate_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description ??
                  tr(
                    'premium_feature_gate_default_description',
                    namedArgs: {'feature': feature},
                  ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  PremiumUpgradeDialog.show(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA11A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  tr('premium_feature_gate_upgrade_now'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                tr('premium_feature_gate_later'),
                style: TextStyle(
                  color: isDarkMode
                      ? GlobalVariables.darkTextTertiary
                      : GlobalVariables.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
