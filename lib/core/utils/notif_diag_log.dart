import 'package:shared_preferences/shared_preferences.dart';

/// Persistent, on-device ring buffer for `[notif]`-tagged diagnostics.
///
/// We have NO device console access on TestFlight, so schedule-time errors that
/// happen on a cold launch (before any screen is open) would otherwise vanish.
/// Every `AppLogger.log`/`AppLogger.error` whose message contains `[notif]` is
/// mirrored here — *including the full exception and stack* — and persisted to
/// [SharedPreferences] so it survives an app restart and is readable from the
/// hidden Notification Diagnostics screen.
///
/// Storage is synchronous-friendly: [attach] is called once during bootstrap
/// with the already-resolved [SharedPreferences] instance, after which
/// [record] can persist via fire-and-forget. Entries recorded before [attach]
/// (rare) are buffered in memory and flushed on attach.
class NotifDiagLog {
  NotifDiagLog._();

  static const _key = 'notif_diag_ring_v1';

  /// Keep a generous window — the screen shows the most recent 50, but holding
  /// more means a burst of schedule logs can't push the original error out.
  static const _maxEntries = 150;

  static SharedPreferences? _prefs;

  /// Chronological, oldest first. Each entry is a multi-line block:
  /// `<iso8601-utc>  <message>` optionally followed by indented error/stack.
  static final List<String> _entries = <String>[];

  /// Wire up persistence. Loads any previously-persisted entries and merges
  /// them *behind* anything recorded earlier this session, then flushes.
  /// Safe to call more than once.
  static void attach(SharedPreferences prefs) {
    _prefs = prefs;
    final stored = prefs.getStringList(_key) ?? const <String>[];
    if (stored.isNotEmpty) {
      // Persisted entries are older than in-memory ones recorded pre-attach.
      _entries.insertAll(0, stored);
      _trim();
    }
    _persist();
  }

  /// Whether a log line is one we care about capturing. Matches the `[notif]`
  /// tag every notification log/error already uses.
  static bool isNotifTagged(String message) => message.contains('[notif]');

  /// Append one diagnostic entry. [error] and [stack] are captured in full so
  /// a swallowed `zonedSchedule` exception is recoverable on-device.
  static void record(String message, {Object? error, StackTrace? stack}) {
    final ts = DateTime.now().toUtc().toIso8601String();
    final buf = StringBuffer('$ts  $message');
    if (error != null) {
      buf.write('\n    ↳ ${error.runtimeType}: $error');
    }
    if (stack != null) {
      final lines = stack
          .toString()
          .trimRight()
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .take(14)
          .map((l) => '      $l')
          .join('\n');
      if (lines.isNotEmpty) buf.write('\n$lines');
    }
    _entries.add(buf.toString());
    _trim();
    _persist();
  }

  /// Most-recent-first view for display.
  static List<String> entries() =>
      List<String>.unmodifiable(_entries.reversed);

  /// Newest-first, capped at [count] for the diagnostics screen.
  static List<String> recent([int count = 50]) {
    final all = entries();
    return all.length <= count ? all : all.sublist(0, count);
  }

  static int get length => _entries.length;

  static void clear() {
    _entries.clear();
    _persist();
  }

  static void _trim() {
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
  }

  static void _persist() {
    // Fire-and-forget; a dropped write just means one fewer breadcrumb, never
    // a crash. Nothing awaits notification logging.
    _prefs?.setStringList(_key, _entries);
  }
}
