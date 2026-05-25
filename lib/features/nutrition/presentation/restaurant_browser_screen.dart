import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/restaurant_menus.dart';
import '../../../models/enums.dart';

class RestaurantBrowserScreen extends ConsumerStatefulWidget {
  const RestaurantBrowserScreen({super.key, this.mealType});

  /// Optional pre-selected meal section to drop the built meal into when the
  /// user finishes the meal builder. Forwarded to the builder via the route.
  final MealType? mealType;

  @override
  ConsumerState<RestaurantBrowserScreen> createState() =>
      _RestaurantBrowserScreenState();
}

class _RestaurantBrowserScreenState
    extends ConsumerState<RestaurantBrowserScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Alphabetised view of [restaurantMenus] with the "Other Restaurant"
  /// catch-all pinned to the bottom — even after search, the catch-all
  /// stays last so users can quickly fall back to it when their chain
  /// isn't on the list.
  List<RestaurantMenu> get _filtered {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? restaurantMenus.toList()
        : restaurantMenus
            .where((r) =>
                r.name.toLowerCase().contains(q) ||
                r.mealTypes.any((t) => t.toLowerCase().contains(q)))
            .toList();
    filtered.sort((a, b) {
      // Pin id == 'other' to the end regardless of name.
      if (a.id == 'other') return 1;
      if (b.id == 'other') return -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final filtered = _filtered;

    return Scaffold(
      appBar: CupertinoNavigationBar(
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
        middle: const Text('Restaurants'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CupertinoTextField(
                controller: _searchController,
                placeholder: 'Search restaurants...',
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    CupertinoIcons.search,
                    size: 18,
                    color: palette.textSecondary,
                  ),
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                style: TextStyle(color: palette.text, fontSize: 14),
                placeholderStyle: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 14,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            // Grid
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(query: _query)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final restaurant = filtered[index];
                        return _RestaurantCard(
                          menu: restaurant,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            final mt = widget.mealType?.name;
                            if (restaurant.searchOnly) {
                              // The catch-all entry uses an empty
                              // searchSeed so the search bar opens blank.
                              final seed = restaurant.searchSeed ??
                                  restaurant.name;
                              final qs = <String>[
                                'restaurant=${Uri.encodeQueryComponent(seed)}',
                                if (mt != null) 'mealType=$mt',
                              ].join('&');
                              context.push(
                                  '/nutrition/restaurant-search?$qs');
                            } else {
                              final path =
                                  '/nutrition/restaurants/${restaurant.id}'
                                  '${mt != null ? '?mealType=$mt' : ''}';
                              context.push(path);
                            }
                          },
                        );
                      },
                    ),
            ),
            // Fallback to free-text search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Center(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    final mt = widget.mealType ?? MealType.lunch;
                    context.go('/nutrition/search/${mt.name}');
                  },
                  child: Text(
                    "Don't see your restaurant? Search foods →",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: palette.accent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.menu, required this.onTap});

  final RestaurantMenu menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: menu.accentColor.withValues(alpha: 0.12),
          border:
              Border.all(color: menu.accentColor.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              menu.emoji,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  menu.searchOnly
                      ? (menu.id == 'other'
                          ? 'Search any menu'
                          : 'Search menu')
                      : menu.mealTypes.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_outlined,
                size: 48, color: palette.textSecondary),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'No restaurants yet.'
                  : 'No restaurants match "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
