import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/ai_coach/presentation/ai_coach_controller.dart';
import '../services/anthropic_service.dart';

/// Anthropic API service — null when no backend proxy is configured.
///
/// Production path (the only path): set `AI_PROXY_URL` in assets/.env to the
/// deployed `aiProxy` Cloud Function URL. The Anthropic key then lives only in
/// Secret Manager on the backend and the app authenticates each call with its
/// Firebase ID token — no Anthropic key ever ships in the app bundle. If
/// `AI_PROXY_URL` is absent the AI Coach is disabled (there is deliberately no
/// on-device key fallback; a bundled key is extractable from any release).
final anthropicServiceProvider = Provider<AnthropicService?>((ref) {
  final proxyUrl = dotenv.env['AI_PROXY_URL'];
  if (proxyUrl == null || proxyUrl.isEmpty) {
    if (kDebugMode) {
      debugPrint('[Anthropic] AI_PROXY_URL is not set — AI Coach disabled. '
          'Deploy the aiProxy Cloud Function and set AI_PROXY_URL in '
          'assets/.env.');
    }
    return null;
  }

  return AnthropicService(
    '', // no key on device — proxy mode only
    proxyEndpoint: Uri.parse(proxyUrl),
    authTokenProvider: () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return user.getIdToken();
    },
  );
});

/// Chat controller with persistent state.
final aiChatControllerProvider =
    StateNotifierProvider<AIChatController, ChatState>((ref) {
  final anthropic = ref.watch(anthropicServiceProvider);
  return AIChatController(ref, anthropic);
});
