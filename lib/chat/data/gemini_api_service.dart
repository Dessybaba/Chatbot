import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiApiService {
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const int maxTokens = 2048;
  static const Duration timeout = Duration(seconds: 30);

  final String _apiKey;

  GeminiApiService({required String apiKey}) : _apiKey = apiKey {
    if (_apiKey.isEmpty) {
      throw Exception('API key cannot be empty');
    }
  }

  /// Send a message with full conversation context
  Future<String> sendMessage(
      String message, List<Map<String, dynamic>> conversationHistory) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl?key=$_apiKey'),
            headers: _getHeaders(),
            body: _getRequestBody(message, conversationHistory),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _extractResponse(responseData);
      } else {
        throw _handleErrorResponse(response);
      }
    } on http.ClientException catch (e) {
      throw Exception(
          'Network error: Please check your internet connection. $e');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Failed host lookup: Check your internet connection');
      }
      rethrow;
    }
  }

  Map<String, String> _getHeaders() => {
        'Content-Type': 'application/json',
      };

  String _getRequestBody(String message, List<Map<String, dynamic>> history) {
    // Build conversation with history
    final contents = [
      ...history,
      {
        'role': 'user',
        'parts': [
          {'text': message}
        ]
      }
    ];

    return jsonEncode({
      'contents': contents,
      'generationConfig': {
        'maxOutputTokens': maxTokens,
        'temperature': 0.9,
        'topP': 1,
        'topK': 40,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        }
      ]
    });
  }

  String _extractResponse(Map<String, dynamic> responseData) {
    if (responseData['candidates'] != null &&
        responseData['candidates'].isNotEmpty &&
        responseData['candidates'][0]['content'] != null &&
        responseData['candidates'][0]['content']['parts'] != null &&
        responseData['candidates'][0]['content']['parts'].isNotEmpty) {
      final text = responseData['candidates'][0]['content']['parts'][0]['text'];
      return text ?? 'Empty response from AI';
    }
    return 'No valid response received';
  }

  Exception _handleErrorResponse(http.Response response) {
    final errorBody = response.body;
    if (response.statusCode == 400) {
      return Exception('Invalid request: Please check your input');
    } else if (response.statusCode == 401) {
      return Exception('Invalid API key');
    } else if (response.statusCode == 429) {
      return Exception('Rate limit exceeded. Please wait a moment');
    } else if (response.statusCode >= 500) {
      return Exception('Server error. Please try again later');
    }
    return Exception('Request failed (${response.statusCode}): $errorBody');
  }
}
