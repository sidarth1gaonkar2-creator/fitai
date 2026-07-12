import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../core/utils/logger.dart';
import '../../../models/ai_message.dart';
import '../data/coach_actions.dart';
import '../../../models/enums.dart';
import '../../../providers/custom_exercise_provider.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/unit_system_provider.dart';
import '../../../services/anthropic_service.dart';
import '../domain/coach_context_builder.dart';
import '../domain/coach_exercise_resolver.dart';

const _systemPrompt =
    'You are DrillFit Coach, a knowledgeable and supportive fitness and '
    'nutrition expert with a no-nonsense drill-sergeant edge. You give '
    "personalized, actionable advice based on the user's workout history, "
    'nutrition data, and goals. Keep responses concise (under 200 words unless '
    'asked for more), practical, and encouraging.\n\n'
    'TOOLS: You can propose two actions — update_nutrition_goals and '
    'create_workout — but ONLY when the user explicitly asks to change their '
    'goals or wants a workout/plan. Never propose a tool for general chat or '
    'questions. Use at MOST ONE tool call per response. You never apply changes '
    'yourself: the app shows the user a confirmation card and only their tap '
    'applies it. Keep each tool rationale in your drill-sergeant character.\n'
    'For create_workout, suggestedWeightKg MUST be in KILOGRAMS and derive from '
    "the user's ACTUAL lift history in the context below — a sensible working "
    'weight is roughly 80–90% of a recent best for the target rep range. Use '
    'null for any exercise with no history; never invent a number.';

/// Max messages persisted locally per user; older ones are trimmed on save.
const _maxStoredMessages = 50;

/// Max messages sent to the proxy per request — independent of how many are
/// stored or displayed.
const _maxContextMessages = 12;

/// One-time flag marking that legacy pre-uid-scoping chat rows were purged.
const _unscopedPurgedKey = 'aiCoachUnscopedPurged';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.isWaitingForStream = false,
    this.streamingContent = '',
    this.errorMessage,
    this.errorIsDailyLimit = false,
  });

  final List<AIMessage> messages;
  final bool isStreaming;
  final bool isWaitingForStream;
  final String streamingContent;
  final String? errorMessage;

  /// True when [errorMessage] is the server's daily-cap 429 — the screen
  /// shows the Airborne upsell for it (free tier only) instead of the generic
  /// error dialog.
  final bool errorIsDailyLimit;

  ChatState copyWith({
    List<AIMessage>? messages,
    bool? isStreaming,
    bool? isWaitingForStream,
    String? streamingContent,
    String? Function()? errorMessage,
    bool? errorIsDailyLimit,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      isWaitingForStream: isWaitingForStream ?? this.isWaitingForStream,
      streamingContent: streamingContent ?? this.streamingContent,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
      errorIsDailyLimit: errorIsDailyLimit ?? this.errorIsDailyLimit,
    );
  }
}

class AIChatController extends StateNotifier<ChatState> {
  AIChatController(this._ref, this._anthropic, this._uid)
      : super(const ChatState()) {
    _loadHistory();
  }

  final Ref _ref;
  final AnthropicService? _anthropic;

  /// Firebase uid this controller is scoped to. Null when signed out — in that
  /// case nothing is loaded, persisted, or sent.
  final String? _uid;

  Isar get _isar => _ref.read(isarProvider);

  Future<void> _loadHistory() async {
    await _purgeLegacyUnscopedMessages();

    final uid = _uid;
    if (uid == null) {
      // Signed out — show nothing and persist nothing.
      if (mounted) state = state.copyWith(messages: const []);
      return;
    }

    try {
      final messages = await _isar.aIMessages
          .filter()
          .uidEqualTo(uid)
          .sortByTimestamp()
          .findAll();
      if (!mounted) return;
      state = state.copyWith(messages: messages);
    } catch (_) {
      // A load failure shouldn't crash the screen — start from an empty chat.
      if (!mounted) return;
      state = state.copyWith(messages: const []);
    }
  }

  /// Deletes pre-scoping global chat rows (uid == '') exactly once after this
  /// upgrade so old data is discarded, never migrated to any account.
  Future<void> _purgeLegacyUnscopedMessages() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      if (prefs.getBool(_unscopedPurgedKey) ?? false) return;
      await _isar.writeTxn(() async {
        await _isar.aIMessages.filter().uidIsEmpty().deleteAll();
      });
      await prefs.setBool(_unscopedPurgedKey, true);
    } catch (_) {
      // Best-effort; will retry on a later launch if it failed.
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (state.isStreaming || state.isWaitingForStream) return;

    if (_anthropic == null) {
      state = state.copyWith(
        errorMessage: () =>
            "AI Coach isn't set up. A backend proxy (AI_PROXY_URL) must be "
            'configured.',
      );
      return;
    }

    final uid = _uid;
    if (uid == null) {
      state = state.copyWith(
        errorMessage: () => 'Sign in to use the AI Coach.',
      );
      return;
    }

    // Save user message (scoped to this uid, trimmed to the 50-message cap).
    final userMsg = AIMessage()
      ..uid = uid
      ..role = MessageRole.user
      ..content = text.trim()
      ..timestamp = DateTime.now();

    await _persist(userMsg);
    if (!mounted) return;

    state = state.copyWith(
      messages: _capInMemory([...state.messages, userMsg]),
      isWaitingForStream: true,
      streamingContent: '',
      errorMessage: () => null,
    );

    try {
      // Build user context
      final context = await CoachContextBuilder.build(_ref);
      final systemWithContext = '$_systemPrompt\n\n'
          '$coachWorkoutSelectionGuidance\n\n'
          '$coachExerciseCatalogue\n\n'
          'Current user context:\n$context';

      // Prepare message history (last 20 messages)
      final history = state.messages
          .take(state.messages.length) // all messages
          .toList();
      final recentHistory = history.length > _maxContextMessages
          ? history.sublist(history.length - _maxContextMessages)
          : history;

      final apiMessages = recentHistory
          .map((m) => (
                role: m.role == MessageRole.user ? 'user' : 'assistant',
                content: m.content,
              ))
          .toList();

      // Stream response — fall back to non-streaming if the stream fails
      // before any chunk arrives.
      final buffer = StringBuffer();
      CoachToolUse? capturedTool;
      bool firstChunk = true;
      bool streamFailedBeforeFirstChunk = false;

      try {
        await for (final event in _anthropic.streamMessage(
          systemPrompt: systemWithContext,
          messages: apiMessages,
        )) {
          if (!mounted) return;

          if (firstChunk) {
            firstChunk = false;
            state = state.copyWith(
              isWaitingForStream: false,
              isStreaming: true,
            );
          }

          if (event is CoachTextDelta) {
            buffer.write(event.text);
            state = state.copyWith(streamingContent: buffer.toString());
          } else if (event is CoachToolUse) {
            // One proposal per response (enforced server-side); keep the latest.
            capturedTool = event;
          }
        }
      } catch (streamErr) {
        if (streamErr is AnthropicRateLimitException) {
          // Daily cap hit — terminal. Don't burn a second call on the
          // non-streaming fallback; surface the limit notice.
          rethrow;
        }
        if (firstChunk) {
          // Nothing streamed yet — try non-streaming fallback.
          streamFailedBeforeFirstChunk = true;
        } else {
          rethrow;
        }
      }

      if (streamFailedBeforeFirstChunk) {
        final result = await _anthropic.sendMessage(
          systemPrompt: systemWithContext,
          messages: apiMessages,
        );
        buffer.write(result.text);
        capturedTool ??= result.toolUse;
      }

      if (!mounted) return;

      // Save assistant message (same uid scope + 50-message cap).
      final assistantMsg = AIMessage()
        ..uid = uid
        ..role = MessageRole.assistant
        ..content = buffer.toString()
        ..timestamp = DateTime.now();
      if (capturedTool != null) {
        // Ground a workout proposal in the fine-muscle library before showing
        // it: snap names to canonical exercises (T1) and register any declared
        // off-library muscle (T2) so the workout ranks under the right group
        // instead of falling through to Chest.
        if (capturedTool.name == 'create_workout') {
          capturedTool = await _resolveWorkoutProposal(capturedTool);
        }
        _attachProposal(assistantMsg, capturedTool);
      }

      await _persist(assistantMsg);
      if (!mounted) return;

      state = state.copyWith(
        messages: _capInMemory([...state.messages, assistantMsg]),
        isStreaming: false,
        isWaitingForStream: false,
        streamingContent: '',
      );
    } on SocketException {
      // Offline is expected, not a bug — info breadcrumb, not an error.
      AppLogger.log('AI coach: network unreachable');
      if (!mounted) return;
      state = state.copyWith(
        isStreaming: false,
        isWaitingForStream: false,
        streamingContent: '',
        errorMessage: () =>
            'No internet connection. Connect to the network and try again.',
        errorIsDailyLimit: false,
      );
    } on AnthropicException catch (e, st) {
      // Rate-limit / daily-cap is an expected 429, not a bug — don't error-log.
      if (e is! AnthropicRateLimitException) {
        AppLogger.error('AI coach: Anthropic error', error: e, stack: st);
      }
      if (!mounted) return;
      // The daily-limit message is already user-friendly — show it verbatim.
      state = state.copyWith(
        isStreaming: false,
        isWaitingForStream: false,
        streamingContent: '',
        errorMessage: () => e is AnthropicRateLimitException
            ? e.message
            : _friendlyError(e.message),
        errorIsDailyLimit: e is AnthropicRateLimitException,
      );
    } catch (e, st) {
      AppLogger.error('AI coach: unexpected send failure', error: e, stack: st);
      if (!mounted) return;
      state = state.copyWith(
        isStreaming: false,
        isWaitingForStream: false,
        streamingContent: '',
        errorMessage: () =>
            "Couldn't reach the AI coach. Check your connection and try again.",
        errorIsDailyLimit: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(
      errorMessage: () => null,
      errorIsDailyLimit: false,
    );
  }

  Future<void> clearHistory() async {
    final uid = _uid;
    try {
      if (uid != null) {
        await _isar.writeTxn(() async {
          await _isar.aIMessages.filter().uidEqualTo(uid).deleteAll();
        });
      }
    } catch (_) {
      // Ignore — clearing is best-effort.
    }
    if (!mounted) return;
    state = const ChatState();
  }

  /// Persists [msg] and enforces the per-user 50-message cap atomically: the
  /// insert and the trim of the oldest overflow run in one write txn, so there
  /// is never a window where more than 50 rows exist for this uid.
  Future<void> _persist(AIMessage msg) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.aIMessages.put(msg);
        final stored = await _isar.aIMessages
            .filter()
            .uidEqualTo(msg.uid)
            .sortByTimestamp()
            .findAll();
        if (stored.length > _maxStoredMessages) {
          final overflow = stored
              .take(stored.length - _maxStoredMessages)
              .map((m) => m.id)
              .toList();
          await _isar.aIMessages.deleteAll(overflow);
        }
      });
    } catch (_) {
      // Best-effort persistence; the message still appears in the session.
    }
  }

  /// Mirrors the stored 50-message cap in memory so the display matches disk.
  List<AIMessage> _capInMemory(List<AIMessage> messages) =>
      messages.length > _maxStoredMessages
          ? messages.sublist(messages.length - _maxStoredMessages)
          : messages;

  /// Attaches a validated tool proposal to [msg] for an inline card. The bounds
  /// check mirrors the server clamps (TASK 4.2) — out-of-bounds renders an error
  /// card ('error'), never an appliable one.
  void _attachProposal(AIMessage msg, CoachToolUse tool) {
    final kind = switch (tool.name) {
      'update_nutrition_goals' => 'nutrition',
      'create_workout' => 'workout',
      _ => null,
    };
    if (kind == null) return;
    msg.proposalKind = kind;
    msg.proposalJson = jsonEncode(tool.input);
    msg.proposalStatus =
        _proposalWithinBounds(kind, tool.input) ? 'proposed' : 'error';
  }

  /// Grounds a create_workout proposal in the fine-muscle library before it's
  /// shown/applied. For each exercise: snap its name to a canonical library
  /// exercise (Tier 1); else, if the model declared a valid off-library muscle
  /// in `notes`, record that group in the custom-exercise registry (Tier 2) so
  /// it ranks under the right group; else leave it untouched (Tier 3 — stays
  /// unranked at save, never silently filed as Chest). Returns a new tool with
  /// canonicalised names + cleaned notes.
  Future<CoachToolUse> _resolveWorkoutProposal(CoachToolUse tool) async {
    final input = Map<String, dynamic>.from(tool.input);
    final exercises = input['exercises'];
    if (exercises is! List) return tool;

    final registry = _ref.read(customExerciseRegistryProvider);
    final resolved = <Map<String, dynamic>>[];
    for (final raw in exercises) {
      if (raw is! Map) continue;
      final e = Map<String, dynamic>.from(raw);
      final proposed = (e['exerciseName'] as String?)?.trim() ?? '';
      if (proposed.isEmpty) {
        resolved.add(e);
        continue;
      }
      final r = resolveProposedExercise(proposed, notes: e['notes'] as String?);
      e['exerciseName'] = r.name;
      e['notes'] = r.notes;
      if (r.tier == 2 && r.group != null) {
        await registry.setGroup(r.name, r.group!);
      }
      resolved.add(e);
    }
    input['exercises'] = resolved;
    return CoachToolUse(tool.name, input);
  }

  bool _proposalWithinBounds(String kind, Map<String, dynamic> input) {
    if (kind == 'nutrition') {
      final cals = (input['calories'] as num?)?.toDouble();
      final p = (input['proteinG'] as num?)?.toDouble();
      final c = (input['carbsG'] as num?)?.toDouble();
      final f = (input['fatG'] as num?)?.toDouble();
      if (cals == null || p == null || c == null || f == null) return false;
      return cals >= 1200 &&
          cals <= 6000 &&
          p >= 30 &&
          p <= 400 &&
          c >= 0 &&
          c <= 800 &&
          f >= 20 &&
          f <= 300;
    }
    final exercises = input['exercises'];
    if (exercises is! List || exercises.isEmpty || exercises.length > 12) {
      return false;
    }
    for (final e in exercises) {
      if (e is! Map) return false;
      final sets = (e['sets'] as num?)?.toInt();
      final reps = (e['reps'] as num?)?.toInt();
      final name = e['exerciseName'];
      if (name is! String || name.trim().isEmpty) return false;
      if (sets == null || sets < 1 || sets > 10) return false;
      if (reps == null || reps < 1 || reps > 50) return false;
    }
    return true;
  }

  /// Persists a status change on an existing message and refreshes the list.
  Future<void> _updateMessage(AIMessage msg) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.aIMessages.put(msg);
      });
    } catch (e, st) {
      AppLogger.error('Failed to update proposal status', error: e, stack: st);
    }
    if (!mounted) return;
    state = state.copyWith(messages: [...state.messages]);
  }

  Future<void> dismissProposal(AIMessage msg) async {
    msg.proposalStatus = 'dismissed';
    await _updateMessage(msg);
  }

  /// Applies a nutrition-goal proposal through the shared resolver path, marks
  /// the card applied, and appends a confirmation note.
  Future<void> applyNutritionProposal(AIMessage msg) async {
    final json = msg.proposalJson;
    if (json == null) return;
    try {
      final input = jsonDecode(json) as Map<String, dynamic>;
      await applyNutritionGoals(
        _ref,
        calories: (input['calories'] as num).toDouble(),
        proteinG: (input['proteinG'] as num).toDouble(),
        carbsG: (input['carbsG'] as num).toDouble(),
        fatG: (input['fatG'] as num).toDouble(),
      );
      msg.proposalStatus = 'applied';
      await _updateMessage(msg);
      await _appendCoachNote('Targets updated. Now go earn them.');
    } catch (e, st) {
      AppLogger.error('applyNutritionProposal failed', error: e, stack: st);
      if (mounted) {
        state = state.copyWith(
          errorMessage: () => "Couldn't apply those targets. Try again.",
        );
      }
    }
  }

  /// Applies a workout proposal by saving it as a startable Coach template.
  Future<void> applyWorkoutProposal(AIMessage msg) async {
    final json = msg.proposalJson;
    if (json == null) return;
    try {
      final input = jsonDecode(json) as Map<String, dynamic>;
      final id = await saveCoachWorkoutTemplate(
        _ref,
        name: input['name'] as String? ?? 'Coach Workout',
        focus: input['focus'] as String? ?? '',
        exercisesJson: jsonEncode(input['exercises'] ?? const []),
      );
      if (id == null) {
        if (mounted) {
          state = state.copyWith(
            errorMessage: () => 'Sign in to save workouts.',
          );
        }
        return;
      }
      msg.proposalStatus = 'applied';
      await _updateMessage(msg);
      await _appendCoachNote('Saved to your templates. Hit it when ready.');
    } catch (e, st) {
      AppLogger.error('applyWorkoutProposal failed', error: e, stack: st);
      if (mounted) {
        state = state.copyWith(
          errorMessage: () => "Couldn't save that workout. Try again.",
        );
      }
    }
  }

  /// Appends a short assistant note (e.g. an apply confirmation) to history.
  Future<void> _appendCoachNote(String text) async {
    final uid = _uid;
    if (uid == null) return;
    final note = AIMessage()
      ..uid = uid
      ..role = MessageRole.assistant
      ..content = text
      ..timestamp = DateTime.now();
    await _persist(note);
    if (!mounted) return;
    state = state.copyWith(messages: _capInMemory([...state.messages, note]));
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('rate_limit') || lower.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (lower.contains('authentication') ||
        lower.contains('invalid') ||
        lower.contains('auth token')) {
      return "Couldn't verify your session. Please sign out and back in.";
    }
    if (lower.contains('overloaded')) {
      return 'The AI service is busy. Please try again in a minute.';
    }
    return "Couldn't reach the AI coach. Check your connection and try again.";
  }
}
