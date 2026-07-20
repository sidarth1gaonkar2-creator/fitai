// Reproduction + regression guard for "some card surfaces keep the previous
// skin's colour after a swap, until a cold restart".
//
// ROOT CAUSE (proven here, not assumed): a card whose OWN build() sets its
// surface to a skin-driven STATIC (FieldManual.field) without that same build
// establishing a dependency on the active theme never gets marked dirty when
// the skin swaps. CupertinoApp rebuilds its CupertinoThemeData on swap and
// Flutter dirties only the elements that DEPENDED on it (via
// CupertinoTheme.of / AppColors.of). A card that reads the static directly has
// no such dependency, so its RenderObject keeps the stale colour.
//
// This is NOT the const-capture bug and NOT the texture cache. The differ is
// dependency, not const-ness: OrdersBlock is non-const yet stale; RankStrip is
// const yet fresh (it watches providers).
//
// The harness below freezes the card's widget instance so the ONLY way it can
// refresh is via its own theme dependency — exactly the on-device situation
// where the dashboard tab stays mounted across a swap.
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/core/theme/app_colors.dart';
import 'package:fitai/core/theme/field_manual.dart';
import 'package:fitai/core/theme/fm_skin.dart';
import 'package:fitai/features/dashboard/presentation/widgets/canteen_card.dart';
import 'package:fitai/features/dashboard/presentation/widgets/orders_block.dart';
import 'package:fitai/features/dashboard/presentation/widgets/rations_panel.dart';
import 'package:fitai/features/themes/domain/app_theme_data.dart';
import 'package:fitai/features/themes/domain/theme_registry.dart';
import 'package:fitai/features/themes/providers/theme_providers.dart';

/// Drives the equipped theme for the harness.
final _equipped = StateProvider<AppThemeData>((_) => defaultTheme);

/// Holds its child instance captured at first build, so a parent rebuild does
/// NOT hand the child a fresh widget. The child element then persists and can
/// only rebuild through its own dependencies — the on-device "tab stays
/// mounted across the swap" condition.
class _Freeze extends StatefulWidget {
  const _Freeze(this.child);
  final Widget child;
  @override
  State<_Freeze> createState() => _FreezeState();
}

class _FreezeState extends State<_Freeze> {
  late final Widget _frozen = widget.child;
  @override
  Widget build(BuildContext context) => _frozen;
}

class _Harness extends ConsumerWidget {
  const _Harness(this.card);
  final Widget card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(_equipped);
    // Mirror app.dart: the equipped skin is published to the static before the
    // tree builds.
    FieldManual.skin = FmSkin.fromTheme(theme);
    final palette =
        AppColors.resolve(theme: theme, brightness: Brightness.dark);
    return CupertinoApp(
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: palette.accent,
        scaffoldBackgroundColor: palette.scaffold,
      ),
      home: CupertinoPageScaffold(
        child: Center(child: _Freeze(card)),
      ),
    );
  }
}

/// The colour of a card's OUTER surface — the first DecoratedBox under it.
Color? _surfaceOf(WidgetTester tester, Type cardType) {
  final box = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(cardType),
          matching: find.byType(DecoratedBox),
        ),
      )
      .first;
  final d = box.decoration;
  return d is BoxDecoration ? d.color : null;
}

Future<void> _pumpAndSwap(
  WidgetTester tester,
  Widget card,
  Type cardType,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeThemeProvider.overrideWith((ref) => ref.watch(_equipped)),
      ],
      child: _Harness(card),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const fmField = Color(0xFF21241F); // Field Manual surface
  const nightField = Color(0xFF0A0A0A); // Night Ops surface

  tearDown(() => FieldManual.skin = const FmSkin.fieldManual());

  testWidgets('OrdersBlock surface follows a live skin swap', (tester) async {
    await _pumpAndSwap(
      tester,
      const OrdersBlock(workout: null, isRestDay: false, streak: 0),
      OrdersBlock,
    );
    expect(_surfaceOf(tester, OrdersBlock), fmField,
        reason: 'starts on Field Manual');

    // Equip Night Ops WITHOUT remounting the frozen card.
    final el = tester.element(find.byType(_Harness));
    ProviderScope.containerOf(el)
        .read(_equipped.notifier)
        .state = themeById('night_ops');
    await tester.pumpAndSettle();

    expect(_surfaceOf(tester, OrdersBlock), nightField,
        reason: 'OrdersBlock still shows the previous skin — Bug is present');
  });

  testWidgets('CanteenCard surface follows a live skin swap', (tester) async {
    await _pumpAndSwap(
      tester,
      const CanteenCard(glasses: 0, onIncrement: _noop, onDecrement: _noop),
      CanteenCard,
    );
    expect(_surfaceOf(tester, CanteenCard), fmField);

    final el = tester.element(find.byType(_Harness));
    ProviderScope.containerOf(el)
        .read(_equipped.notifier)
        .state = themeById('night_ops');
    await tester.pumpAndSettle();

    expect(_surfaceOf(tester, CanteenCard), nightField,
        reason: 'CanteenCard still shows the previous skin — Bug is present');
  });

  testWidgets('RationsPanel already follows the swap (control)', (tester) async {
    // The card that works today — establishes an AppColors.of dependency at
    // the top of build. Proves the harness detects a WORKING card as working.
    await _pumpAndSwap(
      tester,
      const RationsPanel(
        calories: 0,
        calorieTarget: 2000,
        burned: 0,
        protein: 0,
        proteinTarget: 150,
        carbs: 0,
        carbsTarget: 200,
        fat: 0,
        fatTarget: 60,
      ),
      RationsPanel,
    );
    expect(_surfaceOf(tester, RationsPanel), fmField);

    final el = tester.element(find.byType(_Harness));
    ProviderScope.containerOf(el)
        .read(_equipped.notifier)
        .state = themeById('night_ops');
    await tester.pumpAndSettle();

    expect(_surfaceOf(tester, RationsPanel), nightField);
  });
}

void _noop() {}
