import 'dart:convert';
import 'dart:io';

/// Streaming client for the Anthropic Messages API.
class AnthropicService {
  AnthropicService(this.apiKey);

  final String apiKey;
  static const _model = 'claude-sonnet-4-20250514';

  /// Streams text deltas from the Anthropic Messages API.
  ///
  /// [systemPrompt] is sent as the `system` parameter.
  /// [messages] is a list of role/content pairs (user or assistant).
  ///
  /// Yields individual text chunks as they arrive via SSE.
  Stream<String> streamMessage({
    required String systemPrompt,
    required List<({String role, String content})> messages,
  }) async* {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://api.anthropic.com/v1/messages');
      final request = await client.postUrl(uri);

      request.headers.set('x-api-key', apiKey);
      request.headers.set('anthropic-version', '2023-06-01');
      request.headers.set('content-type', 'application/json');

      final body = jsonEncode({
        'model': _model,
        'max_tokens': 1024,
        'stream': true,
        'system': systemPrompt,
        'messages': messages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      });

      request.write(body);
      final response = await request.close();

      if (response.statusCode != 200) {
        final errorBody = await response.transform(utf8.decoder).join();
        final errorJson = jsonDecode(errorBody) as Map<String, dynamic>?;
        final errorMsg = errorJson?['error']?['message'] as String? ??
            'API error (${response.statusCode})';
        throw AnthropicException(errorMsg);
      }

      // Parse SSE stream
      String buffer = '';
      await for (final chunk in response.transform(utf8.decoder)) {
        buffer += chunk;

        // Process complete lines
        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);

          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6);
          if (data == '[DONE]') return;

          try {
            final event = jsonDecode(data) as Map<String, dynamic>;
            final type = event['type'] as String?;

            if (type == 'content_block_delta') {
              final delta = event['delta'] as Map<String, dynamic>?;
              if (delta != null && delta['type'] == 'text_delta') {
                final text = delta['text'] as String? ?? '';
                if (text.isNotEmpty) yield text;
              }
            } else if (type == 'error') {
              final error = event['error'] as Map<String, dynamic>?;
              throw AnthropicException(
                  error?['message'] as String? ?? 'Stream error');
            }
          } on FormatException {
            // Skip malformed JSON lines
          }
        }
      }
    } finally {
      client.close();
    }
  }
}

class AnthropicException implements Exception {
  AnthropicException(this.message);
  final String message;

  @override
  String toString() => message;
}
