class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  Message({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
  };

  // Create from JSON
  factory Message.fromJson(Map<String, dynamic> json) => Message(
    content: json['content'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
    isError: json['isError'] ?? false,
  );
}