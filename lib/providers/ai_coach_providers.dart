import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/ai_coach/presentation/ai_coach_controller.dart';
import '../services/anthropic_service.dart';

/// Anthropic API service — null if neither a proxy nor an API key is configured.
///
/// Preferred (production) path: set `AI_PROXY_URL` in assets/.env to the
/// deployed `aiProxy` Cloud Function URL. The key then lives only on the
/// backend and the app authenticates each call with its Firebase ID token — the
/// Anthropic key never ships in the app bundle. If `AI_PROXY_URL` is absent we
/// fall back to calling Anthropic directly with the local key (dev only; do not
/// ship a release this way — bundled keys are extractable).
final anthropicServiceProvider = Provider<AnthropicService?>((ref) {
  final proxyUrl = dotenv.env['AI_PROXY_URL'];
  if (proxyUrl != null && proxyUrl.isNotEmpty) {
    return AnthropicService(
      '', // no key on device in proxy mode
      proxyEndpoint: Uri.parse(proxyUrl),
      authTokenProvider: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
        return user.getIdToken();
      },
    );
  }

  final key = dotenv.env['ANTHROPIC_API_KEY'];
  if (key == null || key.isEmpty || key == 'your-api-key-here') {
    if (kDebugMode) {
      debugPrint('[Anthropic] No AI_PROXY_URL and API key NOT loaded from '
          'assets/.env (key=${key == null ? "null" : "empty/placeholder"})');
    }
    return null;
  }
  return AnthropicService(key);
});

/// Chat controller with persistent state.
final aiChatControllerProvider =
    StateNotifierProvider<AIChatController, ChatState>((ref) {
  final anthropic = ref.watch(anthropicServiceProvider);
  return AIChatController(ref, anthropic);
});
