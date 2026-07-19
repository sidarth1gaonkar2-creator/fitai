import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
import '../domain/app_theme_data.dart';
import '../domain/theme_registry.dart';
import '../providers/theme_providers.dart';
import 'theme_preview_sheet.dart';

/// Readable tone for text sitting ON a pack's accent fill: ink for bright
/// accents, bone for the dark ones (e.g. Stealth). Mirrors [Palette.onAccent],
/// which only knows the LIVE accent — store cells paint candidate accents.
Color _onPackAccent(Color accent) =>
    accent.computeLuminance() >= 0.18 ? FieldManual.ink : FieldManual.bone;

/// 2-column grid of every theme pack in the registry. Per the Accent Swap
/// Rule every pack rides the same Field Manual ink/field chrome, so each cell
/// shows the FM ground with the pack's accent family + price/ownership state;
/// tapping opens [ThemePreviewSheet] with a mock-dashboard preview and the
/// buy/equip CTA.
class ThemeStoreScreen extends ConsumerWidget {
  const ThemeStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinBalanceProvider);
    final equippedId = ref.watch(activeThemeProvider).id;
    final owned = ref.watch(ownedThemesProvider);
    // Owned ∪ Airborne-included standard themes — what's equippable today.
    final unlocked = ref.watch(unlockedThemesProvider);

    return CupertinoPageScaffold(
      backgroundColor: FieldManual.ink,
      navigationBar: CupertinoNavigationBar(
        middle: Text('THEME STORE', style: FieldManual.title()),
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(
          bottom: BorderSide(color: FieldManual.hairline),
        ),
        trailing: _CurrencyChip(amount: coins),
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
              isOwned: unlocked.contains(theme.id),
              isAirborneUnlock:
                  unlocked.contains(theme.id) && !owned.contains(theme.id),
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
    required this.isAirborneUnlock,
    required this.isEquipped,
    required this.onTap,
  });

  final AppThemeData theme;
  final bool isOwned;

  /// Equippable via the Airborne subscription (not coin-owned) — badged
  /// "INCLUDED" so it never masquerades as permanent ownership.
  final bool isAirborneUnlock;
  final bool isEquipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String stateLabel = isEquipped
        ? 'equipped'
        : isOwned
            ? (isAirborneUnlock ? 'included with Airborne' : 'owned')
            // The flagship is price 0 but not free — never announce it as
            // "0 coins" to the grid or to VoiceOver.
            : theme.airborneExclusive
                ? 'Airborne exclusive'
                : '${theme.price} coins';
    return Semantics(
      button: true,
      label: '${theme.name}, $stateLabel',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: FieldManual.field,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEquipped ? theme.accent : FieldManual.hairline,
                width: isEquipped ? 2 : 1,
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Swatch(theme: theme),
                    if (theme.airborneExclusive)
                      Positioned(
                        top: 8,
                        right: 8,
                        // The flagship's own chip. Brass on ink — an Airborne
                        // brand moment, per the Airborne Brass Rule, so it
                        // stays brass whatever pack is equipped.
                        child: _Badge(
                          label: 'AIRBORNE',
                          background: Color.alphaBlend(
                            FieldManual.brass.withValues(alpha: 0.18),
                            FieldManual.ink,
                          ),
                          textColor: FieldManual.brass,
                        ),
                      )
                    else if (theme.isPremium)
                      Positioned(
                        top: 8,
                        right: 8,
                        // Premium chip: mono label on an accent tint —
                        // blended over ink so it stays opaque and legible on
                        // any swatch pixel. No gold, no gradient.
                        child: _Badge(
                          label: 'PREMIUM',
                          background: Color.alphaBlend(
                            theme.accent.withValues(alpha: 0.18),
                            FieldManual.ink,
                          ),
                          textColor: FieldManual.bone,
                        ),
                      ),
                    if (isEquipped)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _Badge(
                          label: 'EQUIPPED',
                          background: theme.accent,
                          textColor: _onPackAccent(theme.accent),
                        ),
                      )
                    else if (isOwned)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _Badge(
                          label: isAirborneUnlock ? 'INCLUDED' : 'OWNED',
                          background: FieldManual.fieldRaised,
                          textColor: FieldManual.mutedBone,
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
                    theme.name.toUpperCase(),
                    style: FieldManual.title().copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  _PriceLabel(
                    theme: theme,
                    isOwned: isOwned,
                    isEquipped: isEquipped,
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

/// Pack swatch, honest to the Accent Swap Rule: every pack rides the same
/// ink→field Field Manual ground (the gradient derives from the pack's own
/// surface tokens, which ARE ink/field since the registry re-cut), and only
/// the accent family varies — shown as an accent-filled instrument bar plus
/// the accent/accent-light dots.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.theme});
  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.darkBackground, theme.darkSurface],
        ),
      ),
      child: Stack(
        children: [
          // Where the accent really lands: a gauge/progress fill on a
          // hairline track.
          Center(
            child: SizedBox(
              width: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: SizedBox(
                  height: 3,
                  child: Stack(
                    children: [
                      Container(color: FieldManual.hairline),
                      FractionallySizedBox(
                        widthFactor: 0.65,
                        child: Container(color: theme.accent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // The accent and its pressed tone — the two accent states the
                  // pack actually renders. (accentLight is consumed by no
                  // product widget, so showing it here oversold a colour the
                  // pack never delivers.)
                  for (final c in [theme.accent, theme.accentPressed])
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: FieldManual.hairlineStrong),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: FieldManual.label(color: textColor)),
    );
  }
}

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({
    required this.theme,
    required this.isOwned,
    required this.isEquipped,
  });

  final AppThemeData theme;
  final bool isOwned;
  final bool isEquipped;

  @override
  Widget build(BuildContext context) {
    if (isEquipped) {
      // Quiet stamp — the card's accent border and swatch badge already
      // carry the equipped state.
      return Text('EQUIPPED', style: FieldManual.label());
    }
    if (isOwned) {
      return Text(
        'Tap to equip',
        style: FieldManual.body(fontSize: 12, color: FieldManual.mutedBone),
      );
    }
    // Locked flagship: a coin figure would be a lie (price 0, but not free).
    // Brass copy instead — the subscription is the only route in.
    if (theme.airborneExclusive) {
      return Text(
        'With Airborne',
        style: FieldManual.body(fontSize: 12, color: FieldManual.brass),
      );
    }
    return Row(
      children: [
        const Icon(_kCoinGlyph, size: 11, color: FieldManual.mutedBone),
        const SizedBox(width: 4),
        Text('${theme.price}', style: FieldManual.readout(fontSize: 12)),
      ],
    );
  }
}

/// The coin token: a neutral hexagon glyph in mutedBone, never the warning
/// dollar-sign — coins are earned, not purchased, and warning orange is a
/// foreign accent on a themed store.
const IconData _kCoinGlyph = CupertinoIcons.hexagon_fill;

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$amount coins',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: FieldManual.field,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: FieldManual.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(_kCoinGlyph, size: 12, color: FieldManual.mutedBone),
              const SizedBox(width: 5),
              Text('$amount', style: FieldManual.readout(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
