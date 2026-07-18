// Stage-2 sacred-rule guardrail: the Airborne brass mount renders ONLY on the
// user's own current earned rank. A subscriber's locked/future (and past)
// ladder rungs stay base (airborne=false); an inactive subscriber sees base
// everywhere. RankInsignia.airborne is the observable contract.
import 'package:fitai/features/dashboard/presentation/widgets/rank_strip.dart';
import 'package:fitai/features/ranks/domain/military_ranks.dart';
import 'package:fitai/features/ranks/presentation/ranks_screen.dart';
import 'package:fitai/features/ranks/presentation/widgets/rank_badge.dart';
import 'package:fitai/features/ranks/providers/rank_providers.dart';
import 'package:fitai/providers/entitlement_providers.dart';
import 'package:fitai/providers/unit_system_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

RankCalculation _calc(MilitaryRank overall) => RankCalculation(
      overall: overall,
      overallPoints: overall.index.toDouble(),
      muscleGroupPoints: const {},
      muscleGroupRanks: const {},
      exerciseScores: const {'bench-press': 1.0},
      exerciseRanks: const {},
      exerciseBestWeightKg: const {},
      bodyWeightKg: 80,
    );

Widget _host(Widget child,
        {required bool airborne,
        required RankCalculation calc,
        List<Override> extra = const []}) =>
    ProviderScope(
      overrides: [
        rankCalculatorProvider.overrideWith((ref) async => calc),
        airborneActiveProvider.overrideWithValue(airborne),
        ...extra,
      ],
      child: CupertinoApp(home: CupertinoPageScaffold(child: child)),
    );

void main() {
  group('Airborne mount guardrail', () {
    testWidgets('inactive subscriber: rank strip renders base (no mount)',
        (tester) async {
      await tester.pumpWidget(_host(const RankStrip(),
          airborne: false, calc: _calc(MilitaryRank.sergeant_e5)));
      await tester.pumpAndSettle();
      final ins = tester.widgetList<RankInsignia>(find.byType(RankInsignia));
      expect(ins, isNotEmpty);
      expect(ins.every((w) => w.airborne == false), isTrue,
          reason: 'no mount when Airborne is inactive');
    });

    testWidgets('active subscriber: rank strip mounts the current rank',
        (tester) async {
      await tester.pumpWidget(_host(const RankStrip(),
          airborne: true, calc: _calc(MilitaryRank.sergeant_e5)));
      await tester.pumpAndSettle();
      final ins =
          tester.widgetList<RankInsignia>(find.byType(RankInsignia)).toList();
      expect(ins, hasLength(1));
      expect(ins.single.airborne, isTrue);
      expect(ins.single.rank, MilitaryRank.sergeant_e5);
    });

    testWidgets(
        'SACRED RULE: the ladder mounts ONLY the current rung; locked/future '
        'and past rungs stay base', (tester) async {
      const current = MilitaryRank.sergeant_e5;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(_host(const RanksScreen(),
          airborne: true,
          calc: _calc(current),
          extra: [sharedPreferencesProvider.overrideWithValue(prefs)]));
      // Bounded pumps, not pumpAndSettle: the current rung pulses forever.
      await tester.pump(); // loading frame
      await tester.pump(const Duration(milliseconds: 50)); // async calc resolves

      final all =
          tester.widgetList<RankInsignia>(find.byType(RankInsignia)).toList();
      expect(all, isNotEmpty);

      // The whole guardrail in one line: nothing but the user's current rank is
      // ever mounted — no locked/future/past/other-rank insignia wears brass.
      for (final w in all.where((w) => w.airborne)) {
        expect(w.rank, current,
            reason: 'only the current earned rank may be mounted');
      }

      // The current rank IS mounted for the subscriber (hero + current rung).
      final mounted = all.where((w) => w.airborne).toList();
      expect(mounted, isNotEmpty);

      // A future/locked rung (SMA) and a past/earned rung (PVT) are present in
      // the ladder and stay base.
      final sma = all.where((w) => w.rank == MilitaryRank.sgmArmy_e10);
      final pvt = all.where((w) => w.rank == MilitaryRank.private_e1);
      expect(sma, isNotEmpty);
      expect(sma.every((w) => !w.airborne), isTrue,
          reason: 'future/locked rung must never be mounted');
      expect(pvt.every((w) => !w.airborne), isTrue,
          reason: 'past earned rung must never be mounted');
    });
  });
}
