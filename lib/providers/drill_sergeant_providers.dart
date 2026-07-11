import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/scoped_prefs.dart';
import '../data/motivator_messages.dart';
import '../providers/auth_provider.dart';
import '../providers/unit_system_provider.dart';

// Base keys — stored uid-scoped as `<base>_<uid>` (uid-scoping PR-B).
const _kEnabled = 'drill_sergeant_enabled';
const _kIntensity = 'drill_sergeant_intensity';
const _kMorningEnabled = 'morning_motivation_enabled';
const _kMorningTime = 'morning_motivation_time';
const _kFullMetal = 'drill_sergeant_full_metal';

/// User preferences for the toxic-motivator personality. Stored in
/// SharedPreferences (via the existing [sharedPreferencesProvider]) under
/// uid-scoped keys so the values survive app restarts, can be read
/// synchronously during the notification-scheduling cold path, and never
/// bleed to another account on the same device.
class DrillSergeantPrefs {
  const DrillSergeantPrefs({
    required this.enabled,
    required this.intensity,
    required this.morningEnabled,
    required this.morningHour,
    required this.morningMinute,
    required this.fullMetalEnabled,
  });

  /// Master switch. When false, all other fields are ignored and any
  /// previously-scheduled notifications are cancelled by the caller.
  final bool enabled;

  /// 1 = Mild (1×/day), 2 = Medium (2×/day), 3 = Full Savage (4×/day).
  /// Controls FREQUENCY only — message tone does not change with intensity.
  final int intensity;

  /// Independent of [enabled] in storage so we don't lose the user's chosen
  /// morning preference when they toggle the main flag off and back on.
  final bool morningEnabled;
  final int morningHour;
  final int morningMinute;

  /// Opt-in to the explicit-language "Full Metal" message pool. Persisted, but
  /// only has any effect while [kFullMetalEnabled] is true (the hard gate) —
  /// otherwise the 12+ pool is always used. The Settings toggle that sets this
  /// is hidden until the gate opens.
  final bool fullMetalEnabled;

  String get intensityLabel => switch (intensity) {
        1 => 'Mild Roast',
        2 => 'Medium Roast',
        3 => 'Full Savage',
        _ => 'Mild Roast',
      };

  String get morningTimeLabel {
    final h = morningHour % 12 == 0 ? 12 : morningHour % 12;
    final m = morningMinute.toString().padLeft(2, '0');
    final period = morningHour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  DrillSergeantPrefs copyWith({
    bool? enabled,
    int? intensity,
    bool? morningEnabled,
    int? morningHour,
    int? morningMinute,
    bool? fullMetalEnabled,
  }) {
    return DrillSergeantPrefs(
      enabled: enabled ?? this.enabled,
      intensity: intensity ?? this.intensity,
      morningEnabled: morningEnabled ?? this.morningEnabled,
      morningHour: morningHour ?? this.morningHour,
      morningMinute: morningMinute ?? this.morningMinute,
      fullMetalEnabled: fullMetalEnabled ?? this.fullMetalEnabled,
    );
  }

  /// Everything off / neutral — the signed-out state.
  static const DrillSergeantPrefs defaults = DrillSergeantPrefs(
    enabled: false,
    intensity: 1,
    morningEnabled: false,
    morningHour: 7,
    morningMinute: 0,
    fullMetalEnabled: false,
  );

  static DrillSergeantPrefs fromPrefs(SharedPreferences prefs, String? uid) {
    if (uid == null) return defaults;
    final timeStr = prefs.getString(scopedKey(_kMorningTime, uid)) ?? '07:00';
    final parts = timeStr.split(':');
    final h = parts.length == 2 ? int.tryParse(parts[0]) ?? 7 : 7;
    final m = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DrillSergeantPrefs(
      enabled: prefs.getBool(scopedKey(_kEnabled, uid)) ?? false,
      intensity: prefs.getInt(scopedKey(_kIntensity, uid)) ?? 1,
      morningEnabled: prefs.getBool(scopedKey(_kMorningEnabled, uid)) ?? false,
      morningHour: h.clamp(0, 23),
      morningMinute: m.clamp(0, 59),
      fullMetalEnabled: prefs.getBool(scopedKey(_kFullMetal, uid)) ?? false,
    );
  }
}

class DrillSergeantNotifier extends StateNotifier<DrillSergeantPrefs> {
  DrillSergeantNotifier(this._prefs, this._uid)
      : super(DrillSergeantPrefs.fromPrefs(_prefs, _uid)) {
    // Sync the message-pool selection with the persisted preference. The gate
    // ([kFullMetalEnabled]) is enforced inside setFullMetal, so while it's
    // closed this is a no-op and the 12+ pool stays active.
    MotivatorMessages.setFullMetal(state.fullMetalEnabled);
  }

  final SharedPreferences _prefs;
  final String? _uid;

  /// Signed out (unreachable from the Settings UI): state still updates so
  /// the UI stays consistent, but nothing is persisted — no anon keys.
  Future<void> _persistBool(String base, bool value) async {
    final uid = _uid;
    if (uid == null) return;
    await _prefs.setBool(scopedKey(base, uid), value);
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await _persistBool(_kEnabled, value);
  }

  Future<void> setIntensity(int level) async {
    final clamped = level.clamp(1, 3);
    state = state.copyWith(intensity: clamped);
    final uid = _uid;
    if (uid == null) return;
    await _prefs.setInt(scopedKey(_kIntensity, uid), clamped);
  }

  Future<void> setMorningEnabled(bool value) async {
    state = state.copyWith(morningEnabled: value);
    await _persistBool(_kMorningEnabled, value);
  }

  Future<void> setMorningTime(int hour, int minute) async {
    state = state.copyWith(morningHour: hour, morningMinute: minute);
    final uid = _uid;
    if (uid == null) return;
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    await _prefs.setString(scopedKey(_kMorningTime, uid), '$h:$m');
  }

  /// Opt in/out of the explicit "Full Metal" pool. Persisted regardless, but
  /// [MotivatorMessages.setFullMetal] only actually switches pools while
  /// [kFullMetalEnabled] is true — so this is inert until the gate opens.
  Future<void> setFullMetal(bool value) async {
    state = state.copyWith(fullMetalEnabled: value);
    MotivatorMessages.setFullMetal(value);
    await _persistBool(_kFullMetal, value);
  }
}

final drillSergeantProvider =
    StateNotifierProvider<DrillSergeantNotifier, DrillSergeantPrefs>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DrillSergeantNotifier(prefs, ref.watch(currentUserIdProvider));
});
