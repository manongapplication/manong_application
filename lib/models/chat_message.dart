class ChatMessage {
  final int id;
  final String content;
  final int senderId;
  final int receiverId;
  final DateTime createdAt;
  final bool isSupport;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
    required this.isSupport,
  });
}
