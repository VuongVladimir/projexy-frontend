// frontend/lib/features/account/screens/setting_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingScreen extends StatelessWidget {
  static const String routeName = '/settings';
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'settings'.tr()),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Section
              _buildSectionHeader(context, tr('theme')),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildThemeOption(context),
              ),
              const SizedBox(height: 24),

              // Language Section
              _buildSectionHeader(context, tr('language')),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildLanguageOption(context),
              ),
              const SizedBox(height: 24),
              // About Section
              _buildSectionHeader(context, tr('about')),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingItem(
                      context,
                      icon: Symbols.mobile_3,
                      title: 'version'.tr(),
                      subtitle: 'v1.0.0',
                      onTap: () {},
                    ),
                    Divider(
                      height: 1,
                      thickness: 2,
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                    ),
                    _buildSettingItem(
                      context,
                      icon: Symbols.visibility,
                      title: 'privacy_policy'.tr(),
                      subtitle: 'view_privacy_policy'.tr(),
                      onTap: () {
                        // TODO: Navigate to privacy policy
                      },
                    ),
                    Divider(
                      height: 1,
                      thickness: 2,
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                    ),
                    _buildSettingItem(
                      context,
                      icon: Symbols.info,
                      title: 'credits'.tr(),
                      subtitle: 'attributions_licenses'.tr(),
                      onTap: () {
                        Navigator.pushNamed(context, '/credits');
                      },
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return RadioGroup<ThemeMode>(
          groupValue: themeProvider.themeMode,
          onChanged: (value) {
            if (value != null) {
              themeProvider.setTheme(value);
            }
          },
          child: Column(
            children: [
              _buildThemeRadioTile(
                context,
                title: 'light_theme'.tr(),
                subtitle: 'use_light_theme'.tr(),
                icon: Symbols.light_mode,
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setTheme(value);
                  }
                },
              ),
              Divider(
                height: 1,
                thickness: 2,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
              _buildThemeRadioTile(
                context,
                title: 'dark_theme'.tr(),
                subtitle: 'use_dark_theme'.tr(),
                icon: Symbols.dark_mode,
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setTheme(value);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context) {
    final currentLocale = context.locale;

    return RadioGroup<Locale>(
      groupValue: currentLocale,
      onChanged: (value) {
        if (value != null) {
          context.setLocale(value);
        }
      },
      child: Column(
        children: [
          _buildLanguageRadioTile(
            context,
            title: 'english'.tr(),
            subtitle: 'English',
            icon: Symbols.language,
            value: const Locale('en'),
            groupValue: currentLocale,
            onChanged: (value) {
              if (value != null) {
                context.setLocale(value);
              }
            },
          ),
          Divider(
            height: 1,
            thickness: 2,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
          _buildLanguageRadioTile(
            context,
            title: 'vietnamese'.tr(),
            subtitle: 'Tiếng Việt',
            icon: Symbols.language,
            value: const Locale('vi'),
            groupValue: currentLocale,
            onChanged: (value) {
              if (value != null) {
                context.setLocale(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageRadioTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Locale value,
    required Locale groupValue,
    required Function(Locale?) onChanged,
  }) {
    final isSelected = value == groupValue;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isSelected
              ? GlobalVariables.backgroundBlueLight
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.5),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? GlobalVariables.white
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          size: 26,
          fill: isSelected ? 1 : 0,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      trailing: Radio<Locale>(
        value: value,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => onChanged(value),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildThemeRadioTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
    required Function(ThemeMode?) onChanged,
  }) {
    final isSelected = value == groupValue;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isSelected
              ? GlobalVariables.backgroundBlueLight
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.5),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? GlobalVariables.white
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          size: 26,
          fill: isSelected ? 1 : 0,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      trailing: Radio<ThemeMode>(
        value: value,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => onChanged(value),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: GlobalVariables.backgroundBlueLight,
          borderRadius: BorderRadius.circular(8.5),
        ),
        child: Icon(icon, color: GlobalVariables.white, size: 26, fill: 1),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
