import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitai/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('renders first step (name) initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      expect(find.text("What's your name?"), findsOneWidget);
    });

    testWidgets('progress indicator starts at 1/6', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, closeTo(1 / 6, 0.01));
    });

    testWidgets('no back button on first step', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('navigates to step 2 after entering name', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Alice');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Tell us about yourself'), findsOneWidget);
    });

    testWidgets('back button appears on step 2', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      // Navigate to step 2
      await tester.enterText(find.byType(TextFormField), 'Alice');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
