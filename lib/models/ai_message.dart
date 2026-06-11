import 'package:isar/isar.dart';
import 'enums.dart';

part 'ai_message.g.dart';

@collection
class AIMessage {
  Id id = Isar.autoIncrement;

  /// Firebase uid that owns this message. Every query filters by it so chat
  /// history is scoped per account and never leaks across sign-ins. An empty
  /// string marks legacy pre-scoping rows, which are purged once on upgrade.
  @Index()
  String uid = '';

  @enumerated
  late MessageRole role;

  late String content;

  DateTime timestamp = DateTime.now();
}
