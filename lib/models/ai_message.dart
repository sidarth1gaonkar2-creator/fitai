import 'package:isar/isar.dart';
import 'enums.dart';

part 'ai_message.g.dart';

@collection
class AIMessage {
  Id id = Isar.autoIncrement;

  @enumerated
  late MessageRole role;

  late String content;

  DateTime timestamp = DateTime.now();
}
