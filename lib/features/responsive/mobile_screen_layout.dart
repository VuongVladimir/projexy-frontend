import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class MobileScreenLayout extends StatefulWidget {
  const MobileScreenLayout({super.key});

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends State<MobileScreenLayout>
    with SingleTickerProviderStateMixin {
  int _page = 0;
  late PageController pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
    _animationController.dispose();
  }

  void navigationTapped(int page) {
    // Thêm hiệu ứng animation khi chuyển trang
    _animationController.reset();
    _animationController.forward();
    pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Danh sách các nhãn tương ứng với các biểu tượng
    final List<String> labels = [
      'home'.tr(),
      'tasks'.tr(),
      'messages'.tr(),
      'account'.tr(),
    ];

    // Danh sách các biểu tượng
    final List<IconData> icons = [
      Symbols.home_filled,
      Symbols.list_alt_check,
      Symbols.sms,
      Symbols.manage_accounts,
    ];

    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
        children: bottomBarItems,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: GlobalVariables.getNavigationBackground(isDarkMode),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).shadowColor.withValues(alpha: isDarkMode ? 0.16 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDarkMode
                  ? GlobalVariables.darkBorderPrimary
                  : GlobalVariables.borderPrimary,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(icons.length, (index) {
                bool isSelected = _page == index;
                return GestureDetector(
                  onTap: () => navigationTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 16.0 : 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GlobalVariables.primaryBlue
                          : (isDarkMode
                                ? GlobalVariables.darkBackgroundElevated
                                      .withValues(alpha: 0.72)
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[index],
                          color: isSelected
                              ? GlobalVariables.white
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                          weight: isSelected ? 660 : 600,
                          size: 24,
                          fill: isSelected ? 1 : 0,
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Text(
                            labels[index],
                            style: TextStyle(
                              color: GlobalVariables.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
