import 'dart:convert';

import 'package:http/http.dart' as http;

/*

Service class to handle all Gemini API stuff...

*/

class GeminiApiService {
  //  API Constants
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const int _maxTokens = 1024;

  // Store the API key securely
  final String _apiKey;

  // Require API key
  GeminiApiService({required String apiKey}) : _apiKey = apiKey;

  /*

  Send a message to Gemini API and get the response.

  */

  Future<String> sendMessage(String message) async {
    try {
      // Make POST request to Gemini API
      final response = await http.post(
        Uri.parse('$baseUrl?key=$_apiKey'),
        headers: _getHeaders(),
        body: _getRequestBody(message),
      );

      // Check if request was successful
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Extract the content from Gemini's response
        if (responseData['candidates'] != null && 
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          return responseData['candidates'][0]['content']['parts'][0]['text'] ?? 'No response content';
        } else {
          return 'Empty response from Gemini';
        }
      } else {
        throw Exception('API request failed with status: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending message to Gemini: $e');
    }
  }

  // create required headers for Gemini API
  Map<String, String> _getHeaders() => {
        'Content-Type': 'application/json',
      };

  // format the request body for Gemini API specs
  String _getRequestBody(String content) => jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': content}
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': _maxTokens,
          'temperature': 0.7,
        }
      });
}