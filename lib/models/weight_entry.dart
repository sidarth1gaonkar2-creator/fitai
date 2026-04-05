import 'package:isar/isar.dart';

part 'weight_entry.g.dart';

@collection
class WeightEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  late double weightKg;
}
