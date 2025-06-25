import 'package:ai_chat_bot/chat/data/gemini_api_service.dart';
import 'package:ai_chat_bot/model/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatProvider with ChangeNotifier {
  // Gemini API service initialized with key from .env
  late final GeminiApiService _apiService;

  ChatProvider() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _apiService = GeminiApiService(apiKey: apiKey);
  }

  final List<Message> _messages = [];
  bool _isLoading = false;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = Message(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.sendMessage(content);
      final responseMessage = Message(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(responseMessage);
    } catch (e) {
      final errorMessage = Message(
        content: 'Sorry, I encountered an issue.. $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
