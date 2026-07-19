import 'app_theme_data.dart';
import 'theme_registry.dart';

/// Whether [theme] is a STANDARD coin theme — priced in coins but not
/// premium. Airborne unlocks exactly these; free themes need no unlock and
/// premium themes deliberately stay coin-only (they're the long-term coin
/// sink that keeps earned currency meaningful).
bool isStandardCoinTheme(AppThemeData theme) =>
    theme.price > 0 && !theme.isPremium;

/// Whether [theme] can be bought with coins at all. False for the free
/// default, for cash skins, and for the Airborne-exclusive flagship — which
/// carries `price: 0` and so would otherwise read as "affordable" to any
/// `coins >= price` check. Every purchase path must consult this first.
bool isCoinPurchasable(AppThemeData theme) =>
    theme.price > 0 && !theme.airborneExclusive;

/// The theme IDs the user can equip right now: everything coin-owned, plus —
/// while Airborne is active — every standard coin theme.
///
/// Pure gate logic, deliberately separate from [UserThemeState]: Airborne
/// bypasses the coin PRICE only. It never writes ownership, never touches the
/// wallet, and never interacts with coin earning, streaks, or rank
/// progression (rank is earned-only — sacred rule). A lapsed subscription
/// therefore re-locks any standard theme the user didn't buy with coins.
Set<String> unlockedThemeIds({
  required Set<String> owned,
  required bool airborneActive,
}) {
  if (!airborneActive) return owned;
  return {
    ...owned,
    for (final t in themeRegistry)
      if (isStandardCoinTheme(t) || t.airborneExclusive) t.id,
  };
}
