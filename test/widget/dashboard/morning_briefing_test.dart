import 'package:fitai/features/dashboard/presentation/widgets/canteen_card.dart';
import 'package:fitai/features/dashboard/presentation/widgets/kcal_gauge.dart';
import 'package:fitai/features/dashboard/presentation/widgets/orders_block.dart';
import 'package:fitai/features/dashboard/presentation/widgets/rank_strip.dart';
import 'package:fitai/features/ranks/domain/military_ranks.dart';
import 'package:fitai/features/ranks/providers/rank_providers.dart';
import 'package:fitai/models/workout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
          child: SizedBox(width: 380, child: child),
        ),
      ),
    );

void main() {
  group('OrdersBlock', () {
    testWidgets('training day with nothing logged leads with the brass CTA',
        (tester) async {
      await tester.pumpWidget(_host(
        const OrdersBlock(workout: null, isRestDay: false, streak: 0),
      ));
      expect(find.text('REPORT TO THE BAR'), findsOneWidget);
      expect(find.text('LOG WORKOUT'), findsOneWidget);
      // Streak 0 shows no chip.
      expect(find.textContaining('DAY '), findsNothing);
    });

    testWidgets('rest day stands down quietly', (tester) async {
      await tester.pumpWidget(_host(
        const OrdersBlock(workout: null, isRestDay: true, streak: 4),
      ));
      // The streak chip counts up on the shared Motion clock — settle first.
      await tester.pumpAndSettle();
      expect(find.text('STAND DOWN'), findsOneWidget);
      expect(find.text('LOG ANYWAY'), findsOneWidget);
      expect(find.text('DAY 4'), findsOneWidget);
    });

    testWidgets('logged workout reads mission complete with praise and chip',
        (tester) async {
      final workout = Workout()
        ..title = 'Heavy Push Day'
        ..date = DateTime(2026, 7, 14)
        ..durationMinutes = 45;
      await tester.pumpWidget(_host(
        OrdersBlock(
          workout: workout,
          isRestDay: false,
          streak: 12,
          multiplier: 1.7,
        ),
      ));
      // The streak chip counts up on the shared Motion clock — settle first.
      await tester.pumpAndSettle();
      expect(find.text('MISSION COMPLETE'), findsOneWidget);
      expect(find.text('Heavy Push Day'), findsOneWidget);
      expect(find.text('45 MIN'), findsOneWidget);
      expect(find.text('DAY 12 · ×1.7'), findsOneWidget);
      // The praise line is stable for a given date, not random per rebuild.
      expect(
        find.text(OrdersBlock.praiseOfTheDay(DateTime.now())),
        findsOneWidget,
      );
    });
  });

  group('KcalGauge', () {
    testWidgets('shows consumed against target', (tester) async {
      await tester.pumpWidget(_host(
        const KcalGauge(consumed: 1450, target: 2200),
      ));
      await tester.pumpAndSettle();
      expect(find.text('1450'), findsOneWidget);
      expect(find.text('OF 2200 KCAL'), findsOneWidget);
    });

    testWidgets('over target states the overage honestly', (tester) async {
      await tester.pumpWidget(_host(
        const KcalGauge(consumed: 2440, target: 2200),
      ));
      await tester.pumpAndSettle();
      expect(find.text('OVER BY 240'), findsOneWidget);
    });

    testWidgets('tap flips to net remaining when burned data exists',
        (tester) async {
      await tester.pumpWidget(_host(
        const KcalGauge(consumed: 1450, target: 2200, burned: 250),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(KcalGauge));
      await tester.pumpAndSettle();
      // 2200 - 1450 + 250 = 1000 remaining.
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('KCAL REMAINING'), findsOneWidget);
    });
  });

  group('CanteenCard', () {
    testWidgets('steppers report and decrement disables at zero',
        (tester) async {
      var up = 0;
      var down = 0;
      await tester.pumpWidget(_host(
        CanteenCard(
          glasses: 0,
          onIncrement: () => up++,
          onDecrement: () => down++,
        ),
      ));
      await tester.tap(find.byIcon(CupertinoIcons.plus));
      await tester.tap(find.byIcon(CupertinoIcons.minus));
      expect(up, 1);
      expect(down, 0); // disabled at zero
    });
  });

  group('RankStrip', () {
    RankCalculation calcAt(double points) => RankCalculation(
          overall: rankFromPoints(points),
          overallPoints: points,
          muscleGroupPoints: const {},
          muscleGroupRanks: const {},
          exerciseScores: const {'bench-press': 1.0},
          exerciseRanks: const {},
          exerciseBestWeightKg: const {},
          bodyWeightKg: 80,
        );

    Widget hostWithCalc(RankCalculation calc) => ProviderScope(
          overrides: [
            rankCalculatorProvider.overrideWith((ref) async => calc),
          ],
          child: _host(const RankStrip()),
        );

    testWidgets('shows rank name and promotion distance on the 0-900 scale',
        (tester) async {
      await tester.pumpWidget(hostWithCalc(calcAt(4.5)));
      await tester.pumpAndSettle();
      expect(find.text('SERGEANT'), findsOneWidget);
      expect(find.text('450 → 500 SSG'), findsOneWidget);
    });

    testWidgets('apex rank reads APEX with a full rule', (tester) async {
      await tester.pumpWidget(hostWithCalc(calcAt(9.0)));
      await tester.pumpAndSettle();
      expect(find.text('SERGEANT MAJOR OF THE ARMY'), findsOneWidget);
      expect(find.text('RANK SCORE 900 — APEX'), findsOneWidget);
    });

    testWidgets('no rankable data teaches how to earn a rank', (tester) async {
      const empty = RankCalculation.empty;
      await tester.pumpWidget(hostWithCalc(empty));
      await tester.pumpAndSettle();
      expect(find.text('PRIVATE'), findsOneWidget);
      expect(
        find.text('Complete workouts to earn your rank.'),
        findsOneWidget,
      );
    });
  });
}
