import 'package:isar/isar.dart';

part 'user_theme_state.g.dart';

/// Single-row collection holding the user's cosmetic state: which theme is
/// equipped, which they've unlocked, and their soft/premium currency balances.
///
/// We use a fixed `id = 1` and treat the collection as a singleton — the app
/// either reads the row, or creates it with defaults on first launch.
///
/// New users start with 50 coins (a small welcome grant) and 0 gems. The
/// default `ownedThemeIds` includes the two free themes — `midnight_blue`
/// (the default) and `slate`.
@collection
class UserThemeState {
  Id id = 1;

  late String equippedThemeId;

  late List<String> ownedThemeIds;

  late int coins;
  late int gems;

  DateTime updatedAt = DateTime.now();

  UserThemeState();

  UserThemeState.defaults()
      : equippedThemeId = 'midnight_blue',
        ownedThemeIds = const ['midnight_blue', 'slate'],
        coins = 50,
        gems = 0;
}
