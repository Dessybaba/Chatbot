import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiApiService {
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const int maxTokens = 2048;
  static const Duration timeout = Duration(seconds: 30);

  // Rate limiting
  DateTime? _lastRequestTime;
  static const Duration minRequestInterval = Duration(seconds: 2);

  final String _apiKey;

  GeminiApiService({required String apiKey}) : _apiKey = apiKey {
    if (_apiKey.isEmpty) {
      throw Exception('API key cannot be empty');
    }
  }

  /// Send a message with full conversation context and rate limiting
  Future<String> sendMessage(
    String message,
    List<Map<String, dynamic>> conversationHistory,
  ) async {
    // Implement rate limiting
    await _enforceRateLimit();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl?key=$_apiKey'),
            headers: _getHeaders(),
            body: _getRequestBody(message, conversationHistory),
          )
          .timeout(timeout);

      _lastRequestTime = DateTime.now();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _extractResponse(responseData);
      } else if (response.statusCode == 429) {
        // Rate limit exceeded - wait and retry once
        await Future.delayed(const Duration(seconds: 5));
        return await _retryRequest(message, conversationHistory);
      } else {
        throw _handleErrorResponse(response);
      }
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: Please check your internet connection. $e',
      );
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Failed host lookup: Check your internet connection');
      }
      rethrow;
    }
  }

  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < minRequestInterval) {
        final waitTime = minRequestInterval - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }
  }

  Future<String> _retryRequest(
    String message,
    List<Map<String, dynamic>> history,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl?key=$_apiKey'),
            headers: _getHeaders(),
            body: _getRequestBody(message, history),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _extractResponse(responseData);
      } else {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      throw Exception(
        'Rate limit exceeded. Please wait a moment before sending another message.',
      );
    }
  }

  Map<String, String> _getHeaders() => {'Content-Type': 'application/json'};

  String _getRequestBody(String message, List<Map<String, dynamic>> history) {
    // Limit conversation history to last 5 messages to avoid rate limits
    final limitedHistory = history.length > 5
        ? history.sublist(history.length - 5)
        : history;

    final contents = [
      ...limitedHistory,
      {
        'role': 'user',
        'parts': [
          {'text': message},
        ],
      },
    ];

    return jsonEncode({
      'contents': contents,
      'generationConfig': {
        'maxOutputTokens': maxTokens,
        'temperature': 0.7,
        'topP': 0.8,
        'topK': 40,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    });
  }

  String _extractResponse(Map<String, dynamic> responseData) {
    try {
      if (responseData['candidates'] != null &&
          responseData['candidates'].isNotEmpty &&
          responseData['candidates'][0]['content'] != null &&
          responseData['candidates'][0]['content']['parts'] != null &&
          responseData['candidates'][0]['content']['parts'].isNotEmpty) {
        final text =
            responseData['candidates'][0]['content']['parts'][0]['text'];
        return text ?? 'Empty response from AI';
      }
      return 'No valid response received';
    } catch (e) {
      return 'Error parsing response: $e';
    }
  }

  Exception _handleErrorResponse(http.Response response) {
    final errorBody = response.body;

    if (response.statusCode == 400) {
      return Exception('Invalid request: Please check your input');
    } else if (response.statusCode == 401) {
      return Exception('Invalid API key. Please check your .env file');
    } else if (response.statusCode == 429) {
      return Exception(
        '⚠️ Too many requests. Please wait 10 seconds before trying again.',
      );
    } else if (response.statusCode == 403) {
      return Exception('API access forbidden. Check your API key permissions');
    } else if (response.statusCode >= 500) {
      return Exception('Server error. Please try again later');
    }

    // Try to parse error message from response
    try {
      final errorData = jsonDecode(errorBody);
      final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
      return Exception('API Error: $errorMessage');
    } catch (e) {
      return Exception('Request failed (${response.statusCode}): $errorBody');
    }
  }
}
