import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Scaffold;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../tutorial/presentation/tutorial_anchor.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _icons = <IconData>[
    CupertinoIcons.house,
    Icons.fitness_center_outlined,
    CupertinoIcons.square_favorites_alt,
    CupertinoIcons.chart_bar,
    CupertinoIcons.person_2,
  ];

  static const _activeIcons = <IconData>[
    CupertinoIcons.house_fill,
    Icons.fitness_center,
    CupertinoIcons.square_favorites_alt_fill,
    CupertinoIcons.chart_bar_fill,
    CupertinoIcons.person_2_fill,
  ];

  static const _labels = <String>[
    'Home',
    'Workouts',
    'Nutrition',
    'Progress',
    'Community',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: navigationShell,
      bottomNavigationBar: _CupertinoTabBar(
        selectedIndex: navigationShell.currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        icons: _icons,
        activeIcons: _activeIcons,
        labels: _labels,
      ),
    );
  }
}

class _CupertinoTabBar extends StatelessWidget {
  const _CupertinoTabBar({
    required this.selectedIndex,
    required this.onTap,
    required this.icons,
    required this.activeIcons,
    required this.labels,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<IconData> icons;
  final List<IconData> activeIcons;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: palette.background.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: palette.border),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: List.generate(icons.length, (index) {
                  final isSelected = index == selectedIndex;
                  // Tabs 1-4 host the tutorial spotlights for their feature
                  // step. Tab 0 (Home) doesn't get one — its features are
                  // highlighted on the dashboard itself.
                  final tutorialId = switch (index) {
                    1 => 'workouts_tab',
                    2 => 'nutrition_tab',
                    3 => 'progress_tab',
                    4 => 'community_tab',
                    _ => null,
                  };
                  final item = _NavItem(
                    icon: icons[index],
                    activeIcon: activeIcons[index],
                    label: labels[index],
                    isSelected: isSelected,
                    onTap: () => onTap(index),
                  );
                  return Expanded(
                    child: tutorialId == null
                        ? item
                        : TutorialAnchor(id: tutorialId, child: item),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isLight = CupertinoTheme.of(context).brightness == Brightness.light;
    final inactiveColor = isLight
        ? const Color(0xFF3C3C43)
        : palette.textSecondary;
    final color = isSelected ? palette.accent : inactiveColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
