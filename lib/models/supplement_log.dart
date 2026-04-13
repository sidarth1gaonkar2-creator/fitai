import 'package:isar/isar.dart';

part 'supplement_log.g.dart';

@collection
class SupplementLog {
  Id id = Isar.autoIncrement;

  @Index()
  late int supplementId;

  @Index()
  late DateTime date;

  DateTime? timeTaken;

  bool taken = false;
}
