import 'package:isar/isar.dart';

part 'user_theme_state.g.dart';

/// Single-row collection holding the user's cosmetic state: which theme is
/// equipped, which they've unlocked, and their soft/premium currency balances.
///
/// We use a fixed `id = 1` and treat the collection as a singleton — the app
/// either reads the row, or creates it with defaults on first launch.
///
/// Default coins/gems are inflated to 100 each for the store-testing phase
/// so QA can buy multiple themes without grinding. The default `ownedThemeIds`
/// includes both free themes — `midnight_blue` (the default) and `slate`.
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
        coins = 100,
        gems = 100;
}
