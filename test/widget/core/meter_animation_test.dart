import 'package:fitai/core/widgets/meter_bar.dart';
import 'package:fitai/features/dashboard/presentation/widgets/kcal_gauge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one motion system for value meters: rings/bars tween from their
/// previous value to the new one, and reduced motion snaps instantly.
Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return CupertinoApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: Center(child: child),
      ),
    ),
  );
}

/// The gauge's big numeral is its only pure-integer Text ("500"); the
/// sub-label ("OF 2000 KCAL") never parses as an int.
int? _bigNumber(WidgetTester tester) {
  final texts = tester.widgetList<Text>(
    find.descendant(of: find.byType(KcalGauge), matching: find.byType(Text)),
  );
  for (final t in texts) {
    final v = int.tryParse(t.data ?? '');
    if (v != null) return v;
  }
  return null;
}

void main() {
  group('KcalGauge motion', () {
    testWidgets('sweeps from zero on first appearance, then settles',
        (tester) async {
      await tester
          .pumpWidget(_wrap(const KcalGauge(consumed: 500, target: 2000)));
      // First frame of the entry sweep starts at zero.
      expect(find.text('0'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('500'), findsOneWidget);
      expect(find.text('OF 2000 KCAL'), findsOneWidget);
    });

    testWidgets('tween target updates on value change — counts from the '
        'previous value, not zero and not an instant jump', (tester) async {
      await tester
          .pumpWidget(_wrap(const KcalGauge(consumed: 500, target: 2000)));
      await tester.pumpAndSettle();

      await tester
          .pumpWidget(_wrap(const KcalGauge(consumed: 1000, target: 2000)));
      await tester.pump(const Duration(milliseconds: 400));
      final mid = _bigNumber(tester);
      expect(mid, isNotNull);
      expect(mid, greaterThan(500));
      expect(mid, lessThan(1000));

      await tester.pumpAndSettle();
      expect(find.text('1000'), findsOneWidget);
    });

    testWidgets('disableAnimations short-circuits to an instant snap',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const KcalGauge(consumed: 500, target: 2000),
        disableAnimations: true,
      ));
      await tester.pump();
      expect(find.text('500'), findsOneWidget);

      await tester.pumpWidget(_wrap(
        const KcalGauge(consumed: 1200, target: 2000),
        disableAnimations: true,
      ));
      await tester.pump();
      // No count-up frames — straight to the new value.
      expect(find.text('1200'), findsOneWidget);
    });
  });

  group('MeterBar motion', () {
    const fill = Color(0xFFE8E4D8);

    double factor(WidgetTester tester) => tester
        .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .widthFactor!;

    testWidgets('sweeps from the previous fraction on value change',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const SizedBox(width: 200, child: MeterBar(fraction: 0.25, fill: fill)),
      ));
      await tester.pumpAndSettle();
      expect(factor(tester), moreOrLessEquals(0.25, epsilon: 0.001));

      await tester.pumpWidget(_wrap(
        const SizedBox(width: 200, child: MeterBar(fraction: 0.75, fill: fill)),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      // Mid-flight: above where it was, short of where it's going.
      expect(factor(tester), greaterThan(0.25));
      expect(factor(tester), lessThan(0.75));

      await tester.pumpAndSettle();
      expect(factor(tester), moreOrLessEquals(0.75, epsilon: 0.001));
    });

    testWidgets('fill color tweens on change (e.g. bone → alert)',
        (tester) async {
      const from = Color(0xFF000000);
      const to = Color(0xFFFFFFFF);
      Color? fillColor(WidgetTester tester) => tester
          .widget<Container>(find.descendant(
            of: find.byType(FractionallySizedBox),
            matching: find.byType(Container),
          ))
          .color;

      await tester.pumpWidget(_wrap(
        const SizedBox(width: 200, child: MeterBar(fraction: 0.5, fill: from)),
      ));
      await tester.pumpAndSettle();
      expect(fillColor(tester), from);

      await tester.pumpWidget(_wrap(
        const SizedBox(width: 200, child: MeterBar(fraction: 0.5, fill: to)),
      ));
      await tester.pump(const Duration(milliseconds: 400));
      expect(fillColor(tester), isNot(from));
      expect(fillColor(tester), isNot(to));

      await tester.pumpAndSettle();
      expect(fillColor(tester), to);
    });

    testWidgets('disableAnimations snaps the bar instantly', (tester) async {
      await tester.pumpWidget(_wrap(
        const SizedBox(width: 200, child: MeterBar(fraction: 0.25, fill: fill)),
        disableAnimations: true,
      ));
      await tester.pump();
      expect(factor(tester), moreOrLessEquals(0.25, epsilon: 0.001));

      await tester.pumpWidget(_wrap(
        const SizedBox(width: 200, child: MeterBar(fraction: 0.9, fill: fill)),
        disableAnimations: true,
      ));
      await tester.pump();
      expect(factor(tester), moreOrLessEquals(0.9, epsilon: 0.001));
    });
  });
}
