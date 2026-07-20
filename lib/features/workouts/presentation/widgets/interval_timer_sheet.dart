import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Slider, SliderTheme, SliderThemeData;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/interval_timer_provider.dart';
import '../../domain/interval_timer_state.dart';

class IntervalTimerSheet extends ConsumerWidget {
  const IntervalTimerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(intervalTimerProvider);
    final notifier = ref.read(intervalTimerProvider.notifier);

    final isIdle = timer.phase == IntervalTimerPhase.idle;
    final isFinished = timer.phase == IntervalTimerPhase.finished;

    final palette = AppColors.of(context);
    final phaseColor = switch (timer.phase) {
      IntervalTimerPhase.work => palette.accent,
      IntervalTimerPhase.rest => palette.success,
      IntervalTimerPhase.finished => palette.warning,
      IntervalTimerPhase.idle => palette.accent,
    };

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.text.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'INTERVALS',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontVariations: const [FontVariation('wght', 600)],
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 0.6,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 16),

              // Preset selector (only when idle)
              if (isIdle) ...[
                CupertinoSlidingSegmentedControl<IntervalPreset>(
                  groupValue: timer.preset,
                  backgroundColor: palette.scaffold,
                  thumbColor: palette.accent,
                  children: const {
                    IntervalPreset.hiit: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('HIIT',
                          style:
                              TextStyle(fontFamily: 'Inter', fontSize: 13)),
                    ),
                    IntervalPreset.tabata: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Tabata',
                          style:
                              TextStyle(fontFamily: 'Inter', fontSize: 13)),
                    ),
                    IntervalPreset.custom: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Custom',
                          style:
                              TextStyle(fontFamily: 'Inter', fontSize: 13)),
                    ),
                  },
                  onValueChanged: (v) {
                    if (v != null) {
                      HapticFeedback.selectionClick();
                      notifier.loadPreset(v);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Config sliders
                _ConfigSlider(
                  label: 'Work',
                  value: timer.workDuration,
                  min: 5,
                  max: 300,
                  color: palette.accent,
                  onChanged: (v) => notifier.setWorkDuration(v.round()),
                ),
                const SizedBox(height: 8),
                _ConfigSlider(
                  label: 'Rest',
                  value: timer.restDuration,
                  min: 5,
                  max: 300,
                  color: palette.success,
                  onChanged: (v) => notifier.setRestDuration(v.round()),
                ),
                const SizedBox(height: 8),
                _ConfigSlider(
                  label: 'Rounds',
                  value: timer.totalRounds,
                  min: 1,
                  max: 50,
                  color: palette.warning,
                  onChanged: (v) => notifier.setRounds(v.round()),
                  formatValue: (v) => '$v',
                ),
                const SizedBox(height: 20),
              ],

              // Timer display (when running/finished)
              if (!isIdle) ...[
                // Phase label — mono stamp in the phase colour.
                Text(
                  timer.phaseLabel.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: phaseColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),

                // Large countdown — the instrument readout.
                Text(
                  timer.formattedTime,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontWeight: FontWeight.w700,
                    fontSize: 64,
                    color: phaseColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),

                // Round indicator
                Text(
                  isFinished
                      ? 'All rounds complete!'
                      : 'ROUND ${timer.currentRound}/${timer.totalRounds}',
                  style: isFinished
                      ? TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          color: palette.textSecondary,
                        )
                      : TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontVariations: const [FontVariation('wght', 500)],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          letterSpacing: 1,
                          color: palette.textSecondary,
                        ),
                ),
                const SizedBox(height: 20),
              ],

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isIdle || isFinished)
                    _ActionButton(
                      label: isFinished ? 'Restart' : 'Start',
                      color: palette.accent,
                      onTap: () => notifier.start(),
                    )
                  else ...[
                    _ActionButton(
                      label: 'Stop',
                      color: palette.destructive,
                      onTap: () => notifier.stop(),
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      label: timer.isPaused ? 'Resume' : 'Pause',
                      color: timer.isPaused ? palette.success : palette.warning,
                      onTap: () {
                        if (timer.isPaused) {
                          notifier.resume();
                        } else {
                          notifier.pause();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigSlider extends StatelessWidget {
  const _ConfigSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
    this.formatValue,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final Color color;
  final ValueChanged<double> onChanged;
  final String Function(int)? formatValue;

  String _formatSeconds(int s) {
    if (formatValue != null) return formatValue!(s);
    if (s >= 60) {
      final m = s ~/ 60;
      final r = s % 60;
      return r > 0 ? '${m}m ${r}s' : '${m}m';
    }
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            _formatSeconds(value),
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontVariations: const [FontVariation('wght', 500)],
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: AppColors.of(context).text,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Ink label on bright fills, white on dark ones — never accent-on-accent.
    final onFill = color.computeLuminance() >= 0.18
        ? const Color(0xFF1A1C1A)
        : const Color(0xFFFFFFFF);
    return Semantics(
      label: label,
      button: true,
      child: ExcludeSemantics(
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          color: color,
          borderRadius: BorderRadius.circular(4),
          onPressed: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Oswald',
              fontVariations: const [FontVariation('wght', 600)],
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.6,
              color: onFill,
            ),
          ),
        ),
      ),
    );
  }
}

