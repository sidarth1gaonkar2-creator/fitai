import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/health_providers.dart';
import '../../../../providers/unit_system_provider.dart';

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
    final granted =
        await ref.read(healthServiceProvider).requestPermissions();
    if (!context.mounted) return;
    if (granted) {
      await ref.read(healthPrefsProvider.notifier).setConnected(true);
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
    final palette = AppColors.of(context);
    return CupertinoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite, color: palette.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Connect Apple Health',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: palette.text,
                  ),
                ),
                Text(
                  'Sync steps, calories, heart rate and sleep',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: palette.textSecondary,
          ),
        ],
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
          final sleepMinutes = (data['sleepMinutes'] as int?) ?? 0;

          final isMetric = units == UnitSystem.metric;
          final distanceLabel = isMetric ? 'km' : 'mi';
          final distanceValue = isMetric
              ? (distanceMeters / 1000).toStringAsFixed(1)
              : (distanceMeters / 1609.34).toStringAsFixed(1);

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
                value: distanceMeters > 0 ? distanceValue : '—',
                label: distanceLabel,
              ),
              const SizedBox(width: 8),
              _ActivityCard(
                icon: Icons.stairs,
                value: flights > 0 ? flights.toString() : '—',
                label: 'Flights',
              ),
              const SizedBox(width: 8),
              _ActivityCard(
                icon: CupertinoIcons.timer,
                value: activeMinutes > 0 ? '$activeMinutes' : '—',
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
    final palette = AppColors.of(context);
    return Container(
      width: 90,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: palette.accent),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: palette.text,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: palette.textSecondary,
            ),
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
      itemBuilder: (_, _) => const ShimmerBox(
        width: 90,
        height: 80,
        borderRadius: 14,
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
              style: TextStyle(color: AppColors.of(context).text),
            ),
          ],
        ),
      ),
    );
  }
}
