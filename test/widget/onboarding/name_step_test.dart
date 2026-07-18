import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai/features/onboarding/presentation/widgets/name_step.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('NameStep', () {
    testWidgets('shows validation error when name is empty', (tester) async {
      await tester.pumpApp(const NameStep());

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('does not show error when name is entered', (tester) async {
      await tester.pumpApp(const NameStep());

      await tester.enterText(find.byType(TextFormField), 'John');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsNothing);
    });

    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpApp(const NameStep());

      expect(find.text("What's your name?"), findsOneWidget);
      expect(
        find.text("So the sergeant knows who he's talking to."),
        findsOneWidget,
      );
    });
  });
}
