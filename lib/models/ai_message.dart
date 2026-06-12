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

  // --- AI Coach tool-use proposal (Build 75) --------------------------------
  // When this assistant message carries a tool proposal, [proposalKind] is
  // 'nutrition' or 'workout', [proposalJson] is the validated tool input, and
  // [proposalStatus] tracks the card lifecycle: 'proposed' | 'applied' |
  // 'dismissed' | 'error'. Persisted per-uid so cards survive the 50-message
  // history. Default 'none' = an ordinary text message.
  String? proposalKind;

  String? proposalJson;

  String proposalStatus = 'none';
}
