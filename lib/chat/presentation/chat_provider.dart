import 'package:ai_chat_bot/chat/data/gemini_api_service.dart';
import 'package:ai_chat_bot/model/message.dart';
import 'package:flutter/material.dart';

class ChatProvider with ChangeNotifier {
  // Gemini api service
  final _apiService = GeminiApiService(apiKey: 'AIzaSyB10W4HKWGXrg4y5_N-HTKjgRU9jEYdahM');

  // Messages and loading...
  final List<Message> _messages = [];
  bool _isLoading = false;

  // Getters
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  // Send message to Gemini API
  Future<void> sendMessage(String content) async {
    // prevent sending empty messages
    if (content.trim().isEmpty) return;

    // user message
    final userMessage = Message(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // add user message
    _messages.add(userMessage);

    // update UI
    notifyListeners();

    // send loading..
    _isLoading = true;

    // update UI
    notifyListeners();

    // send message and receive response
    try {
      final response = await _apiService.sendMessage(content);

      // response message from AI
      final responseMessage = Message(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      // add to chat
      _messages.add(responseMessage);
    }

    // error..
    catch (e) {
      // error message
      final errorMessage = Message(
        content: 'Sorry , i encountered an issue.. $e',
        isUser: false,
        timestamp: DateTime.now(),
      );

      // add message to chat
      _messages.add(errorMessage);
    }

    // finished loading
    _isLoading = false;

    // update UI
    notifyListeners(); 
  }
}
