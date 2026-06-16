import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/app_theme_data.dart';
import '../domain/theme_registry.dart';
import '../providers/theme_providers.dart';
import 'theme_preview_sheet.dart';

/// 2-column grid of every theme in the registry. Each cell shows a swatch
/// preview + price/ownership state; tapping opens [ThemePreviewSheet] with a
/// mock-dashboard preview and the buy/equip CTA.
class ThemeStoreScreen extends ConsumerWidget {
  const ThemeStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final coins = ref.watch(coinBalanceProvider);
    final equippedId = ref.watch(activeThemeProvider).id;
    final owned = ref.watch(ownedThemesProvider);

    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Theme Store'),
        backgroundColor: palette.background.withValues(alpha: 0.85),
        border: null,
        trailing: _CurrencyChip(
          icon: Icons.monetization_on,
          color: palette.warning,
          amount: coins,
        ),
      ),
      child: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: themeRegistry.length,
          itemBuilder: (context, index) {
            final theme = themeRegistry[index];
            return _ThemeCard(
              theme: theme,
              isOwned: owned.contains(theme.id),
              isEquipped: theme.id == equippedId,
              onTap: () => _openPreview(context, theme),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openPreview(BuildContext context, AppThemeData theme) async {
    HapticFeedback.selectionClick();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => ThemePreviewSheet(theme: theme),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.isOwned,
    required this.isEquipped,
    required this.onTap,
  });

  final AppThemeData theme;
  final bool isOwned;
  final bool isEquipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEquipped ? theme.accent : palette.border,
            width: isEquipped ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Swatch(theme: theme),
                    if (theme.isPremium)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _Badge(
                          label: 'Premium',
                          background:
                              CupertinoColors.black.withValues(alpha: 0.55),
                          textColor: CupertinoColors.white,
                          icon: Icons.star,
                          iconColor: palette.warning,
                        ),
                      ),
                    if (isEquipped)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _Badge(
                          label: 'Equipped',
                          background: theme.accent,
                          textColor: CupertinoColors.white,
                        ),
                      )
                    else if (isOwned)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _Badge(
                          label: 'Owned',
                          background:
                              CupertinoColors.black.withValues(alpha: 0.55),
                          textColor: CupertinoColors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    theme.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: palette.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  _PriceLabel(
                    theme: theme,
                    isOwned: isOwned,
                    isEquipped: isEquipped,
                    palette: palette,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.theme});
  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.darkBackground,
            theme.darkSurface,
            theme.accent,
            theme.accentLight,
          ],
          stops: const [0.0, 0.45, 0.85, 1.0],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final c in [theme.accent, theme.accentLight, theme.success])
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CupertinoColors.white.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.textColor,
    this.icon,
    this.iconColor,
  });

  final String label;
  final Color background;
  final Color textColor;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: iconColor ?? textColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 9,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({
    required this.theme,
    required this.isOwned,
    required this.isEquipped,
    required this.palette,
  });

  final AppThemeData theme;
  final bool isOwned;
  final bool isEquipped;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    if (isEquipped) {
      return Text(
        'Equipped',
        style: TextStyle(
          fontSize: 11,
          color: theme.accent,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (isOwned) {
      return Text(
        'Tap to equip',
        style: TextStyle(
          fontSize: 11,
          color: palette.textSecondary,
        ),
      );
    }
    return Row(
      children: [
        Icon(
          Icons.monetization_on,
          size: 11,
          color: palette.warning,
        ),
        const SizedBox(width: 3),
        Text(
          '${theme.price}',
          style: TextStyle(
            fontSize: 11,
            color: palette.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.icon,
    required this.color,
    required this.amount,
  });

  final IconData icon;
  final Color color;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$amount',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}
