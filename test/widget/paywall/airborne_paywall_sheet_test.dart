import 'package:fitai/features/paywall/domain/paywall_plans.dart';
import 'package:fitai/features/paywall/presentation/airborne_paywall_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

const _annual = PaywallPlan(
  period: PaywallPeriod.annual,
  priceString: r'$59.99',
  trialDays: 7,
  savingsPercent: 50,
);
const _monthly = PaywallPlan(
  period: PaywallPeriod.monthly,
  priceString: r'$9.99',
);

void main() {
  /// Scrolls [finder] into the sheet's viewport (it can sit below the fold in
  /// the 800×600 test window), then taps it.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  /// Pumps a host screen whose button opens the paywall sheet, then opens it.
  /// Returns a getter for the sheet's eventual result.
  Future<Future<bool> Function()> openSheet(
    WidgetTester tester, {
    required LoadPlans loadPlans,
    PurchasePlan? purchase,
    RestorePurchases? restore,
  }) async {
    Future<bool>? result;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  result = showAirbornePaywallSheet(
                    context,
                    loadPlans: loadPlans,
                    purchase: purchase ??
                        (_) async => PaywallPurchaseOutcome.failed,
                    restore: restore ?? () async => false,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result!;
  }

  testWidgets('renders manifest, doctrine, and plans with annual defaulted',
      (tester) async {
    await openSheet(tester, loadPlans: () async => [_annual, _monthly]);

    // Header + benefits manifest.
    expect(find.text('VOLUNTEERS ONLY'), findsOneWidget);
    expect(find.text('COACH MESSAGES / DAY'), findsOneWidget);
    expect(find.textContaining('100'), findsWidgets);
    expect(find.text('ALL ISSUED'), findsOneWidget);

    // The doctrine line — rank is never for sale.
    expect(
      find.text("YOUR RANK IS EARNED.\nAIRBORNE DOESN'T TOUCH IT."),
      findsOneWidget,
    );

    // Plans, savings chip, and annual-first fine print (trial + price).
    expect(find.text('ANNUAL'), findsOneWidget);
    expect(find.text('MONTHLY'), findsOneWidget);
    expect(find.text('SAVE 50%'), findsOneWidget);
    expect(
      find.textContaining(r'7 days free, then $59.99/year.'),
      findsOneWidget,
    );
  });

  testWidgets('selecting monthly updates the fine print', (tester) async {
    await openSheet(tester, loadPlans: () async => [_annual, _monthly]);

    await tapVisible(tester, find.text('MONTHLY'));
    await tester.pumpAndSettle();

    expect(find.textContaining(r'$9.99/month.'), findsOneWidget);
    expect(find.textContaining('free, then'), findsNothing);
  });

  testWidgets('successful purchase shows the welcome moment and pops true',
      (tester) async {
    PaywallPlan? purchased;
    final result = await openSheet(
      tester,
      loadPlans: () async => [_annual, _monthly],
      purchase: (plan) async {
        purchased = plan;
        return PaywallPurchaseOutcome.success;
      },
    );

    await tapVisible(tester, find.widgetWithText(CupertinoButton, 'GO AIRBORNE'));
    await tester.pumpAndSettle();

    expect(purchased, same(_annual));
    expect(find.text('WELCOME ABOARD'), findsOneWidget);

    await tester.tap(find.text('CARRY ON'));
    await tester.pumpAndSettle();
    expect(await result(), isTrue);
  });

  testWidgets('cancelled purchase keeps the sheet open and quiet',
      (tester) async {
    await openSheet(
      tester,
      loadPlans: () async => [_annual, _monthly],
      purchase: (_) async => PaywallPurchaseOutcome.cancelled,
    );

    await tapVisible(tester, find.widgetWithText(CupertinoButton, 'GO AIRBORNE'));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME ABOARD'), findsNothing);
    expect(find.text('ANNUAL'), findsOneWidget);
  });

  testWidgets('load failure shows retry, and retry recovers', (tester) async {
    var calls = 0;
    await openSheet(
      tester,
      loadPlans: () async {
        calls++;
        if (calls == 1) throw StateError('offline');
        return [_annual, _monthly];
      },
    );

    expect(find.textContaining("Couldn't reach the App Store"), findsOneWidget);

    await tapVisible(tester, find.text('RETRY'));
    await tester.pumpAndSettle();

    expect(find.text('ANNUAL'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('restore that ends entitled closes the sheet with true',
      (tester) async {
    final result = await openSheet(
      tester,
      loadPlans: () async => [_annual, _monthly],
      restore: () async => true,
    );

    await tapVisible(tester, find.text('RESTORE PURCHASES'));
    await tester.pumpAndSettle();

    expect(find.text('ANNUAL'), findsNothing);
    expect(await result(), isTrue);
  });

  testWidgets('close pops false without touching the store', (tester) async {
    var purchaseCalls = 0;
    final result = await openSheet(
      tester,
      loadPlans: () async => [_annual, _monthly],
      purchase: (_) async {
        purchaseCalls++;
        return PaywallPurchaseOutcome.success;
      },
    );

    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pumpAndSettle();

    expect(purchaseCalls, 0);
    expect(await result(), isFalse);
  });
}
