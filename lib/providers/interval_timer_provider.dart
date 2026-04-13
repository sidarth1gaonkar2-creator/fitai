import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/workouts/domain/interval_timer_state.dart';

class IntervalTimerNotifier extends StateNotifier<IntervalTimerState> {
  IntervalTimerNotifier() : super(const IntervalTimerState());

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void loadPreset(IntervalPreset preset) {
    _timer?.cancel();
    final config = presetConfig(preset);
    state = IntervalTimerState(
      preset: preset,
      workDuration: config.work,
      restDuration: config.rest,
      totalRounds: config.rounds,
    );
  }

  void setWorkDuration(int seconds) {
    state = state.copyWith(
      workDuration: seconds.clamp(5, 300),
      preset: IntervalPreset.custom,
    );
  }

  void setRestDuration(int seconds) {
    state = state.copyWith(
      restDuration: seconds.clamp(5, 300),
      preset: IntervalPreset.custom,
    );
  }

  void setRounds(int rounds) {
    state = state.copyWith(
      totalRounds: rounds.clamp(1, 50),
      preset: IntervalPreset.custom,
    );
  }

  void start() {
    _timer?.cancel();
    state = state.copyWith(
      phase: IntervalTimerPhase.work,
      remainingSeconds: state.workDuration,
      currentRound: 1,
      isPaused: false,
    );
    HapticFeedback.heavyImpact();
    _startTicking();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    state = state.copyWith(isPaused: false);
    _startTicking();
  }

  void stop() {
    _timer?.cancel();
    state = IntervalTimerState(
      workDuration: state.workDuration,
      restDuration: state.restDuration,
      totalRounds: state.totalRounds,
      preset: state.preset,
    );
  }

  void _startTicking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final remaining = state.remainingSeconds - 1;

      if (remaining <= 0) {
        _onPhaseComplete();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  void _onPhaseComplete() {
    HapticFeedback.heavyImpact();

    if (state.phase == IntervalTimerPhase.work) {
      // Switch to rest
      state = state.copyWith(
        phase: IntervalTimerPhase.rest,
        remainingSeconds: state.restDuration,
      );
    } else if (state.phase == IntervalTimerPhase.rest) {
      if (state.currentRound >= state.totalRounds) {
        // All rounds complete
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        state = state.copyWith(
          phase: IntervalTimerPhase.finished,
          remainingSeconds: 0,
        );
      } else {
        // Next round
        state = state.copyWith(
          phase: IntervalTimerPhase.work,
          remainingSeconds: state.workDuration,
          currentRound: state.currentRound + 1,
        );
      }
    }
  }
}

final intervalTimerProvider =
    StateNotifierProvider.autoDispose<IntervalTimerNotifier, IntervalTimerState>(
  (ref) => IntervalTimerNotifier(),
);
