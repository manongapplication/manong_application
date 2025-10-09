import 'dart:async';

import 'package:logging/logging.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SocketApiService {
  static final SocketApiService _instance = SocketApiService._internal();
  factory SocketApiService() => _instance;
  SocketApiService._internal();

  final Logger logger = Logger('SocketApiService');
  IO.Socket? socket;
  final String? baseUrl = dotenv.env['APP_URL'];

  Future<void> connect() async {
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    final completer = Completer<void>();

    socket!.onConnect((_) {
      logger.info('Connected to server');
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    socket!.onDisconnect((_) => logger.info('Disconnected from server'));

    socket!.onConnectError((err) {
      logger.severe('Connection error: $err');
      if (!completer.isCompleted) completer.completeError(err);
    });

    // Add general event listener for debugging
    socket!.onAny((event, data) {
      logger.info('Received event: $event with data: $data');
    });

    socket!.connect();
    return completer.future;
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }

  void emit(String event, Map<String, dynamic> data) {
    if (socket?.connected == true) {
      logger.info('Emitting $event: $data');
      socket?.emit(event, data);
    } else {
      logger.warning('Attempted to emit $event but socket is not connected');
    }
  }

  void on(String event, Function(dynamic) callback) {
    logger.info('Setting up listener for event: $event');
    socket?.on(event, (data) {
      logger.info('Event $event received with data: $data');
      callback(data);
    });
  }

  Future<dynamic> emitWithAck(
    String event,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (socket?.connected != true) {
      logger.warning('Attempted to emit $event but socket is not connected');
      return null;
    }

    final completer = Completer<dynamic>();
    logger.info('Emitting $event: $data');

    socket!.emitWithAck(
      event,
      data,
      ack: (response) {
        if (!completer.isCompleted) completer.complete(response);
      },
    );

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          if (!completer.isCompleted) {
            completer.completeError('Timeout waiting for ack');
          }
          return null;
        },
      );
    } catch (e) {
      logger.severe('Error emitting $event: $e');
      return null;
    }
  }

  void off(String event) {
    logger.info('Removing listener for event: $event');
    socket?.off(event);
  }

  void dispose() {
    socket?.dispose();
    socket = null;
  }

  // Add method to check connection status
  bool get isConnected => socket?.connected == true;
}
