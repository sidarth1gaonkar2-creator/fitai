import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitai/core/utils/scoped_prefs.dart';
import 'package:fitai/features/ranks/domain/exercise_standards.dart';
import 'package:fitai/providers/custom_exercise_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomExerciseRegistry', () {
    test('stores and retrieves a custom group (case-insensitive)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final reg = CustomExerciseRegistry(prefs, 'u1');

      expect(reg.groupFor('Cable Y-Raise'), isNull);
      expect(reg.isKnown('Cable Y-Raise'), isFalse);

      await reg.setGroup('Cable Y-Raise', RankGroup.shoulders);

      expect(reg.groupFor('Cable Y-Raise'), RankGroup.shoulders);
      expect(reg.groupFor('cable y-raise'), RankGroup.shoulders);
      expect(reg.isKnown('CABLE Y-RAISE'), isTrue);
    });

    test('persists across registry instances over the same prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await CustomExerciseRegistry(prefs, 'u1')
          .setGroup('JM Press', RankGroup.arms);

      expect(CustomExerciseRegistry(prefs, 'u1').groupFor('JM Press'),
          RankGroup.arms);
    });

    test('registry is per-uid — another account sees nothing', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await CustomExerciseRegistry(prefs, 'A')
          .setGroup('Sled Push', RankGroup.legs);

      expect(CustomExerciseRegistry(prefs, 'B').groupFor('Sled Push'), isNull);
      expect(
          CustomExerciseRegistry(prefs, 'A').groupFor('Sled Push'),
          RankGroup.legs);
    });

    test('signed out: reads empty and setGroup writes no keys', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final reg = CustomExerciseRegistry(prefs, null);

      await reg.setGroup('Anything', RankGroup.core);
      expect(reg.groupFor('Anything'), isNull);
      expect(prefs.getKeys(), isEmpty);
    });

    test('re-categorising overwrites the prior group (no duplicate)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final reg = CustomExerciseRegistry(prefs, 'u1');

      await reg.setGroup('Sled Push', RankGroup.legs);
      await reg.setGroup('sled push', RankGroup.back); // same name, new group
      expect(reg.groupFor('Sled Push'), RankGroup.back);
    });

    test('tolerates a corrupt stored value and recovers', () async {
      SharedPreferences.setMockInitialValues(
        {scopedKey('custom_exercise_groups_v1', 'u1'): 'not valid json'},
      );
      final prefs = await SharedPreferences.getInstance();
      final reg = CustomExerciseRegistry(prefs, 'u1');

      expect(reg.groupFor('Anything'), isNull); // no crash
      await reg.setGroup('Anything', RankGroup.core);
      expect(reg.groupFor('Anything'), RankGroup.core);
    });
  });
}
