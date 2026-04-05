import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _icons = <IconData>[
    Icons.home_outlined,
    Icons.fitness_center_outlined,
    Icons.restaurant_outlined,
    Icons.bar_chart_outlined,
    Icons.chat_bubble_outline,
  ];

  static const _activeIcons = <IconData>[
    Icons.home,
    Icons.fitness_center,
    Icons.restaurant,
    Icons.bar_chart,
    Icons.chat_bubble,
  ];

  static const _labels = <String>[
    'Home',
    'Workouts',
    'Nutrition',
    'Progress',
    'AI Coach',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomNavBar(
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

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
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
    return Container(
      color: AppColors.bottomNavBar,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: List.generate(icons.length, (index) {
              final isSelected = index == selectedIndex;
              return Expanded(
                child: _NavItem(
                  icon: icons[index],
                  activeIcon: activeIcons[index],
                  label: labels[index],
                  isSelected: isSelected,
                  onTap: () => onTap(index),
                ),
              );
            }),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isSelected ? 6 : 0,
              height: isSelected ? 6 : 0,
              decoration: const BoxDecoration(
                color: AppColors.lime,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
