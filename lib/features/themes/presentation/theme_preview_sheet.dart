import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../domain/app_theme_data.dart';
import '../providers/theme_providers.dart';

/// Bottom sheet shown when a theme card is tapped. Previews the theme on a
/// fake dashboard fragment (ring + macro bars + card), then shows the right
/// CTA — Buy / Equip / Equipped ✓ — based on ownership state.
class ThemePreviewSheet extends ConsumerWidget {
  const ThemePreviewSheet({super.key, required this.theme});

  final AppThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final owned = ref.watch(ownedThemesProvider);
    final state = ref.watch(userThemeStateProvider);
    final coins = state.coins;

    final isOwned = owned.contains(theme.id);
    final isEquipped = state.equippedThemeId == theme.id;
    final canAfford = coins >= theme.price;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              theme.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 4),
            _PriceLine(theme: theme, isOwned: isOwned, palette: palette),
            const SizedBox(height: 18),
            _MockDashboard(theme: theme),
            const SizedBox(height: 22),
            _ActionButton(
              theme: theme,
              isOwned: isOwned,
              isEquipped: isEquipped,
              canAfford: canAfford,
              palette: palette,
              onPressed: () => _handlePress(
                context: context,
                ref: ref,
                isOwned: isOwned,
                isEquipped: isEquipped,
                canAfford: canAfford,
              ),
            ),
            if (!isOwned && !canAfford) ...[
              const SizedBox(height: 10),
              Text(
                'Not enough coins — finish more workouts to earn more.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handlePress({
    required BuildContext context,
    required WidgetRef ref,
    required bool isOwned,
    required bool isEquipped,
    required bool canAfford,
  }) async {
    if (isEquipped) return;
    final notifier = ref.read(userThemeStateProvider.notifier);
    if (isOwned) {
      HapticFeedback.lightImpact();
      await notifier.equip(theme.id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showCupertinoToast(context, 'Equipped “${theme.name}”');
      return;
    }
    if (!canAfford) return;
    HapticFeedback.mediumImpact();
    final result = await notifier.purchase(theme);
    if (!context.mounted) return;
    if (result == PurchaseResult.success) {
      Navigator.of(context).pop();
      showCupertinoToast(context, 'Unlocked “${theme.name}” — equipped!');
    } else if (result == PurchaseResult.alreadyOwned) {
      Navigator.of(context).pop();
      showCupertinoToast(context, 'Equipped “${theme.name}”');
    } else {
      // insufficientFunds — the button is normally disabled before reaching
      // here. Surface a dialog just in case wallet state changed mid-flight.
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Not enough coins'),
          content: Text(
            'You need ${theme.price} coins to unlock “${theme.name}”.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.theme,
    required this.isOwned,
    required this.palette,
  });

  final AppThemeData theme;
  final bool isOwned;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    if (isOwned || theme.id == 'midnight_blue') {
      return Text(
        'Owned',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: palette.textSecondary,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.monetization_on,
          size: 14,
          color: palette.warning,
        ),
        const SizedBox(width: 4),
        Text(
          '${theme.price} coins',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: palette.text,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.theme,
    required this.isOwned,
    required this.isEquipped,
    required this.canAfford,
    required this.palette,
    required this.onPressed,
  });

  final AppThemeData theme;
  final bool isOwned;
  final bool isEquipped;
  final bool canAfford;
  final Palette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    String label;
    bool enabled;
    if (isEquipped) {
      label = 'Equipped ✓';
      enabled = false;
    } else if (isOwned) {
      label = 'Equip';
      enabled = true;
    } else if (!canAfford) {
      label = 'Not enough coins';
      enabled = false;
    } else {
      label = 'Buy for ${theme.price} coins';
      enabled = true;
    }
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: enabled ? theme.accent : palette.surfaceElevated,
        disabledColor: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        onPressed: enabled ? onPressed : null,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: enabled ? CupertinoColors.white : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Fake dashboard preview: a calorie-ring stand-in, three macro bars, and a
/// "card". Each element is painted with the candidate theme's colours so the
/// user sees the equip effect before committing.
class _MockDashboard extends StatelessWidget {
  const _MockDashboard({required this.theme});

  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.darkBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0x14FFFFFF)),
      ),
      child: Column(
        children: [
          _MockRing(theme: theme),
          const SizedBox(height: 14),
          _MockMacroBar(label: 'Protein', value: 0.7, theme: theme),
          const SizedBox(height: 8),
          _MockMacroBar(label: 'Carbs', value: 0.45, theme: theme),
          const SizedBox(height: 8),
          _MockMacroBar(label: 'Fat', value: 0.3, theme: theme),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.darkSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.accent.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.local_fire_department,
                      color: theme.accent, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '5-day streak',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: CupertinoColors.white,
                        ),
                      ),
                      Text(
                        'Keep it up.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockRing extends StatelessWidget {
  const _MockRing({required this.theme});
  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: _RingPainter(
          progress: 0.65,
          ringColor: theme.accent,
          trackColor: theme.darkSurface,
        ),
        child: const Center(
          child: Text(
            '1,420',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: CupertinoColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  final double progress;
  final Color ringColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 8) / 2;
    final track = Paint()
      ..color = trackColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final foreground = Paint()
      ..color = ringColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centre, radius, track);
    final sweep = 2 * 3.1415926535 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -3.1415926535 / 2,
      sweep,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor;
}

class _MockMacroBar extends StatelessWidget {
  const _MockMacroBar({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final double value;
  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: theme.darkSurface),
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.accent, theme.accentLight],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
