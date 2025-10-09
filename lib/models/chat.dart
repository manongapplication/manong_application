import 'package:logging/logging.dart';

class Chat {
  final int id;
  final String roomId;
  final String senderId;
  final String content;
  final ChatAttachment? attachment;
  final List<ChatAttachment>? attachments; // Support multiple attachments
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.attachment,
    this.attachments,
    required this.createdAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    try {
      // Handle different possible field names from server
      String senderId;
      if (json.containsKey('senderId')) {
        senderId = json['senderId'].toString();
      } else if (json.containsKey('sender_id')) {
        senderId = json['sender_id'].toString();
      } else {
        throw Exception('No senderId or sender_id found in JSON');
      }

      String roomId;
      if (json.containsKey('roomId')) {
        roomId = json['roomId'] as String;
      } else if (json.containsKey('room_id')) {
        roomId = json['room_id'] as String;
      } else {
        roomId = ''; // fallback
      }

      DateTime createdAt;
      if (json.containsKey('createdAt')) {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } else if (json.containsKey('created_at')) {
        createdAt = DateTime.parse(json['created_at'] as String);
      } else {
        createdAt = DateTime.now(); // fallback
      }

      // Handle attachments (both single and multiple)
      ChatAttachment? attachment;
      List<ChatAttachment>? attachments;

      if (json['attachment'] != null) {
        attachment = ChatAttachment.fromJson(
          Map<String, dynamic>.from(json['attachment']),
        );
      }

      if (json['attachments'] != null && json['attachments'] is List) {
        attachments = (json['attachments'] as List)
            .map(
              (att) => ChatAttachment.fromJson(Map<String, dynamic>.from(att)),
            )
            .toList();
      }

      return Chat(
        id: json['id'] as int,
        roomId: roomId,
        senderId: senderId,
        content: json['content'] as String,
        attachment: attachment,
        attachments: attachments,
        createdAt: createdAt,
      );
    } catch (e) {
      print('Error in Chat.fromJson: $e');
      print('JSON that caused error: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'attachment': attachment?.toJson(),
      'attachments': attachments?.map((att) => att.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ChatAttachment {
  final int id;
  final String type;
  final String url;

  ChatAttachment({required this.id, required this.type, required this.url});

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['id'] as int,
      type: json['type'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type, 'url': url};
  }
}
