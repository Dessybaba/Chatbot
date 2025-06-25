import 'package:ai_chat_bot/model/message.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, 
  required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12)
        ),
        child: Text(message.content, style: TextStyle(
          color: message.isUser ? Colors.white : Colors.black ),)),
    );
  }
}
