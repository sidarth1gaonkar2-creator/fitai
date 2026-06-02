import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/unit_converter.dart';

const _prefKey = 'unit_system';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main with SharedPreferences.getInstance()');
});

final unitSystemProvider =
    StateNotifierProvider<UnitSystemNotifier, UnitSystem>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UnitSystemNotifier(prefs);
});

class UnitSystemNotifier extends StateNotifier<UnitSystem> {
  UnitSystemNotifier(this._prefs)
      : super(
          // Default to imperial. The onboarding measurements step lets
          // the user flip this; once they pick (or skip), the chosen
          // unit is persisted via [setUnit] and carries through the
          // rest of the app.
          _prefs.getString(_prefKey) == 'metric'
              ? UnitSystem.metric
              : UnitSystem.imperial,
        );

  final SharedPreferences _prefs;

  void setUnit(UnitSystem system) {
    state = system;
    _prefs.setString(_prefKey, system.name);
  }
}
