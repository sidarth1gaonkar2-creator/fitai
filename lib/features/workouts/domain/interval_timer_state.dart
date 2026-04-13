enum IntervalTimerPhase { idle, work, rest, finished }

enum IntervalPreset { hiit, tabata, custom }

class IntervalTimerState {
  const IntervalTimerState({
    this.phase = IntervalTimerPhase.idle,
    this.remainingSeconds = 0,
    this.currentRound = 0,
    this.totalRounds = 8,
    this.workDuration = 20,
    this.restDuration = 10,
    this.isPaused = false,
    this.preset = IntervalPreset.hiit,
  });

  final IntervalTimerPhase phase;
  final int remainingSeconds;
  final int currentRound;
  final int totalRounds;
  final int workDuration;
  final int restDuration;
  final bool isPaused;
  final IntervalPreset preset;

  bool get isRunning =>
      (phase == IntervalTimerPhase.work || phase == IntervalTimerPhase.rest) &&
      !isPaused;

  String get phaseLabel => switch (phase) {
        IntervalTimerPhase.idle => 'Ready',
        IntervalTimerPhase.work => 'WORK',
        IntervalTimerPhase.rest => 'REST',
        IntervalTimerPhase.finished => 'Done!',
      };

  String get formattedTime {
    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    if (mins > 0) {
      return '$mins:${secs.toString().padLeft(2, '0')}';
    }
    return '$secs';
  }

  IntervalTimerState copyWith({
    IntervalTimerPhase? phase,
    int? remainingSeconds,
    int? currentRound,
    int? totalRounds,
    int? workDuration,
    int? restDuration,
    bool? isPaused,
    IntervalPreset? preset,
  }) {
    return IntervalTimerState(
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      workDuration: workDuration ?? this.workDuration,
      restDuration: restDuration ?? this.restDuration,
      isPaused: isPaused ?? this.isPaused,
      preset: preset ?? this.preset,
    );
  }
}

// Preset configurations
({int work, int rest, int rounds}) presetConfig(IntervalPreset preset) {
  return switch (preset) {
    IntervalPreset.hiit => (work: 30, rest: 15, rounds: 10),
    IntervalPreset.tabata => (work: 20, rest: 10, rounds: 8),
    IntervalPreset.custom => (work: 30, rest: 30, rounds: 5),
  };
}
