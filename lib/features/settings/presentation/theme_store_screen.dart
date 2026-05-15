import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, Scaffold, ScaffoldMessenger, SnackBar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../data/theme_store.dart';
import '../../../providers/theme_store_providers.dart';

class ThemeStoreScreen extends ConsumerWidget {
  const ThemeStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final coins = ref.watch(coinBalanceProvider);
    final gems = ref.watch(gemBalanceProvider);
    final activeId = ref.watch(activeThemeIdProvider);
    final owned = ref.watch(themeOwnershipProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: CupertinoNavigationBar(
        middle: const Text('Theme Store'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CurrencyChip(
              icon: Icons.monetization_on,
              color: palette.warning,
              amount: coins,
            ),
            const SizedBox(width: 8),
            _CurrencyChip(
              icon: Icons.diamond,
              color: palette.accent,
              amount: gems,
            ),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: availableThemes.length + 1, // +1 for "Get more coins" tile
        itemBuilder: (context, index) {
          if (index == availableThemes.length) {
            return _EarnMoreTile();
          }
          final theme = availableThemes[index];
          return _ThemeCard(
            theme: theme,
            isActive: theme.id == activeId,
            isOwned: owned.contains(theme.id) || theme.isDefault,
            onTap: () => _onCardTap(context, ref, theme),
          );
        },
      ),
    );
  }

  Future<void> _onCardTap(
    BuildContext context,
    WidgetRef ref,
    AppThemePack theme,
  ) async {
    HapticFeedback.selectionClick();
    final owned = ref.read(themeOwnershipProvider);
    final activeId = ref.read(activeThemeIdProvider);
    final isOwned = owned.contains(theme.id) || theme.isDefault;
    final isActive = theme.id == activeId;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => _ThemePreviewSheet(
        theme: theme,
        isOwned: isOwned,
        isActive: isActive,
        onAction: () => _handleAction(sheetContext, ref, theme),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext sheetContext,
    WidgetRef ref,
    AppThemePack theme,
  ) async {
    final owned = ref.read(themeOwnershipProvider);
    final isOwned = owned.contains(theme.id) || theme.isDefault;
    final messenger = ScaffoldMessenger.maybeOf(sheetContext);

    if (isOwned) {
      await ref.read(activeThemeIdProvider.notifier).setActive(theme.id);
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      messenger?.showSnackBar(
        SnackBar(content: Text('Equipped "${theme.name}"')),
      );
      return;
    }

    if (theme.isPremium) {
      // No StoreKit integration yet — surface a friendly placeholder.
      await showCupertinoDialog<void>(
        context: sheetContext,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Coming soon'),
          content: const Text(
            'Gem purchases will be available in a future update.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final ok = await ref
        .read(coinBalanceProvider.notifier)
        .spend(theme.priceCoin, 'theme_${theme.id}');
    if (!ok) {
      if (!sheetContext.mounted) return;
      await showCupertinoDialog<void>(
        context: sheetContext,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Not enough coins'),
          content: Text(
            'You need ${theme.priceCoin} coins to unlock "${theme.name}". '
            'Complete more workouts to earn more!',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    await ref.read(themeOwnershipProvider.notifier).add(theme.id);
    await ref.read(activeThemeIdProvider.notifier).setActive(theme.id);
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    if (sheetContext.mounted) {
      showCupertinoToast(
        sheetContext,
        'Unlocked "${theme.name}" — equipped!',
      );
    }
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.isActive,
    required this.isOwned,
    required this.onTap,
  });

  final AppThemePack theme;
  final bool isActive;
  final bool isOwned;
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
            color: isActive ? palette.accent : palette.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color swatch preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.backgroundColor,
                      theme.surfaceColor,
                      theme.primaryColor,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (theme.isPremium)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.diamond,
                                  size: 10, color: Color(0xFF00BCD4)),
                              SizedBox(width: 2),
                              Text(
                                'Premium',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (isActive)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Equipped',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                    isActive: isActive,
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

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({
    required this.theme,
    required this.isOwned,
    required this.isActive,
  });

  final AppThemePack theme;
  final bool isOwned;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    if (isActive) {
      return Text(
        'Equipped',
        style: TextStyle(
          fontSize: 11,
          color: palette.accent,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (isOwned) {
      return Text(
        'Owned · tap to equip',
        style: TextStyle(
          fontSize: 11,
          color: palette.textSecondary,
        ),
      );
    }
    if (theme.isPremium) {
      return Row(
        children: [
          Icon(Icons.diamond, size: 11, color: palette.accent),
          const SizedBox(width: 3),
          Text(
            '${theme.priceGem} gems',
            style: TextStyle(
              fontSize: 11,
              color: palette.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(Icons.monetization_on, size: 11, color: palette.warning),
        const SizedBox(width: 3),
        Text(
          '${theme.priceCoin}',
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

class _ThemePreviewSheet extends StatelessWidget {
  const _ThemePreviewSheet({
    required this.theme,
    required this.isOwned,
    required this.isActive,
    required this.onAction,
  });

  final AppThemePack theme;
  final bool isOwned;
  final bool isActive;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: palette.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.backgroundColor,
                    theme.surfaceColor,
                    theme.primaryColor,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              theme.name,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              theme.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: isActive ? palette.surface : palette.accent,
                borderRadius: BorderRadius.circular(12),
                onPressed: isActive ? null : onAction,
                child: Text(
                  isActive
                      ? 'Already equipped'
                      : isOwned
                          ? 'Equip'
                          : theme.isPremium
                              ? 'Buy with ${theme.priceGem} gems'
                              : 'Unlock for ${theme.priceCoin} coins',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

class _EarnMoreTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.monetization_on,
              color: palette.warning, size: 24),
          const SizedBox(height: 8),
          Text(
            'Earn coins',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '+10 per workout\n+50 at 7-day streak\n+25 for new PR\n+100 for challenge complete',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

