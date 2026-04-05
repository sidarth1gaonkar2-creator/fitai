import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai/features/onboarding/presentation/widgets/body_info_step.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('BodyInfoStep', () {
    testWidgets('shows validation error for empty age', (tester) async {
      await tester.pumpApp(const BodyInfoStep());

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Age is required'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid age', (tester) async {
      await tester.pumpApp(const BodyInfoStep());

      await tester.enterText(find.byType(TextFormField), '5');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Age must be between 13 and 120'), findsOneWidget);
    });

    testWidgets('shows snackbar when sex not selected', (tester) async {
      await tester.pumpApp(const BodyInfoStep());

      await tester.enterText(find.byType(TextFormField), '25');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Please select your sex'), findsOneWidget);
    });

    testWidgets('renders sex segmented button', (tester) async {
      await tester.pumpApp(const BodyInfoStep());

      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
    });
  });
}
