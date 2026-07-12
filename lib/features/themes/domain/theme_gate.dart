import 'app_theme_data.dart';
import 'theme_registry.dart';

/// Whether [theme] is a STANDARD coin theme — priced in coins but not
/// premium. Airborne unlocks exactly these; free themes need no unlock and
/// premium themes deliberately stay coin-only (they're the long-term coin
/// sink that keeps earned currency meaningful).
bool isStandardCoinTheme(AppThemeData theme) =>
    theme.price > 0 && !theme.isPremium;

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
      if (isStandardCoinTheme(t)) t.id,
  };
}
