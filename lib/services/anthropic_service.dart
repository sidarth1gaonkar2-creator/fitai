import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/utils/logger.dart';

/// Streaming + non-streaming client for the Anthropic Messages API.
class AnthropicService {
  AnthropicService(this.apiKey) {
    if (apiKey.isEmpty) {
      throw AnthropicException(
        'ANTHROPIC_API_KEY is missing. Add it to assets/.env and ensure '
        'the file is listed under flutter.assets in pubspec.yaml.',
      );
    }
  }

  final String apiKey;
  static const _model = 'claude-sonnet-4-20250514';
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _streamTimeout = Duration(seconds: 60);

  Map<String, String> _headers({required bool streaming}) => {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        if (streaming) 'accept': 'text/event-stream',
      };

  Map<String, dynamic> _body({
    required String systemPrompt,
    required List<({String role, String content})> messages,
    required bool stream,
  }) =>
      {
        'model': _model,
        'max_tokens': 1024,
        'stream': stream,
        'system': systemPrompt,
        'messages': messages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      };

  /// Streams text deltas from the Anthropic Messages API.
  /// If the stream errors out, callers should fall back to [sendMessage].
  Stream<String> streamMessage({
    required String systemPrompt,
    required List<({String role, String content})> messages,
  }) async* {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final bodyJson = jsonEncode(
          _body(systemPrompt: systemPrompt, messages: messages, stream: true));
      debugPrint('[Anthropic] → POST $_endpoint (streaming)');
      debugPrint('[Anthropic] → body: ${_truncate(bodyJson, 500)}');

      final request = await client.postUrl(Uri.parse(_endpoint));
      _headers(streaming: true).forEach(request.headers.set);
      request.add(utf8.encode(bodyJson));

      final response = await request.close().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw AnthropicException(
                'Timed out connecting to the AI service.'),
          );

      debugPrint('[Anthropic] ← status ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorBody = await response.transform(utf8.decoder).join();
        debugPrint('[Anthropic] ← error body: ${_truncate(errorBody, 1000)}');
        Map<String, dynamic>? errorJson;
        try {
          errorJson = jsonDecode(errorBody) as Map<String, dynamic>?;
        } catch (_) {}
        final errorMsg = errorJson?['error']?['message'] as String? ??
            'API error (${response.statusCode})';
        throw AnthropicException(errorMsg);
      }

      // Parse SSE stream with an idle-timeout so we never hang forever.
      String buffer = '';
      int chunksYielded = 0;
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
            debugPrint('[Anthropic] ← stream [DONE] ($chunksYielded chunks)');
            return;
          }

          try {
            final event = jsonDecode(data) as Map<String, dynamic>;
            final type = event['type'] as String?;

            if (type == 'content_block_delta') {
              final delta = event['delta'] as Map<String, dynamic>?;
              if (delta != null && delta['type'] == 'text_delta') {
                final text = delta['text'] as String? ?? '';
                if (text.isNotEmpty) {
                  chunksYielded++;
                  yield text;
                }
              }
            } else if (type == 'message_stop') {
              debugPrint(
                  '[Anthropic] ← message_stop ($chunksYielded chunks)');
              return;
            } else if (type == 'error') {
              final error = event['error'] as Map<String, dynamic>?;
              final msg = error?['message'] as String? ?? 'Stream error';
              debugPrint('[Anthropic] ← stream error event: $msg');
              throw AnthropicException(msg);
            }
          } on FormatException catch (e) {
            debugPrint(
                '[Anthropic] SSE line failed to parse: $e (line=${_truncate(line, 200)})');
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

  /// Non-streaming fallback. Returns the full assistant text in one call.
  Future<String> sendMessage({
    required String systemPrompt,
    required List<({String role, String content})> messages,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    try {
      final bodyJson = jsonEncode(
          _body(systemPrompt: systemPrompt, messages: messages, stream: false));
      debugPrint('[Anthropic] → POST $_endpoint (non-streaming fallback)');
      debugPrint('[Anthropic] → body: ${_truncate(bodyJson, 500)}');

      final request = await client.postUrl(Uri.parse(_endpoint));
      _headers(streaming: false).forEach(request.headers.set);
      request.add(utf8.encode(bodyJson));

      final response = await request.close().timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw AnthropicException(
                'AI service timed out. Please try again.'),
          );

      final body = await response.transform(utf8.decoder).join();
      debugPrint('[Anthropic] ← status ${response.statusCode}');
      debugPrint('[Anthropic] ← body: ${_truncate(body, 1000)}');

      if (response.statusCode != 200) {
        Map<String, dynamic>? errorJson;
        try {
          errorJson = jsonDecode(body) as Map<String, dynamic>?;
        } catch (_) {}
        final errorMsg = errorJson?['error']?['message'] as String? ??
            'API error (${response.statusCode})';
        throw AnthropicException(errorMsg);
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final content = json['content'] as List<dynamic>?;
      if (content == null || content.isEmpty) {
        throw AnthropicException('Empty response from AI service.');
      }
      final buffer = StringBuffer();
      for (final block in content) {
        if (block is Map<String, dynamic> && block['type'] == 'text') {
          buffer.write(block['text'] as String? ?? '');
        }
      }
      return buffer.toString();
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
