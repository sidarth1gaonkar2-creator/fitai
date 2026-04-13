import 'package:isar/isar.dart';
import 'enums.dart';

part 'supplement.g.dart';

@collection
class Supplement {
  Id id = Isar.autoIncrement;

  late String name;

  late String dosage;

  late String unit;

  @Enumerated(EnumType.ordinal)
  late SupplementTiming timing;

  bool isActive = true;
}
