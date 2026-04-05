import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/ai_coach/presentation/ai_coach_controller.dart';
import '../services/anthropic_service.dart';

/// Anthropic API service — null if API key is not configured.
final anthropicServiceProvider = Provider<AnthropicService?>((ref) {
  final key = dotenv.env['ANTHROPIC_API_KEY'];
  if (key == null || key.isEmpty || key == 'your-api-key-here') return null;
  return AnthropicService(key);
});

/// Chat controller with persistent state.
final aiChatControllerProvider =
    StateNotifierProvider<AIChatController, ChatState>((ref) {
  final anthropic = ref.watch(anthropicServiceProvider);
  return AIChatController(ref, anthropic);
});
