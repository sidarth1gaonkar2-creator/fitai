import 'package:flutter/services.dart';

/// Data models + native bridge for the hidden Notification Diagnostics screen.
///
/// The flutter_local_notifications Dart API only exposes id/title/body for a
/// pending request — NOT its trigger date or the precise OS authorization
/// status. Those are the two facts we most need to debug "nothing fires", so we
/// read them straight from `UNUserNotificationCenter` over a tiny read-only
/// method channel (registered in ios/Runner/AppDelegate.swift). Everything here
/// fails soft: if the channel is missing (non-iOS, unit tests), callers fall
/// back to the plugin's Dart API.

/// One entry in the OS pending-notification queue.
class PendingEntry {
  const PendingEntry({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.repeats,
    this.nextTrigger,
    required this.fromNative,
  });

  final int id;
  final String? title;
  final String? body;

  /// iOS trigger kind: `calendar` (matchDateTimeComponents repeating),
  /// `interval` (one-shot/periodic), or `immediate-or-other`. Null on the
  /// Dart fallback path (Android / channel unavailable).
  final String? type;

  /// Whether the OS trigger repeats. Null when unknown.
  final bool? repeats;

  /// The next wall-clock time iOS will fire this, in device-local time. Null
  /// when unavailable (Dart fallback, or an `immediate` trigger).
  final DateTime? nextTrigger;

  /// True when sourced from the native channel (has real trigger data), false
  /// when sourced from the plugin's Dart `pendingNotificationRequests()`.
  final bool fromNative;
}

/// Full snapshot rendered by the diagnostics screen.
class NotifDiagnostics {
  const NotifDiagnostics({
    required this.collectedAt,
    required this.pluginInitialized,
    required this.tzLocalName,
    required this.tzResolvedAtInit,
    required this.tzInitError,
    required this.tzLiveResolved,
    required this.tzLiveError,
    required this.permissionEnabled,
    required this.permissionDetail,
    required this.nativeAuthStatus,
    required this.pending,
    required this.pendingFromNative,
    required this.collectError,
  });

  final DateTime collectedAt;

  /// Did `NotificationService.init()` complete (plugin.initialize awaited)?
  final bool pluginInitialized;

  /// `tz.local.name` evaluated right now. If this reads `UTC` the device zone
  /// resolution silently fell back — every schedule would be UTC-stamped.
  final String tzLocalName;

  /// What `FlutterTimezone.getLocalTimezone()` returned during init (cached).
  final String? tzResolvedAtInit;

  /// Error captured during init's timezone resolution, if any.
  final String? tzInitError;

  /// A fresh `FlutterTimezone.getLocalTimezone()` call — surfaces a
  /// MissingPluginException if the pod isn't actually wired up.
  final String tzLiveResolved;
  final String? tzLiveError;

  /// `checkPermissions().isEnabled` (iOS) / areNotificationsEnabled (Android).
  final bool? permissionEnabled;

  /// Human-readable breakdown (alert/badge/sound/provisional/critical).
  final String permissionDetail;

  /// Precise `UNAuthorizationStatus` name from the native channel (iOS only).
  final String? nativeAuthStatus;

  final List<PendingEntry> pending;
  final bool pendingFromNative;

  /// Any error that interrupted collection (collection itself never throws).
  final String? collectError;
}

/// Outcome of the "fire test in 60s" action — surfaces the exception text on
/// screen instead of swallowing it (the whole point of the screen).
class DiagTestResult {
  const DiagTestResult({
    required this.success,
    this.scheduledFor,
    required this.tzName,
    this.error,
    this.stack,
  });

  final bool success;

  /// Local wall-clock time the test is scheduled to fire.
  final DateTime? scheduledFor;
  final String tzName;
  final String? error;
  final String? stack;
}

/// Read-only native bridge over `UNUserNotificationCenter`.
class NotifNativeDiag {
  NotifNativeDiag._();

  static const MethodChannel _channel =
      MethodChannel('com.sidarth.fitai/notif_diag');

  /// Precise OS authorization status, or null if the channel is unavailable.
  static Future<String?> authorizationStatus() async {
    try {
      return await _channel.invokeMethod<String>('getAuthorizationStatus');
    } catch (_) {
      return null;
    }
  }

  /// Pending requests with trigger dates, or null if the channel is
  /// unavailable (caller falls back to the plugin's Dart API).
  static Future<List<PendingEntry>?> pendingDetailed() async {
    try {
      final res =
          await _channel.invokeMethod<List<dynamic>>('getPendingDetailed');
      if (res == null) return null;
      return res.map((raw) {
        final m = (raw as Map).cast<dynamic, dynamic>();
        final idRaw = m['id'];
        final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? -1;
        final ms = m['nextTriggerMs'];
        final next = ms is num
            ? DateTime.fromMillisecondsSinceEpoch(ms.toInt())
            : null;
        return PendingEntry(
          id: id,
          title: m['title'] as String?,
          body: m['body'] as String?,
          type: m['type'] as String?,
          repeats: m['repeats'] as bool?,
          nextTrigger: next,
          fromNative: true,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }
}
