import 'dart:async';
import 'package:logging/logging.dart';
import 'package:manong_application/api/socket_api_service.dart';
import 'package:manong_application/models/chat.dart';

class ChatApiService {
  static final ChatApiService _instance = ChatApiService._internal();
  factory ChatApiService() => _instance;
  ChatApiService._internal();

  final Logger logger = Logger('ChatApiService');
  final SocketApiService _socketService = SocketApiService();

  // Store callbacks to avoid multiple listeners
  Function(dynamic)? _historyCallback;
  Function(dynamic)? _messageUpdateCallback;

  void onHistory(Function(List<dynamic>) callback) {
    // Remove existing listener if any
    if (_historyCallback != null) {
      _socketService.off('chat:history');
    }

    _historyCallback = (data) {
      if (data is List) {
        callback(data);
      } else {
        logger.warning(
          'Expected List for chat history, got: ${data.runtimeType}',
        );
        callback([]);
      }
    };

    _socketService.on('chat:history', _historyCallback!);
    logger.info('Set up chat:history listener');
  }

  void onMessageUpdate(Function(dynamic) callback) {
    // Remove existing listener if any
    if (_messageUpdateCallback != null) {
      _socketService.off('chat:update');
    }

    _messageUpdateCallback = (data) {
      logger.info('Received message update: $data');
      callback(data);
    };

    _socketService.on('chat:update', _messageUpdateCallback!);
    logger.info('Set up chat:update listener');
  }

  Future<void> joinRoom({
    required int senderId,
    required int receiverId,
    required int userId,
    required int manongId,
    required int serviceRequestId,
  }) async {
    // Add a small delay to ensure listeners are set up
    await Future.delayed(Duration(milliseconds: 100));

    final data = {
      'senderId': senderId,
      'receiverId': receiverId,
      'userId': userId,
      'manongId': manongId,
      'serviceRequestId': serviceRequestId,
    };

    logger.info('Joining chat room with data: $data');
    _socketService.emit('joinChatRoom', data);
  }

  Future<Chat?> sendMessage({
    required int senderId,
    required int receiverId,
    required int userId,
    required int manongId,
    required int serviceRequestId,
    required String content,
    List<Map<String, String>>? attachments,
  }) async {
    final data = {
      'senderId': senderId,
      'receiverId': receiverId,
      'userId': userId,
      'manongId': manongId,
      'serviceRequestId': serviceRequestId,
      'content': content,
      'attachments': attachments,
    };

    try {
      final response = await _socketService.emitWithAck('sendMessage', data);

      if (response != null && response is Map<String, dynamic>) {
        // Ensure id exists
        if (!response.containsKey('id')) {
          logger.warning('Server response missing id: $response');
          return null;
        }
        return Chat.fromJson(response);
      } else {
        logger.warning('Server response is null or invalid: $response');
      }
    } catch (e) {
      logger.severe('Error sending message: $e');
    }

    return null;
  }

  void disconnect({
    required int userId,
    required int manongId,
    required int serviceRequestId,
  }) {
    final data = {
      'userId': userId,
      'manongId': manongId,
      'serviceRequestId': serviceRequestId,
    };

    logger.info('Leaving chat room: $data');
    _socketService.emit('leaveChatRoom', data);

    // Clean up listeners
    if (_historyCallback != null) {
      _socketService.off('chat:history');
      _historyCallback = null;
    }

    if (_messageUpdateCallback != null) {
      _socketService.off('chat:update');
      _messageUpdateCallback = null;
    }
  }
}
