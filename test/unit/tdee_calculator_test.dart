import 'package:flutter_test/flutter_test.dart';
import 'package:fitai/core/utils/tdee_calculator.dart';
import 'package:fitai/models/enums.dart';

void main() {
  group('calculateBMR', () {
    test('male BMR: 80kg, 180cm, 25yo = 1780', () {
      final bmr = calculateBMR(
        weightKg: 80,
        heightCm: 180,
        age: 25,
        sex: Sex.male,
      );
      // 10*80 + 6.25*180 - 5*25 + 5 = 800 + 1125 - 125 + 5 = 1805
      expect(bmr, 1805);
    });

    test('female BMR: 60kg, 165cm, 30yo = 1270.25', () {
      final bmr = calculateBMR(
        weightKg: 60,
        heightCm: 165,
        age: 30,
        sex: Sex.female,
      );
      // 10*60 + 6.25*165 - 5*30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
      expect(bmr, 1320.25);
    });

    test('male and female differ by 166', () {
      final maleBmr = calculateBMR(
        weightKg: 70,
        heightCm: 170,
        age: 25,
        sex: Sex.male,
      );
      final femaleBmr = calculateBMR(
        weightKg: 70,
        heightCm: 170,
        age: 25,
        sex: Sex.female,
      );
      expect(maleBmr - femaleBmr, 166);
    });
  });

  group('calculateTDEE', () {
    const bmr = 1800.0;

    test('sedentary multiplier = 1.2', () {
      final tdee =
          calculateTDEE(bmr: bmr, activityLevel: ActivityLevel.sedentary);
      expect(tdee, closeTo(2160, 0.01));
    });

    test('light multiplier = 1.375', () {
      final tdee =
          calculateTDEE(bmr: bmr, activityLevel: ActivityLevel.light);
      expect(tdee, closeTo(2475, 0.01));
    });

    test('moderate multiplier = 1.55', () {
      final tdee =
          calculateTDEE(bmr: bmr, activityLevel: ActivityLevel.moderate);
      expect(tdee, closeTo(2790, 0.01));
    });

    test('active multiplier = 1.725', () {
      final tdee =
          calculateTDEE(bmr: bmr, activityLevel: ActivityLevel.active);
      expect(tdee, closeTo(3105, 0.01));
    });

    test('very active multiplier = 1.9', () {
      final tdee =
          calculateTDEE(bmr: bmr, activityLevel: ActivityLevel.veryActive);
      expect(tdee, closeTo(3420, 0.01));
    });
  });
}
