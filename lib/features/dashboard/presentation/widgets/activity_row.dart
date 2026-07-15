import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../providers/health_providers.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../../../services/health_service.dart';

/// Horizontal scrolling row of Apple Health stats. Only renders on iOS when
/// the user is connected and has the dashboard toggle on. Shows a connect CTA
/// when iOS + available but not connected.
class ActivityRow extends ConsumerWidget {
  const ActivityRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isIOS) return const SizedBox.shrink();
    final availableAsync = ref.watch(healthAvailableProvider);
    return availableAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (available) {
        if (!available) return const SizedBox.shrink();
        final prefs = ref.watch(healthPrefsProvider);
        if (!prefs.connected) {
          return _ConnectBanner(onTap: () => _connect(context, ref));
        }
        if (!prefs.showOnDashboard) return const SizedBox.shrink();
        return const _ActivityCardsList();
      },
    );
  }

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    bool granted = false;
    try {
      granted = await ref.read(healthServiceProvider).requestPermissions();
    } catch (e) {
      if (!context.mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Apple Health'),
          content: const Text(
            'Unable to connect to Apple Health. Open the iOS Settings app '
            'and check Privacy → Health → DrillFit.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (!context.mounted) return;
    if (granted) {
      final notifier = ref.read(healthPrefsProvider.notifier);
      await notifier.setConnected(true);
      await notifier
          .markAuthorizedAt(HealthService.permissionsSchemaVersion);
      ref.invalidate(dailyHealthSummaryProvider);
      ref.invalidate(weeklyStepsProvider);
      ref.invalidate(weeklyActiveCaloriesProvider);
      if (context.mounted) {
        showCupertinoToast(context, 'Apple Health connected');
      }
    } else {
      showCupertinoToast(
        context,
        'Permission denied. Enable it in iOS Settings → Health.',
      );
    }
  }
}

class _ConnectBanner extends StatelessWidget {
  const _ConnectBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: FieldManual.field,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FieldManual.hairline),
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite, color: FieldManual.olive, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Connect Apple Health',
                        style: FieldManual.body(fontSize: 14)),
                    Text(
                      'Sync steps, calories, heart rate and sleep',
                      style: FieldManual.body(
                          color: FieldManual.mutedBone, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: FieldManual.mutedBone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCardsList extends ConsumerWidget {
  const _ActivityCardsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dailyHealthSummaryProvider);
    final units = ref.watch(unitSystemProvider);

    return SizedBox(
      height: 88,
      child: summaryAsync.when(
        loading: () => _LoadingRow(),
        error: (_, _) => _ErrorRow(
          onRetry: () => ref.invalidate(dailyHealthSummaryProvider),
        ),
        data: (data) {
          final steps = (data['steps'] as int?) ?? 0;
          final distanceMeters = (data['distanceMeters'] as double?) ?? 0;
          final flights = (data['flightsClimbed'] as int?) ?? 0;
          final activeMinutes = (data['activeMinutes'] as int?) ?? 0;
          final heartRate = data['heartRate'] as int?;
          final restingHr = data['restingHeartRate'] as int?;
          final sleepMinutes = (data['sleepMinutes'] as int?) ?? 0;
          final standHours = (data['standHours'] as int?) ?? 0;

          final isMetric = units == UnitSystem.metric;
          final distanceLabel = isMetric ? 'km' : 'mi';
          final distanceValue = isMetric
              ? (distanceMeters / 1000).toStringAsFixed(1)
              : (distanceMeters / 1609.34).toStringAsFixed(1);

          // Stats that are inherently numeric (steps, distance, flights,
          // active minutes) show their literal value — including 0. They're
          // only ever "missing" if the user revoked READ permission for that
          // type, which the user will see immediately as zeros across the
          // board. Heart rate and sleep can be genuinely null (no Apple
          // Watch reading, no sleep tracked) so those still show "—".
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            children: [
              _ActivityCard(
                icon: Icons.directions_walk,
                value: _formatNumber(steps),
                label: 'Steps',
              ),
              const SizedBox(width: 8),
              _ActivityCard(
                icon: CupertinoIcons.location_solid,
                value: distanceValue,
                label: distanceLabel,
              ),
              const SizedBox(width: 8),
              _ActivityCard(
                icon: Icons.stairs,
                value: flights.toString(),
                label: 'Flights',
              ),
              const SizedBox(width: 8),
              _ActivityCard(
                icon: CupertinoIcons.timer,
                value: '$activeMinutes',
                label: 'Active',
              ),
              const SizedBox(width: 8),
              _ActivityCard(
                icon: Icons.favorite,
                value: heartRate != null ? '$heartRate' : '—',
                label: 'bpm',
              ),
              const SizedBox(width: 8),
              _ActivityCard(
                icon: Icons.monitor_heart,
                value: restingHr != null ? '$restingHr' : '—',
                label: 'Resting',
              ),
              const SizedBox(width: 8),
              _ActivityCard(
                icon: Icons.accessibility,
                value: '$standHours',
                label: 'Stand',
              ),
              const SizedBox(width: 8),
              _ActivityCard(
                icon: Icons.bedtime,
                value: sleepMinutes > 0 ? _formatSleep(sleepMinutes) : '—',
                label: 'Sleep',
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatNumber(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final remaining = s.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }

  static String _formatSleep(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h${m}m';
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: FieldManual.field,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FieldManual.hairline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: FieldManual.olive),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FieldManual.readout(fontSize: 14),
          ),
          Text(
            label.toUpperCase(),
            style: FieldManual.label(fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, _) => Container(
        width: 90,
        height: 80,
        decoration: BoxDecoration(
          color: FieldManual.field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FieldManual.hairline),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CupertinoButton(
        onPressed: onRetry,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.refresh, size: 14),
            const SizedBox(width: 6),
            Text(
              'Retry Apple Health',
              style: FieldManual.body(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
