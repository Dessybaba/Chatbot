import 'dart:convert';
import 'package:ai_chat_bot/chat/data/gemini_api_service.dart';
import 'package:ai_chat_bot/model/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatProvider with ChangeNotifier {
  late final GeminiApiService _apiService;
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _currentChatId;

  ChatProvider() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      _messages.add(Message(
        content: '⚠️ API key not found. Please add GEMINI_API_KEY to your .env file',
        isUser: false,
        isError: true,
      ));
    }
    _apiService = GeminiApiService(apiKey: apiKey);
    _loadMessages();
  }

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get currentChatId => _currentChatId;

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Check internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _addErrorMessage('No internet connection. Please check your network.');
      return;
    }

    // Add user message
    final userMessage = Message(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();
    await _saveMessages();

    // Show loading state
    _isLoading = true;
    notifyListeners();

    try {
      // Build conversation history for context
      final conversationHistory = _buildConversationHistory();
      
      // Get AI response
      final response = await _apiService.sendMessage(content, conversationHistory);
      
      final aiMessage = Message(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);
      await _saveMessages();
    } catch (e) {
      _addErrorMessage(_formatError(e.toString()));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _buildConversationHistory() {
    // Send last 10 messages for context (to avoid token limits)
    final recentMessages = _messages.length > 10 
        ? _messages.sublist(_messages.length - 10)
        : _messages;
    
    return recentMessages
        .where((msg) => !msg.isError) // Exclude error messages
        .map((msg) => {
          'role': msg.isUser ? 'user' : 'model',
          'parts': [{'text': msg.content}]
        })
        .toList();
  }

  void _addErrorMessage(String errorText) {
    final errorMessage = Message(
      content: errorText,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );
    _messages.add(errorMessage);
    notifyListeners();
  }

  String _formatError(String error) {
    if (error.contains('SocketException') || error.contains('Failed host lookup')) {
      return '🌐 Connection failed. Please check your internet connection.';
    } else if (error.contains('TimeoutException')) {
      return '⏱️ Request timed out. Please try again.';
    } else if (error.contains('Invalid API key')) {
      return '🔑 Invalid API key. Please check your configuration.';
    } else if (error.contains('Rate limit')) {
      return '⚠️ Too many requests. Please wait a moment and try again.';
    }
    return '❌ Sorry, something went wrong. Please try again.';
  }

  Future<void> clearMessages() async {
    _messages.clear();
    _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
    await _saveMessages();
    notifyListeners();
  }

  Future<void> deleteMessage(int index) async {
    if (index >= 0 && index < _messages.length) {
      _messages.removeAt(index);
      await _saveMessages();
      notifyListeners();
    }
  }

  // Persistence methods
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages.map((m) => m.toJson()).toList();
      await prefs.setString('chat_messages', jsonEncode(messagesJson));
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesString = prefs.getString('chat_messages');
      if (messagesString != null) {
        final List<dynamic> messagesJson = jsonDecode(messagesString);
        _messages.addAll(
          messagesJson.map((json) => Message.fromJson(json)).toList()
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> exportChat() async {
    // This could export to a file or clipboard
    final chatText = _messages
        .map((m) => '${m.isUser ? "You" : "AI"} (${_formatTimestamp(m.timestamp)}): ${m.content}')
        .join('\n\n');
    return Future.value(); // Implement actual export logic as needed
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}