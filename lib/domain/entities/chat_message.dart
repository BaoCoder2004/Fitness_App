class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final ChatRole role;
  final String content;
  final DateTime timestamp;
}

enum ChatRole {
  user,
  assistant,
}

