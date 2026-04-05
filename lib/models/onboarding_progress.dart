import 'package:isar/isar.dart';

part 'onboarding_progress.g.dart';

@collection
class OnboardingProgress {
  Id id = Isar.autoIncrement;

  String? name;
  int? age;
  String? sex;
  double? weightKg;
  double? heightCm;
  String? goal;
  String? activityLevel;
  int lastCompletedStep = 0;
  DateTime updatedAt = DateTime.now();
}
