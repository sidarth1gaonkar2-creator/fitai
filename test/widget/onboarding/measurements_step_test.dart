import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai/features/onboarding/presentation/widgets/measurements_step.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('MeasurementsStep', () {
    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpApp(const MeasurementsStep());

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Weight is required'), findsOneWidget);
      expect(find.text('Height is required'), findsOneWidget);
    });

    testWidgets('shows error for non-positive weight', (tester) async {
      await tester.pumpApp(const MeasurementsStep());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '-5');
      await tester.enterText(fields.at(1), '175');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Weight must be a positive number'), findsOneWidget);
    });

    testWidgets('shows error for non-positive height', (tester) async {
      await tester.pumpApp(const MeasurementsStep());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '75');
      await tester.enterText(fields.at(1), '0');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Height must be a positive number'), findsOneWidget);
    });

    testWidgets('renders weight and height labels', (tester) async {
      await tester.pumpApp(const MeasurementsStep());

      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('Height (cm)'), findsOneWidget);
    });
  });
}
