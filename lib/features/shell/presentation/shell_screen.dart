import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Scaffold;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/tactical_surface.dart';
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
      backgroundColor: palette.scaffold,
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
    // Flat tonal chrome (the Quiet Chrome rule): near-opaque ink with a
    // hairline top rule — no blur material. Tab labels ride Dynamic Type but
    // clamp at 1.3× (mirroring UIKit tab bars) so the fixed-height bar never
    // clips at accessibility sizes.
    return Container(
      decoration: BoxDecoration(
        color: palette.background.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: palette.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
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
                  index: index,
                  count: icons.length,
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
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    // Field Manual nav states: active tab wears the live accent (brass on
    // the default issue), inactive tabs sit in tertiary structure — olive on
    // the Field Manual, classic gray on legacy packs (DESIGN.md §Navigation).
    final color = isSelected ? palette.accent : palette.textTertiary;
    // Active tab wears the accent halo on a HUD skin (Night Ops); empty on
    // every other theme, so the tab bar is byte-identical there.
    final glow = isSelected ? skinAccentTextShadows(palette.accent) : null;
    return Semantics(
      button: true,
      selected: isSelected,
      // Spoken position context, matching the native tab-bar pattern
      // ("Home, tab, 1 of 5") so VoiceOver users know the destination count.
      label: '$label, tab, ${index + 1} of $count',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: 24,
                shadows: glow,
              ),
              const SizedBox(height: 3),
              Text(
                // Condensed uppercase designation, per the FM nav spec. The
                // spoken label above stays sentence case for VoiceOver.
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontVariations: [
                    FontVariation('wght', isSelected ? 600 : 500),
                  ],
                  fontSize: 10,
                  letterSpacing: 0.8,
                  color: color,
                  shadows: glow,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
