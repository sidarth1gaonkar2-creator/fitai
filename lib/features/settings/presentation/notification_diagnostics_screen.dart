import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/notif_diag_log.dart';
import '../../../providers/drill_sergeant_providers.dart';
import '../../../providers/notification_reconciler.dart';
import '../../../services/notification_diagnostics.dart';
import '../../../services/notification_service.dart';

/// Hidden developer screen (reached via a long-press on the Settings version
/// row) that makes the entire local-notification pipeline visible ON DEVICE —
/// the only way to debug "nothing fires" on TestFlight where there's no console.
///
/// It shows the resolved timezone (a UTC fallback is visible at a glance), the
/// live OS permission, the real pending queue with trigger dates, and the
/// persisted `[notif]` log ring buffer. The "fire test in 60s" button runs the
/// same zonedSchedule path morning motivation uses and prints any exception
/// right on the screen.
class NotificationDiagnosticsScreen extends ConsumerStatefulWidget {
  const NotificationDiagnosticsScreen({super.key});

  @override
  ConsumerState<NotificationDiagnosticsScreen> createState() =>
      _NotificationDiagnosticsScreenState();
}

class _NotificationDiagnosticsScreenState
    extends ConsumerState<NotificationDiagnosticsScreen> {
  NotifDiagnostics? _diag;
  DiagTestResult? _lastTest;
  bool _loading = true;
  bool _busy = false;
  String? _actionNote;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final diag = await NotificationService.instance.collectDiagnostics();
    if (!mounted) return;
    setState(() {
      _diag = diag;
      _loading = false;
    });
  }

  Future<void> _fireTest() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionNote = null;
    });
    final result = await NotificationService.instance.scheduleDiagnosticTest();
    // Re-dump pending immediately so the just-scheduled probe (id 870) shows up
    // — if it doesn't appear here, the OS rejected it silently.
    final diag = await NotificationService.instance.collectDiagnostics();
    if (!mounted) return;
    final inQueue =
        diag.pending.any((p) => p.id == NotificationService.diagnosticTestId);
    setState(() {
      _lastTest = result;
      _diag = diag;
      _busy = false;
      if (!result.success) {
        _actionNote = 'Test FAILED to schedule — see the exception below. '
            'That text is the bug.';
      } else if (inQueue) {
        // EXPECTED on this device: the generic zonedSchedule path is confirmed
        // working (the daily drill-sergeant reminder fires). A green fire-test
        // is not the answer — check the Morning Motivation card below, which
        // tests the specific id-860 path that never fires.
        _actionNote = 'Test queued ✓ and present in the OS pending queue '
            '(id 870 below) — confirms the generic schedule path works. The '
            'morning-motivation failure is id-860-specific: see the Morning '
            'Motivation card.';
      } else {
        // zonedSchedule returned WITHOUT throwing, yet the probe is absent
        // from the OS queue — the schedule was silently dropped.
        _actionNote = 'zonedSchedule returned with NO error, but id 870 is '
            'NOT in the OS pending queue → the schedule was silently dropped. '
            'Capture this with the Copy report button.';
      }
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _reconcile() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionNote = null;
    });
    try {
      await ref.read(notificationReconcilerProvider).reconcile();
      _actionNote = 'Reconcile ran. Check the log + pending queue below.';
    } catch (e) {
      _actionNote = 'Reconcile threw: $e';
    }
    final diag = await NotificationService.instance.collectDiagnostics();
    if (!mounted) return;
    setState(() {
      _diag = diag;
      _busy = false;
    });
  }

  /// Runs ONLY the drill-sergeant + morning-motivation reconcile (the exact
  /// path that should schedule id 860), then re-dumps so we can see whether the
  /// morning reminder actually lands in the OS queue. This is the focused probe
  /// for the Build 77 morning-motivation investigation.
  Future<void> _reconcileDrill() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionNote = null;
    });
    try {
      await ref.read(notificationReconcilerProvider).reconcileDrill();
      _actionNote = 'Drill reconcile ran — see if id 860 appears below + the '
          'log for "scheduled daily id=860".';
    } catch (e) {
      _actionNote = 'reconcileDrill threw: $e';
    }
    final diag = await NotificationService.instance.collectDiagnostics();
    if (!mounted) return;
    setState(() {
      _diag = diag;
      _busy = false;
    });
  }

  Future<void> _requestPermission() async {
    if (_busy) return;
    setState(() => _busy = true);
    final granted = await NotificationService.instance.requestPermission();
    final diag = await NotificationService.instance.collectDiagnostics();
    if (!mounted) return;
    setState(() {
      _diag = diag;
      _busy = false;
      _actionNote = 'requestPermission() returned $granted';
    });
  }

  Future<void> _cancelTest() async {
    await NotificationService.instance.cancelDiagnosticTest();
    final diag = await NotificationService.instance.collectDiagnostics();
    if (!mounted) return;
    setState(() {
      _diag = diag;
      _lastTest = null;
      _actionNote = 'Test probe (id 870) cancelled.';
    });
  }

  void _clearLog() {
    NotifDiagLog.clear();
    setState(() => _actionNote = 'Log cleared.');
  }

  Future<void> _copyReport() async {
    await Clipboard.setData(ClipboardData(text: _buildReport()));
    if (!mounted) return;
    setState(() => _actionNote = 'Full report copied to clipboard.');
    HapticFeedback.selectionClick();
  }

  String _buildReport() {
    final d = _diag;
    final b = StringBuffer()
      ..writeln('=== DrillFit Notification Diagnostics ===')
      ..writeln('collectedAt: ${d?.collectedAt.toIso8601String()}');
    if (d != null) {
      b
        ..writeln('pluginInitialized: ${d.pluginInitialized}')
        ..writeln('tz.local.name: ${d.tzLocalName}')
        ..writeln('tz resolved@init: ${d.tzResolvedAtInit}')
        ..writeln('tz init error: ${d.tzInitError}')
        ..writeln('tz live: ${d.tzLiveResolved}')
        ..writeln('tz live error: ${d.tzLiveError}')
        ..writeln('permission enabled: ${d.permissionEnabled}')
        ..writeln('permission detail: ${d.permissionDetail}')
        ..writeln('native auth status: ${d.nativeAuthStatus}')
        ..writeln('pending (${d.pending.length}, '
            'fromNative=${d.pendingFromNative}):');
      for (final p in d.pending) {
        b.writeln('  id=${p.id} "${p.title}" '
            'type=${p.type} repeats=${p.repeats} '
            'next=${p.nextTrigger != null ? _fmt(p.nextTrigger!) : '—'}');
      }
    }
    final t = _lastTest;
    if (t != null) {
      b
        ..writeln('--- last fire-test ---')
        ..writeln('success: ${t.success}')
        ..writeln('tz: ${t.tzName}')
        ..writeln('scheduledFor: ${t.scheduledFor}')
        ..writeln('error: ${t.error}')
        ..writeln('stack: ${t.stack}');
    }
    b.writeln('--- [notif] log (newest first) ---');
    for (final line in NotifDiagLog.entries()) {
      b.writeln(line);
    }
    return b.toString();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _fmt(DateTime dt) =>
      '${dt.year}-${_two(dt.month)}-${_two(dt.day)} '
      '${_two(dt.hour)}:${_two(dt.minute)}:${_two(dt.second)}';

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final d = _diag;
    final drill = ref.watch(drillSergeantProvider);

    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Notification Diagnostics'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
        trailing: _busy || _loading
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _refresh,
                child: const Icon(CupertinoIcons.refresh, size: 20),
              ),
      ),
      child: SafeArea(
        child: _loading && d == null
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_actionNote != null) ...[
                    _NoteBanner(text: _actionNote!, palette: palette),
                    const SizedBox(height: 12),
                  ],
                  _buildActions(palette),
                  const SizedBox(height: 16),
                  if (_lastTest != null) ...[
                    _buildTestResult(palette, _lastTest!),
                    const SizedBox(height: 16),
                  ],
                  _buildMorningMotivation(palette, d, drill),
                  const SizedBox(height: 16),
                  if (d != null) ...[
                    _buildTimezone(palette, d),
                    const SizedBox(height: 16),
                    _buildPermission(palette, d),
                    const SizedBox(height: 16),
                    _buildPending(palette, d),
                    const SizedBox(height: 16),
                  ],
                  _buildLog(palette),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildActions(Palette palette) {
    return _Card(
      palette: palette,
      title: 'Actions',
      icon: CupertinoIcons.bolt_fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionButton(
            label: 'Fire test notification in 60s',
            color: palette.accent,
            onPressed: _busy ? null : _fireTest,
          ),
          const SizedBox(height: 8),
          _ActionButton(
            label: 'Run full reconcile now',
            color: palette.surfaceElevated,
            textColor: palette.text,
            onPressed: _busy ? null : _reconcile,
          ),
          const SizedBox(height: 8),
          _ActionButton(
            label: 'Request OS permission',
            color: palette.surfaceElevated,
            textColor: palette.text,
            onPressed: _busy ? null : _requestPermission,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Copy report',
                  color: palette.surfaceElevated,
                  textColor: palette.text,
                  onPressed: _copyReport,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Cancel test',
                  color: palette.surfaceElevated,
                  textColor: palette.textSecondary,
                  onPressed: _busy ? null : _cancelTest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestResult(Palette palette, DiagTestResult t) {
    final ok = t.success;
    final color = ok ? palette.success : palette.destructive;
    return _Card(
      palette: palette,
      title: 'Last fire-test',
      icon: ok ? CupertinoIcons.check_mark_circled : CupertinoIcons.xmark_octagon,
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('result', ok ? 'SCHEDULED OK' : 'THREW', palette, valueColor: color),
          _kv('tz at schedule', t.tzName, palette),
          if (t.scheduledFor != null)
            _kv('will fire at', _fmt(t.scheduledFor!), palette),
          if (t.error != null) ...[
            const SizedBox(height: 8),
            Text('exception (the bug report):',
                style: TextStyle(
                    color: palette.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            _Mono(text: t.error!, palette: palette, color: color),
          ],
          if (t.stack != null && t.stack!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _Mono(text: t.stack!, palette: palette, dim: true),
          ],
        ],
      ),
    );
  }

  /// The prime suspect for Build 77. The daily drill-sergeant reminders (ids
  /// 850-853) fire correctly, so zonedSchedule / tz / permission all work — yet
  /// morning motivation (id 860) never fires. Both go through the SAME
  /// `_scheduleDaily`, so this card surfaces the upstream difference: the live
  /// drill prefs (is morning actually enabled in storage?) and whether id 860
  /// lands in the OS queue after a drill reconcile.
  Widget _buildMorningMotivation(
      Palette palette, NotifDiagnostics? d, DrillSergeantPrefs drill) {
    final inQueue = d?.pending
            .any((p) => p.id == NotificationService.morningMotivationId) ??
        false;
    // Morning only schedules when BOTH the master drill toggle and the morning
    // toggle are on (reconcileDrill early-returns when !drill.enabled).
    final wouldSchedule = drill.enabled && drill.morningEnabled;
    final problem = wouldSchedule && d != null && !inQueue;

    return _Card(
      palette: palette,
      title: 'Morning Motivation (id 860)',
      icon: CupertinoIcons.sunrise,
      accent: problem
          ? palette.destructive
          : (wouldSchedule ? null : palette.warning),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('drill master enabled', '${drill.enabled}', palette,
              valueColor:
                  drill.enabled ? palette.success : palette.warning),
          _kv('morning enabled', '${drill.morningEnabled}', palette,
              valueColor:
                  drill.morningEnabled ? palette.success : palette.warning),
          _kv('morning time', drill.morningTimeLabel, palette),
          _kv('id 860 in queue', inQueue ? 'YES' : 'NO', palette,
              valueColor: inQueue ? palette.success : palette.destructive),
          const SizedBox(height: 6),
          if (!drill.enabled)
            Text(
              'Master Drill Sergeant toggle is OFF → reconcileDrill cancels '
              'morning and returns early. Morning can never schedule while '
              'this is off, even if the morning toggle is on.',
              style: TextStyle(color: palette.warning, fontSize: 12),
            )
          else if (!drill.morningEnabled)
            Text(
              'Morning toggle is OFF in storage → morning is intentionally not '
              'scheduled. If the Settings UI shows it ON, the toggle handler '
              'is not persisting (suspect: settings handler).',
              style: TextStyle(color: palette.warning, fontSize: 12),
            )
          else if (problem)
            Text(
              'Morning SHOULD be scheduled (both toggles on) but id 860 is NOT '
              'in the queue. Tap below, then check the log for '
              '"scheduled daily id=860" vs "failed to schedule daily id=860".',
              style: TextStyle(color: palette.destructive, fontSize: 12),
            )
          else
            Text(
              'Both toggles on and id 860 is queued. Check its trigger date in '
              'the pending list — if it is correct, the schedule is fine and '
              'the issue is OS delivery, not scheduling.',
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
          const SizedBox(height: 10),
          _ActionButton(
            label: 'Re-run drill reconcile now',
            color: palette.accent,
            onPressed: _busy ? null : _reconcileDrill,
          ),
        ],
      ),
    );
  }

  Widget _buildTimezone(Palette palette, NotifDiagnostics d) {
    final isUtc = d.tzLocalName == 'UTC';
    return _Card(
      palette: palette,
      title: 'Timezone',
      icon: CupertinoIcons.globe,
      accent: isUtc ? palette.warning : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('tz.local.name', d.tzLocalName, palette,
              valueColor: isUtc ? palette.warning : palette.success),
          if (isUtc)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                '⚠ tz.local is UTC — device zone resolution fell back. '
                'Schedules are UTC-stamped.',
                style: TextStyle(color: palette.warning, fontSize: 12),
              ),
            ),
          _kv('resolved @ init', d.tzResolvedAtInit ?? '(none)', palette),
          if (d.tzInitError != null)
            _kv('init error', d.tzInitError!, palette,
                valueColor: palette.destructive),
          _kv('live getLocalTimezone()', d.tzLiveResolved, palette),
          if (d.tzLiveError != null)
            _kv('live error', d.tzLiveError!, palette,
                valueColor: palette.destructive),
          _kv('plugin initialized', '${d.pluginInitialized}', palette,
              valueColor:
                  d.pluginInitialized ? palette.success : palette.destructive),
        ],
      ),
    );
  }

  Widget _buildPermission(Palette palette, NotifDiagnostics d) {
    final enabled = d.permissionEnabled == true;
    return _Card(
      palette: palette,
      title: 'OS Permission',
      icon: CupertinoIcons.bell,
      accent: enabled ? null : palette.destructive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('isEnabled', '${d.permissionEnabled}', palette,
              valueColor: enabled ? palette.success : palette.destructive),
          if (d.nativeAuthStatus case final status?)
            _kv('UNAuthorizationStatus', status, palette),
          const SizedBox(height: 4),
          _Mono(text: d.permissionDetail, palette: palette),
        ],
      ),
    );
  }

  Widget _buildPending(Palette palette, NotifDiagnostics d) {
    return _Card(
      palette: palette,
      title: 'Pending queue (${d.pending.length})',
      icon: CupertinoIcons.list_bullet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.pendingFromNative
                ? 'Source: UNUserNotificationCenter (real trigger dates).'
                : 'Source: plugin Dart API (no trigger dates available).',
            style: TextStyle(color: palette.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          if (d.pending.isEmpty)
            Text(
              'EMPTY — nothing is queued. If you just enabled a reminder, '
              'this is the smoking gun: the schedule never landed.',
              style: TextStyle(color: palette.warning, fontSize: 13),
            )
          else
            ...d.pending.map((p) => _pendingRow(palette, p)),
        ],
      ),
    );
  }

  Widget _pendingRow(Palette palette, PendingEntry p) {
    final isTest = p.id == NotificationService.diagnosticTestId;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTest ? palette.accent : palette.separator,
          width: isTest ? 1.2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('id ${p.id}',
                  style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
              if (isTest) ...[
                const SizedBox(width: 6),
                Text('(test)',
                    style:
                        TextStyle(color: palette.textSecondary, fontSize: 11)),
              ],
              const Spacer(),
              if (p.type != null)
                Text(
                  '${p.type}${p.repeats == true ? ' · repeats' : ''}',
                  style:
                      TextStyle(color: palette.textSecondary, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(p.title ?? '(no title)',
              style: TextStyle(color: palette.text, fontSize: 13)),
          if (p.nextTrigger != null)
            Text('fires ${_fmt(p.nextTrigger!)}',
                style: TextStyle(
                    color: palette.success,
                    fontSize: 12,
                    fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildLog(Palette palette) {
    final lines = NotifDiagLog.recent(50);
    return _Card(
      palette: palette,
      title: '[notif] log — last ${lines.length}',
      icon: CupertinoIcons.doc_text,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: _clearLog,
        child: Text('Clear',
            style: TextStyle(color: palette.destructive, fontSize: 13)),
      ),
      child: lines.isEmpty
          ? Text('No [notif] entries captured yet.',
              style: TextStyle(color: palette.textSecondary, fontSize: 13))
          : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.separator, width: 0.5),
              ),
              child: SelectableText(
                lines.join('\n'),
                style: TextStyle(
                  color: palette.textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
    );
  }

  Widget _kv(String k, String v, Palette palette, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(k,
                style:
                    TextStyle(color: palette.textSecondary, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                color: valueColor ?? palette.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.palette,
    required this.title,
    required this.icon,
    required this.child,
    this.accent,
    this.trailing,
  });

  final Palette palette;
  final String title;
  final IconData icon;
  final Widget child;
  final Color? accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent ?? palette.border,
          width: accent != null ? 1.2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent ?? palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.textColor,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: color,
      borderRadius: BorderRadius.circular(10),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? CupertinoColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Mono extends StatelessWidget {
  const _Mono({
    required this.text,
    required this.palette,
    this.color,
    this.dim = false,
  });

  final String text;
  final Palette palette;
  final Color? color;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.separator, width: 0.5),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          color: color ?? (dim ? palette.textSecondary : palette.text),
          fontFamily: 'monospace',
          fontSize: dim ? 10 : 12,
          height: 1.4,
        ),
      ),
    );
  }
}

class _NoteBanner extends StatelessWidget {
  const _NoteBanner({required this.text, required this.palette});

  final String text;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: palette.accent, fontSize: 13),
      ),
    );
  }
}
