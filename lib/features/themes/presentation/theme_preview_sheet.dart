import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../../../core/theme/surface_texture.dart';
import '../../../core/widgets/cupertino_helpers.dart';
import '../../../core/widgets/jump_wings.dart';
import '../../../providers/entitlement_providers.dart';
import '../../paywall/presentation/airborne_paywall.dart';
import '../domain/app_theme_data.dart';
import '../domain/theme_gate.dart';
import '../domain/theme_registry.dart';
import '../providers/theme_providers.dart';

/// Bottom sheet shown when a theme card is tapped. Previews the pack's accent
/// on a fake Field Manual dashboard fragment (gauge + macro bars + card) —
/// per the Accent Swap Rule the chrome is identical across packs, so the
/// accent is the whole story — then shows the right CTA — Buy / Equip /
/// Equipped ✓ — based on ownership state.
class ThemePreviewSheet extends ConsumerWidget {
  const ThemePreviewSheet({super.key, required this.theme});

  final AppThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final owned = ref.watch(ownedThemesProvider);
    final unlocked = ref.watch(unlockedThemesProvider);
    final airborne = ref.watch(airborneActiveProvider);
    final state = ref.watch(userThemeStateProvider);
    final coins = state.coins;

    // Owned = bought with coins; unlocked additionally includes standard coin
    // themes while Airborne is active (price bypass only — never ownership).
    final isOwned = owned.contains(theme.id);
    final isUnlocked = unlocked.contains(theme.id);
    final isEquipped = state.equippedThemeId == theme.id;
    final canAfford = coins >= theme.price;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        // FM sheet: ink ground, top radius 12; the scrim behind the modal
        // conveys modality — no shadow.
        color: FieldManual.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        // Scrolls rather than overflows: the mock dashboard + CTA stack can
        // exceed screen height at max Dynamic Type.
        child: SingleChildScrollView(
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
                  color: FieldManual.mutedBone.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              theme.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: FieldManual.headline(),
            ),
            const SizedBox(height: 4),
            _PriceLine(
              theme: theme,
              isOwned: isOwned,
              isAirborneUnlock: isUnlocked && !isOwned,
            ),
            const SizedBox(height: 18),
            _MockDashboard(theme: theme),
            const SizedBox(height: 22),
            _ActionButton(
              theme: theme,
              isUnlocked: isUnlocked,
              isEquipped: isEquipped,
              canAfford: canAfford,
              palette: palette,
              onPressed: () => _handlePress(
                context: context,
                ref: ref,
                isOwned: isOwned,
                isUnlocked: isUnlocked,
                isEquipped: isEquipped,
                canAfford: canAfford,
              ),
            ),
            // Airborne affordance on locked STANDARD themes — premium themes
            // stay coin-only, and subscribers see no upsell.
            if (!airborne && !isOwned && isStandardCoinTheme(theme)) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 6),
                onPressed: () => _handleAirborneTap(context, ref),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Airborne brand moment — brass, not the live accent.
                    // The sheet ground is ink by doctrine, where brass reads.
                    const JumpWings(width: 24),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Or go Airborne — every standard theme, issued.',
                        style: FieldManual.body(
                          fontSize: 13,
                          color: FieldManual.brass,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isUnlocked && !canAfford) ...[
              const SizedBox(height: 10),
              Text(
                'Not enough coins — finish more workouts to earn more.',
                textAlign: TextAlign.center,
                style: FieldManual.body(
                  fontSize: 12,
                  color: FieldManual.mutedBone,
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  /// Opens the Airborne paywall; on success the sheet's providers rebuild and
  /// the theme flips to unlocked in place.
  Future<void> _handleAirborneTap(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    await presentAirbornePaywall(context, ref);
  }

  Future<void> _handlePress({
    required BuildContext context,
    required WidgetRef ref,
    required bool isOwned,
    required bool isUnlocked,
    required bool isEquipped,
    required bool canAfford,
  }) async {
    if (isEquipped) return;
    final notifier = ref.read(userThemeStateProvider.notifier);
    if (isUnlocked) {
      HapticFeedback.lightImpact();
      // markOwned only for true coin ownership: an Airborne-unlocked equip
      // must not grant the theme permanently (it re-locks if the sub lapses).
      await notifier.equip(theme.id, markOwned: isOwned);
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
    required this.isAirborneUnlock,
  });

  final AppThemeData theme;
  final bool isOwned;

  /// Equippable via the Airborne subscription rather than coin ownership.
  final bool isAirborneUnlock;

  @override
  Widget build(BuildContext context) {
    if (isOwned || theme.id == defaultTheme.id) {
      return Text(
        'OWNED',
        textAlign: TextAlign.center,
        style: FieldManual.label(),
      );
    }
    if (isAirborneUnlock) {
      // Airborne entitlement stamp — a brand moment, so brass (not the live
      // accent) on the sheet's ink ground.
      return Text(
        'INCLUDED WITH AIRBORNE',
        textAlign: TextAlign.center,
        style: FieldManual.label(color: FieldManual.brass),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Neutral coin token in mutedBone — never the warning dollar-sign.
        const Icon(
          CupertinoIcons.hexagon_fill,
          size: 13,
          color: FieldManual.mutedBone,
        ),
        const SizedBox(width: 5),
        Text(
          '${theme.price} COINS',
          style: FieldManual.readout(fontSize: 13),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.theme,
    required this.isUnlocked,
    required this.isEquipped,
    required this.canAfford,
    required this.palette,
    required this.onPressed,
  });

  final AppThemeData theme;
  final bool isUnlocked;
  final bool isEquipped;
  final bool canAfford;
  final Palette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    String label;
    bool enabled;
    if (isEquipped) {
      label = 'EQUIPPED ✓';
      enabled = false;
    } else if (isUnlocked) {
      label = 'EQUIP';
      enabled = true;
    } else if (!canAfford) {
      label = 'NOT ENOUGH COINS';
      enabled = false;
    } else {
      label = 'BUY FOR ${theme.price} COINS';
      enabled = true;
    }
    // Text on the CANDIDATE pack's accent mirrors [Palette.onAccent] (ink on
    // bright accents, bone on dark ones like Stealth) — palette.onAccent only
    // knows the live accent, and this button paints the candidate's.
    final onAccent = theme.accent.computeLuminance() >= 0.18
        ? FieldManual.ink
        : FieldManual.bone;
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: enabled ? theme.accent : FieldManual.fieldRaised,
        disabledColor: FieldManual.fieldRaised,
        borderRadius: BorderRadius.circular(4),
        onPressed: enabled ? onPressed : null,
        child: Text(
          label,
          style: FieldManual.label(
            fontSize: 13,
            color: enabled ? onAccent : FieldManual.mutedBone,
          ),
        ),
      ),
    );
  }
}

/// Fake dashboard preview: a kcal-gauge stand-in, three macro readout bars,
/// and a streak "card", all on Field Manual chrome. Per the Accent Swap Rule
/// only the accent family varies between packs — the ground stays ink/field
/// (the pack surface tokens below ARE ink/field since the registry re-cut)
/// and the macro bars stay bone, exactly as on the real dashboard. The accent
/// shows where it really lands: the gauge sweep and the icon chip (plus the
/// CTA button above).
class _MockDashboard extends StatelessWidget {
  const _MockDashboard({required this.theme});

  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    // Read geometry/material from the PREVIEWED theme, never from
    // FieldManual.skin — that reflects the theme currently *equipped*, which
    // is precisely the one the user isn't looking at here. Accent-swap packs
    // leave these null and resolve to the original literals, so their preview
    // is unchanged; a full skin previews as the material it actually is.
    final radius = theme.cardRadius ?? 8;
    final borderColor = theme.darkBorder ?? FieldManual.hairline;
    final texture = theme.surfaceTexture;

    final panel = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // Left transparent when a texture paints behind, so the camo shows.
        color: texture == null ? theme.darkBackground : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _MockGauge(theme: theme),
          const SizedBox(height: 14),
          const _MockMacroBar(label: 'PROTEIN', value: 0.7),
          const SizedBox(height: 8),
          const _MockMacroBar(label: 'CARBS', value: 0.45),
          const SizedBox(height: 8),
          const _MockMacroBar(label: 'FAT', value: 0.3),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.darkSurface, // field on every pack
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: theme.accent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '5-DAY STREAK',
                        style: FieldManual.readout(fontSize: 12),
                      ),
                      Text(
                        'Keep it up.',
                        style: FieldManual.body(
                          fontSize: 11,
                          color: FieldManual.mutedBone,
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

    if (texture == null) return panel;
    // A full skin's texture IS the thing being bought. Previewing it as a flat
    // fill would sell the skin on its accent alone.
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: SurfaceTexturePainter(texture),
        child: panel,
      ),
    );
  }
}

/// Miniature of the real dashboard instrument (kcal_gauge.dart): a 240° arc
/// opening at the bottom with tick etching — a speedometer, not an Apple ring.
/// Previewing the pack "as on the real dashboard" means drawing the real shape.
class _MockGauge extends StatelessWidget {
  const _MockGauge({required this.theme});
  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 92,
      child: CustomPaint(
        painter: _GaugeMockPainter(fraction: 0.65, accent: theme.accent),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('1,420', style: FieldManual.readout(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

class _GaugeMockPainter extends CustomPainter {
  _GaugeMockPainter({required this.fraction, required this.accent});

  final double fraction;
  final Color accent;

  // 240° arc, opening at the bottom: 150° → 390° — the real gauge's geometry.
  static final _start = _rad(150);
  static final _sweep = _rad(240);
  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    final radius = math.min(size.width, size.height * 1.28) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = FieldManual.hairlineStrong;
    canvas.drawArc(rect, _start, _sweep, false, track);

    // Tick etching: minor every 5%, major every 25%.
    final minorTick = Paint()
      ..strokeWidth = 1
      ..color = FieldManual.bone.withValues(alpha: 0.35);
    final majorTick = Paint()
      ..strokeWidth = 1.4
      ..color = FieldManual.bone.withValues(alpha: 0.65);
    for (var i = 0; i <= 20; i++) {
      final isMajor = i % 5 == 0;
      final angle = _start + _sweep * (i / 20);
      final outer = radius + 5;
      final inner = outer + (isMajor ? 6 : 3);
      final from = center + Offset(math.cos(angle), math.sin(angle)) * outer;
      final to = center + Offset(math.cos(angle), math.sin(angle)) * inner;
      canvas.drawLine(from, to, isMajor ? majorTick : minorTick);
    }

    // Progress arc — the accent needle-sweep.
    if (fraction > 0) {
      final progress = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = accent;
      canvas.drawArc(rect, _start, _sweep * fraction, false, progress);
    }
  }

  @override
  bool shouldRepaint(_GaugeMockPainter old) =>
      old.fraction != fraction || old.accent != accent;
}

/// Mirrors the real MacroReadout: mono label, bone fill on a hairline track.
/// Deliberately NOT accent-painted — macro bars are bone on every pack, and
/// the preview must not promise otherwise.
class _MockMacroBar extends StatelessWidget {
  const _MockMacroBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: FieldManual.label()),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: SizedBox(
              height: 3,
              child: Stack(
                children: [
                  Container(color: FieldManual.hairline),
                  FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      color: FieldManual.bone.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
