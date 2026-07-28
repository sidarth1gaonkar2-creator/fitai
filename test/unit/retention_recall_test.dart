import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/providers/retention_planner.dart';

/// Recall hard-stop state machine. "Unanswered" is defined precisely:
///   * D1 unanswered ⇔ no app-open before D2's fire time.
///   * D2 unanswered ⇔ no app-open within 72h of D2 firing.
///   * exhausted ⇔ both unanswered (counter reaches 2) → recall stops for good.
///   * any app-open resets the counter AND the exhausted flag.
void main() {
  // Darkness baseline = last app-open. D1 = +3d 18:00, D2 = +7d 18:00.
  final base = DateTime(2026, 1, 1, 9, 0);
  final d1Fire = RetentionPlanner.recallDay3Fire(base); // Jan 4, 18:00
  final d2Fire = RetentionPlanner.recallDay7Fire(base); // Jan 8, 18:00
  final d2Deadline = d2Fire.add(RetentionRecall.d2AnswerWindow); // Jan 11, 18:00

  test('fire times anchor 3 and 7 days out at 18:00', () {
    expect(d1Fire, DateTime(2026, 1, 4, 18, 0));
    expect(d2Fire, DateTime(2026, 1, 8, 18, 0));
  });

  test('D1 unanswered: no app-open before D2 fires → count 1, not exhausted', () {
    final s = RetentionRecall.evaluate(
      d1Fire: d1Fire,
      d2Fire: d2Fire,
      now: d2Fire, // judgeable exactly at D2's fire time
      lastAppOpenAt: null,
    );
    expect(s.unanswered, 1);
    expect(s.exhausted, isFalse);
  });

  test('D2 still inside its 72h window → not yet counted', () {
    final s = RetentionRecall.evaluate(
      d1Fire: d1Fire,
      d2Fire: d2Fire,
      now: d2Fire.add(const Duration(hours: 71)),
      lastAppOpenAt: null,
    );
    expect(s.unanswered, 1); // only D1 so far
    expect(s.exhausted, isFalse);
  });

  test('D2 unanswered after 72h with no open → count 2, EXHAUSTED', () {
    final s = RetentionRecall.evaluate(
      d1Fire: d1Fire,
      d2Fire: d2Fire,
      now: d2Deadline.add(const Duration(minutes: 1)),
      lastAppOpenAt: null,
    );
    expect(s.unanswered, 2);
    expect(s.exhausted, isTrue);
  });

  test('app-open between D1 and D2 answers D1 → never exhausts', () {
    final s = RetentionRecall.evaluate(
      d1Fire: d1Fire,
      d2Fire: d2Fire,
      now: d2Deadline.add(const Duration(minutes: 1)),
      lastAppOpenAt: DateTime(2026, 1, 5, 10, 0), // in [d1Fire, d2Fire)
    );
    expect(s.unanswered, 1); // D1 answered; D2 unanswered
    expect(s.exhausted, isFalse);
  });

  test('app-open within D2 72h window answers D2 → not exhausted', () {
    final s = RetentionRecall.evaluate(
      d1Fire: d1Fire,
      d2Fire: d2Fire,
      now: d2Deadline.add(const Duration(minutes: 1)),
      lastAppOpenAt: d2Fire.add(const Duration(hours: 24)), // in window
    );
    expect(s.unanswered, 1); // D1 unanswered, D2 answered
    expect(s.exhausted, isFalse);
  });

  test('app-open resets BOTH the counter and the exhausted flag', () {
    // Start from a fully-exhausted state; an app-open zeroes it.
    final reset = RetentionRecall.onAppOpen();
    expect(reset, RetentionRecallState.initial);
    expect(reset.unanswered, 0);
    expect(reset.exhausted, isFalse);
  });
}
