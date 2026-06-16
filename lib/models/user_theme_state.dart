import 'package:isar/isar.dart';

part 'user_theme_state.g.dart';

/// Single-row collection holding the user's cosmetic state: which theme is
/// equipped, which they've unlocked, and their soft/premium currency balances.
///
/// We use a fixed `id = 1` and treat the collection as a singleton — the app
/// either reads the row, or creates it with defaults on first launch.
///
/// New users start with 50 coins (a small welcome grant). The default
/// `ownedThemeIds` includes the two free themes — `midnight_blue` (the
/// default) and `slate`.
@collection
class UserThemeState {
  Id id = 1;

  late String equippedThemeId;

  late List<String> ownedThemeIds;

  late int coins;

  /// DORMANT — gems were retired in favour of a single-currency (coins) model.
  /// This field is never read, awarded, spent, or surfaced in the UI; it is
  /// kept only to avoid a standalone Isar schema/codegen change.
  /// TODO(rebrand schema bump): remove during the planned UserThemeState
  /// migration (uid-scoping + hasChosenTheme) so the schema change lands once.
  late int gems;

  DateTime updatedAt = DateTime.now();

  UserThemeState();

  UserThemeState.defaults()
      : equippedThemeId = 'midnight_blue',
        ownedThemeIds = const ['midnight_blue', 'slate'],
        coins = 50,
        gems = 0;
}
