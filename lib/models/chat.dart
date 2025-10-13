import 'package:flutter/material.dart';

class Chat {
  final int id;
  final int senderId;
  final int receiverId;
  final String roomId;
  final String content;
  final ChatAttachment? attachment;
  final List<ChatAttachment>? attachments; // Support multiple attachments
  final DateTime? seenAt;
  final int? serviceRequestId;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.roomId,
    required this.content,
    this.attachment,
    this.attachments,
    this.seenAt,
    this.serviceRequestId,
    required this.createdAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    try {
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
        senderId: json['senderId'] as int,
        receiverId: json['receiverId'] as int,
        roomId: json['roomId'].toString(),
        content: json['content'] as String,
        attachment: attachment,
        attachments: attachments,
        seenAt: json['seenAt'] != null
            ? DateTime.tryParse(json['seenAt'])
            : null,
        serviceRequestId: json['serviceRequestId'] != null
            ? int.tryParse(json['serviceRequestId'].toString())
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
    } catch (e) {
      debugPrint('Error in Chat.fromJson: $e');
      debugPrint('JSON that caused error: $json');
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
      'seenAt': seenAt,
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
