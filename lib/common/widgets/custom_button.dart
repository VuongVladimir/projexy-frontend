// frontend/lib/common/widgets/custom_button.dart
import 'package:flutter/material.dart';
import '../constants/global_variables.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    // Determine default colors based on theme if not provided
    final defaultBackgroundColor = outlined
        ? Colors.transparent
        : (backgroundColor ?? Theme.of(context).colorScheme.primary);
    
    final defaultTextColor = outlined
        ? Theme.of(context).colorScheme.primary
        : (textColor ?? Theme.of(context).colorScheme.onPrimary);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: outlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: defaultTextColor,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _buildButtonContent(context, defaultTextColor),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: defaultBackgroundColor,
                foregroundColor: defaultTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.3),
              ),
              child: _buildButtonContent(context, defaultTextColor),
            ),
    );
  }

  Widget _buildButtonContent(BuildContext context, Color textColor) {
    return isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: textColor,
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          );
  }
}