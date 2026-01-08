import 'package:ai_chat_bot/model/message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onLongPress;

  const ChatBubble({super.key, required this.message, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(),
          if (!message.isUser) const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF4285F4), Color(0xFF9C27B0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: message.isUser
                        ? null
                        : (message.isError
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF1F2937)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 12),
          if (message.isUser) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    // Simple formatting for code blocks and bold text
    final lines = message.content.split('\n');
    final List<TextSpan> spans = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check if line is a code block (starts with ``` or has 4 spaces)
      if (line.trim().startsWith('```') || line.startsWith('    ')) {
        spans.add(
          TextSpan(
            text:
                line.replaceAll('```', '') + (i < lines.length - 1 ? '\n' : ''),
            style: TextStyle(
              color: const Color(0xFF4285F4),
              fontFamily: 'monospace',
              backgroundColor: Colors.black.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        );
      } else {
        // Handle bold text **text**
        final boldRegex = RegExp(r'\*\*(.*?)\*\*');
        if (boldRegex.hasMatch(line)) {
          int lastIndex = 0;
          for (final match in boldRegex.allMatches(line)) {
            // Add text before bold
            if (match.start > lastIndex) {
              spans.add(
                TextSpan(
                  text: line.substring(lastIndex, match.start),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              );
            }
            // Add bold text
            spans.add(
              TextSpan(
                text: match.group(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
            lastIndex = match.end;
          }
          // Add remaining text
          if (lastIndex < line.length) {
            spans.add(
              TextSpan(
                text:
                    line.substring(lastIndex) +
                    (i < lines.length - 1 ? '\n' : ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            );
          }
        } else {
          // Regular text
          spans.add(
            TextSpan(
              text: line + (i < lines.length - 1 ? '\n' : ''),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          );
        }
      }
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: message.isUser
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              )
            : const LinearGradient(
                colors: [Color(0xFF4285F4), Color(0xFF9C27B0)],
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                (message.isUser
                        ? const Color(0xFF10B981)
                        : const Color(0xFF4285F4))
                    .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        message.isUser ? Icons.person : Icons.auto_awesome,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }
}
