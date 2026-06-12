import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/utils/logger.dart';

/// Streaming + non-streaming client for the Anthropic Messages API.
class AnthropicService {
  AnthropicService(
    this.apiKey, {
    this.proxyEndpoint,
    this.authTokenProvider,
  }) {
    // A key is only required in direct mode; in proxy mode the key lives on the
    // backend and is never present on the device.
    if (proxyEndpoint == null && apiKey.isEmpty) {
      throw AnthropicException(
        'AnthropicService requires a proxy endpoint (AI_PROXY_URL). The '
        'Anthropic key is never used on-device.',
      );
    }
  }

  final String apiKey;

  /// When set, requests are sent to your own backend (the AI proxy) instead of
  /// calling Anthropic directly, so the API key never ships inside the app
  /// bundle. In this mode [apiKey] is ignored and the request is authenticated
  /// with a Firebase ID token supplied by [authTokenProvider].
  final Uri? proxyEndpoint;

  /// Supplies a fresh Firebase ID token for proxy-mode auth. Only consulted
  /// when [proxyEndpoint] is set.
  final Future<String?> Function()? authTokenProvider;

  bool get _useProxy => proxyEndpoint != null;

  static const _model = 'claude-sonnet-4-20250514';
  static const _anthropicUrl = 'https://api.anthropic.com/v1/messages';
  static const _streamTimeout = Duration(seconds: 60);

  Uri get _uri => proxyEndpoint ?? Uri.parse(_anthropicUrl);

  Future<Map<String, String>> _headers({required bool streaming}) async {
    if (_useProxy) {
      final token = await authTokenProvider?.call();
      return {
        'content-type': 'application/json',
        if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
        'anthropic-version': '2023-06-01',
        if (streaming) 'accept': 'text/event-stream',
      };
    }
    return {
      'content-type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      if (streaming) 'accept': 'text/event-stream',
    };
  }

  Map<String, dynamic> _body({
    required String systemPrompt,
    required List<({String role, String content})> messages,
    required bool stream,
  }) =>
      {
        'model': _model,
        // A little headroom so a multi-exercise create_workout tool input
        // isn't truncated mid-JSON.
        'max_tokens': 1500,
        'stream': stream,
        'system': systemPrompt,
        'messages': messages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      };

  /// Streams [CoachEvent]s from the Anthropic Messages API — text deltas plus
  /// any completed (server-validated) tool proposal.
  /// If the stream errors out, callers should fall back to [sendMessage].
  Stream<CoachEvent> streamMessage({
    required String systemPrompt,
    required List<({String role, String content})> messages,
  }) async* {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final bodyJson = jsonEncode(
          _body(systemPrompt: systemPrompt, messages: messages, stream: true));
      if (kDebugMode) {
        debugPrint('[Anthropic] → POST $_uri (streaming, proxy=$_useProxy)');
        debugPrint('[Anthropic] → body: ${_truncate(bodyJson, 500)}');
      }

      final request = await client.postUrl(_uri);
      (await _headers(streaming: true)).forEach(request.headers.set);
      request.add(utf8.encode(bodyJson));

      final response = await request.close().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw AnthropicException(
                'Timed out connecting to the AI service.'),
          );

      if (kDebugMode) {
        debugPrint('[Anthropic] ← status ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        final errorBody = await response.transform(utf8.decoder).join();
        if (kDebugMode) {
          debugPrint('[Anthropic] ← error body: ${_truncate(errorBody, 1000)}');
        }
        Map<String, dynamic>? errorJson;
        try {
          errorJson = jsonDecode(errorBody) as Map<String, dynamic>?;
        } catch (_) {}
        final errorMsg = errorJson?['error']?['message'] as String? ??
            'API error (${response.statusCode})';
        // 429 from the proxy is our own per-user daily cap (Anthropic's own
        // errors are masked to a generic 502 server-side). Surface it as a
        // distinct, terminal exception so the controller shows the limit
        // notice instead of retrying via the non-streaming fallback.
        if (response.statusCode == 429) {
          throw AnthropicRateLimitException(errorMsg);
        }
        throw AnthropicException(errorMsg);
      }

      // Parse SSE stream with an idle-timeout so we never hang forever.
      String buffer = '';
      int chunksYielded = 0;
      // Accumulates a tool_use block. The proxy normalizes it to a single
      // content_block_start + one input_json_delta (carrying the validated
      // input) + content_block_stop.
      String? toolName;
      final toolJson = StringBuffer();
      final lines = response
          .transform(utf8.decoder)
          .timeout(_streamTimeout, onTimeout: (sink) {
        sink.addError(AnthropicException(
            'Stream stalled: no data received for ${_streamTimeout.inSeconds}s'));
        sink.close();
      });

      await for (final chunk in lines) {
        buffer += chunk;
        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);

          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6);
          if (data == '[DONE]') {
            if (kDebugMode) {
              debugPrint('[Anthropic] ← stream [DONE] ($chunksYielded chunks)');
            }
            return;
          }

          try {
            final event = jsonDecode(data) as Map<String, dynamic>;
            final type = event['type'] as String?;

            if (type == 'content_block_start') {
              final cb = event['content_block'] as Map<String, dynamic>?;
              if (cb != null && cb['type'] == 'tool_use') {
                toolName = cb['name'] as String?;
                toolJson.clear();
              }
            } else if (type == 'content_block_delta') {
              final delta = event['delta'] as Map<String, dynamic>?;
              if (delta != null && delta['type'] == 'text_delta') {
                final text = delta['text'] as String? ?? '';
                if (text.isNotEmpty) {
                  chunksYielded++;
                  yield CoachTextDelta(text);
                }
              } else if (delta != null &&
                  delta['type'] == 'input_json_delta' &&
                  toolName != null) {
                toolJson.write(delta['partial_json'] as String? ?? '');
              }
            } else if (type == 'content_block_stop') {
              final name = toolName;
              if (name != null) {
                try {
                  final input =
                      jsonDecode(toolJson.toString()) as Map<String, dynamic>;
                  yield CoachToolUse(name, input);
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('[Anthropic] tool_use JSON parse failed: $e');
                  }
                }
                toolName = null;
                toolJson.clear();
              }
            } else if (type == 'message_stop') {
              if (kDebugMode) {
                debugPrint(
                    '[Anthropic] ← message_stop ($chunksYielded chunks)');
              }
              return;
            } else if (type == 'error') {
              final error = event['error'] as Map<String, dynamic>?;
              final msg = error?['message'] as String? ?? 'Stream error';
              AppLogger.error('Anthropic stream error event: $msg');
              throw AnthropicException(msg);
            }
          } on FormatException catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '[Anthropic] SSE line failed to parse: $e (line=${_truncate(line, 200)})');
            }
          }
        }
      }
    } on TimeoutException catch (e, st) {
      AppLogger.error(
        'Anthropic stream timed out',
        error: e,
        stack: st,
      );
      throw AnthropicException('AI service timed out. Please try again.');
    } on SocketException catch (e, st) {
      AppLogger.error(
        'Anthropic stream SocketException',
        error: e,
        stack: st,
      );
      rethrow;
    } on AnthropicException {
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        'Anthropic stream unexpected error (${e.runtimeType})',
        error: e,
        stack: st,
      );
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  /// Non-streaming fallback. Returns the full assistant text plus any tool
  /// proposal in one call.
  Future<CoachResult> sendMessage({
    required String systemPrompt,
    required List<({String role, String content})> messages,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    try {
      final bodyJson = jsonEncode(
          _body(systemPrompt: systemPrompt, messages: messages, stream: false));
      if (kDebugMode) {
        debugPrint('[Anthropic] → POST $_uri (non-streaming, proxy=$_useProxy)');
        debugPrint('[Anthropic] → body: ${_truncate(bodyJson, 500)}');
      }

      final request = await client.postUrl(_uri);
      (await _headers(streaming: false)).forEach(request.headers.set);
      request.add(utf8.encode(bodyJson));

      final response = await request.close().timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw AnthropicException(
                'AI service timed out. Please try again.'),
          );

      final body = await response.transform(utf8.decoder).join();
      if (kDebugMode) {
        debugPrint('[Anthropic] ← status ${response.statusCode}');
        debugPrint('[Anthropic] ← body: ${_truncate(body, 1000)}');
      }

      if (response.statusCode != 200) {
        Map<String, dynamic>? errorJson;
        try {
          errorJson = jsonDecode(body) as Map<String, dynamic>?;
        } catch (_) {}
        final errorMsg = errorJson?['error']?['message'] as String? ??
            'API error (${response.statusCode})';
        if (response.statusCode == 429) {
          throw AnthropicRateLimitException(errorMsg);
        }
        throw AnthropicException(errorMsg);
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final content = json['content'] as List<dynamic>?;
      if (content == null || content.isEmpty) {
        throw AnthropicException('Empty response from AI service.');
      }
      final buffer = StringBuffer();
      CoachToolUse? tool;
      for (final block in content) {
        if (block is! Map<String, dynamic>) continue;
        if (block['type'] == 'text') {
          buffer.write(block['text'] as String? ?? '');
        } else if (block['type'] == 'tool_use') {
          final name = block['name'] as String?;
          final input = block['input'];
          if (name != null && input is Map<String, dynamic>) {
            tool = CoachToolUse(name, input);
          }
        }
      }
      return CoachResult(text: buffer.toString(), toolUse: tool);
    } on AnthropicException {
      rethrow;
    } on SocketException catch (e, st) {
      AppLogger.error(
        'Anthropic non-stream SocketException',
        error: e,
        stack: st,
      );
      throw AnthropicException("No internet connection.");
    } catch (e, st) {
      AppLogger.error(
        'Anthropic non-stream unexpected error (${e.runtimeType})',
        error: e,
        stack: st,
      );
      throw AnthropicException("Couldn't reach the AI coach. $e");
    } finally {
      client.close(force: true);
    }
  }

  static String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…(${s.length - max} more)';
}

class AnthropicException implements Exception {
  AnthropicException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thrown when the proxy rejects a request because the signed-in user has hit
/// their per-user daily AI Coach cap (HTTP 429). [message] is already
/// user-friendly and safe to show directly.
class AnthropicRateLimitException extends AnthropicException {
  AnthropicRateLimitException(super.message);
}

/// A streamed AI Coach event: a chunk of assistant text, or a completed
/// (server-validated) tool proposal.
sealed class CoachEvent {}

class CoachTextDelta extends CoachEvent {
  CoachTextDelta(this.text);
  final String text;
}

class CoachToolUse extends CoachEvent {
  CoachToolUse(this.name, this.input);

  /// Anthropic tool name: 'update_nutrition_goals' or 'create_workout'.
  final String name;

  /// The validated tool input (clamped/checked server-side).
  final Map<String, dynamic> input;
}

/// Result of a non-streaming [AnthropicService.sendMessage] call.
class CoachResult {
  CoachResult({required this.text, this.toolUse});
  final String text;
  final CoachToolUse? toolUse;
}
