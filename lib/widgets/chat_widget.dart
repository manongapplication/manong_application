import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/api/chat_api_service.dart';
import 'package:manong_application/api/image_upload_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/chat.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/models/service_request_status.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/image_dialog.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ChatWidget extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final VoidCallback onClose;
  final bool isFullScreen;

  const ChatWidget({
    super.key,
    required this.serviceRequest,
    required this.onClose,
    this.isFullScreen = false,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final Logger logger = Logger('ChatWidget');
  late ServiceRequest _serviceRequest;
  late AuthService _authService;
  late ChatApiService _chatApiService;
  bool _isLoading = true;
  bool _isButtonLoading = false;
  String? _error;
  AppUser? _user;
  String? _title;
  late String? _baseImageUrl;
  late List<File> _images;
  final TextEditingController _messageController = TextEditingController();
  late ScrollController _scrollController;
  late ImageUploadApiService _imageUploadService;
  final List<Chat> _chat = [];
  bool _canSendMessages = true;
  bool _isChatExpired = false;
  bool _isChatCancelled = false;
  bool _hasLoadedHistory = false;
  final int _maxImages = 3;

  // Track sending state
  bool _isSending = false;
  int? _currentTempId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initializeComponents();
    initializeMethods();
  }

  void initializeComponents() {
    _serviceRequest = widget.serviceRequest;
    _authService = AuthService();
    _chatApiService = ChatApiService();
    _images = <File>[];
    _baseImageUrl = dotenv.env['APP_URL']?.replaceAll(RegExp(r'/$'), '');
    _imageUploadService = ImageUploadApiService();
  }

  void checkChatStatus() {
    final now = DateTime.now();
    Duration diff = now.difference(_serviceRequest.createdAt!);

    _isChatExpired = diff.inDays >= 7;
    _isChatCancelled = _serviceRequest.status == ServiceRequestStatus.cancelled;

    _canSendMessages = !_isChatExpired && !_isChatCancelled;

    _chat.removeWhere((c) => c.id == -1);

    if (_hasLoadedHistory) {
      String systemMessage;
      if (_isChatCancelled) {
        systemMessage =
            "❌ This service request has been cancelled. You can view the chat history but cannot send new messages.";
      } else if (_isChatExpired) {
        systemMessage =
            "🕒 This chat session has ended (7 days have passed). You can view the chat history but cannot send new messages.";
      } else {
        systemMessage =
            "Hello! 👋 You can chat here with Manong. Describe your problem or any concerns you have.";
      }

      _chat.insert(
        0,
        Chat(
          id: -1,
          roomId: '',
          content: systemMessage,
          senderId: -1,
          receiverId: -1,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> initializeMethods() async {
    await _fetchUser();
    if (_user != null) {
      _loadChats();
    } else {
      logger.warning('User is null, cannot join chat room');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _fetchUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _authService.getMyProfile();

      if (!mounted) return;
      setState(() {
        _error = null;
        _user = response;
        _title = _serviceRequest.manongId == _user?.id
            ? _user?.phone
            : 'Manong ${_serviceRequest.manong?.appUser.firstName?.split(' ')[0]}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      logger.severe('Error fetching user $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasLoadedHistory = false;
    });

    try {
      if (_user == null) {
        logger.info('Empty user');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _chat.clear();
        _chat.add(
          Chat(
            id: -2,
            roomId: '',
            content: "Loading conversations...",
            senderId: -2,
            receiverId: -2,
            createdAt: DateTime.now(),
          ),
        );
      });

      _chatApiService.onHistory((data) {
        logger.info('Processing chat history with ${data.length} messages');
        if (mounted) {
          setState(() {
            _chat.clear();
            _chat.addAll(data.map((json) => Chat.fromJson(json)));
            _hasLoadedHistory = true;
            checkChatStatus();
          });
          _scrollToBottom();
        }
      });

      _chatApiService.onMessageUpdate((data) {
        if (!mounted) return;
        final updated = Chat.fromJson(data);

        setState(() {
          // Check if this is our own message and we have a temp message
          if (updated.senderId == _user?.id && _currentTempId != null) {
            // Find and replace the temp message
            final tempIndex = _chat.indexWhere((c) => c.id == _currentTempId);
            if (tempIndex != -1) {
              logger.info('Replacing temp message with real one');
              _chat[tempIndex] = updated;
              _currentTempId = null;
              return;
            }
          }

          // For other messages, check if already exists
          final existingIndex = _chat.indexWhere((c) => c.id == updated.id);
          if (existingIndex != -1) {
            _chat[existingIndex] = updated;
          } else {
            _chat.add(updated);
          }
        });

        _scrollToBottom();
      });

      await _chatApiService.joinRoom(
        senderId: _user!.id,
        receiverId: _user!.id == _serviceRequest.manongId!
            ? _serviceRequest.userId!
            : _serviceRequest.manongId!,
        userId: _serviceRequest.userId!,
        manongId: _serviceRequest.manongId!,
        serviceRequestId: _serviceRequest.id!,
      );

      logger.info('Successfully joined chat room');

      Future.delayed(Duration(seconds: 3), () {
        if (mounted && !_hasLoadedHistory) {
          logger.warning('Chat history timeout - no messages received');
          setState(() {
            _hasLoadedHistory = true;
            _chat.removeWhere((c) => c.id == -2);
            checkChatStatus();
          });
        }
      });
    } catch (e) {
      logger.severe('Error loading chats: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _hasLoadedHistory = true;
          _chat.removeWhere((c) => c.id == -2);
          checkChatStatus();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_images.isEmpty && _messageController.text.isEmpty) return;
    if (_isSending) return; // Prevent multiple sends

    if (!_canSendMessages) {
      SnackBarUtils.showWarning(
        navigatorKey.currentContext!,
        _isChatCancelled
            ? 'Cannot send messages: Service request has been cancelled'
            : 'Cannot send messages: Chat session has ended (7 days have passed)',
      );
      return;
    }

    setState(() {
      _isSending = true;
      _isButtonLoading = true;
    });

    final String messageText = _messageController.text;
    final List<File> currentImages = List.from(_images);
    final tempId = -(DateTime.now().millisecondsSinceEpoch);
    _currentTempId = tempId;

    // Create temporary attachments for preview
    List<ChatAttachment> tempAttachments = [];
    if (currentImages.isNotEmpty) {
      tempAttachments = currentImages.map((file) {
        return ChatAttachment(id: tempId, type: 'image', url: file.path);
      }).toList();
    }

    final tempMessage = Chat(
      id: tempId,
      roomId: '',
      content: messageText,
      senderId: _user!.id,
      receiverId: _user!.id == _serviceRequest.manongId!
          ? _serviceRequest.userId!
          : _serviceRequest.manongId!,
      createdAt: DateTime.now(),
      attachments: tempAttachments.isNotEmpty ? tempAttachments : null,
      isLoading: true,
    );

    // Optimistic UI update
    setState(() {
      _chat.add(tempMessage);
      _messageController.clear();
      _images.clear();
      _isButtonLoading = false;
    });

    _scrollToBottom();

    try {
      if (_user == null) return;

      final response = await _chatApiService.sendMessage(
        senderId: _user!.id,
        receiverId: _user!.id == _serviceRequest.manongId!
            ? _serviceRequest.userId!
            : _serviceRequest.manongId!,
        userId: _serviceRequest.userId!,
        manongId: _serviceRequest.manongId!,
        serviceRequestId: _serviceRequest.id!,
        content: messageText,
        attachments: null,
      );

      if (response == null) {
        // Message failed - remove temp message
        setState(() {
          _chat.removeWhere((msg) => msg.id == tempId);
          _currentTempId = null;
        });
        SnackBarUtils.showError(
          context,
          'Failed to send message. Please try again.',
        );
        return;
      }

      final messageId = response.id;

      if (currentImages.isNotEmpty) {
        try {
          await _imageUploadService.uploadImages(
            serviceRequestId: _serviceRequest.id!,
            messageId: messageId,
            images: currentImages,
          );
          // WebSocket will handle replacement
        } catch (e) {
          logger.warning('Image upload failed: $e');
          SnackBarUtils.showWarning(
            context,
            'Message sent but images failed to upload',
          );
          // WebSocket will still send the message without images
        }
      }
      // WebSocket will handle replacement for all cases
    } catch (e) {
      // Error occurred - remove temp message
      setState(() {
        _chat.removeWhere((msg) => msg.id == tempId);
        _currentTempId = null;
      });

      logger.severe('Error sending message: $e');
      SnackBarUtils.showError(
        context,
        'Failed to send message. Please check your connection.',
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Widget _buildChatArea() {
    return Container(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: false,
                itemCount: _chat.length,
                itemBuilder: (context, index) {
                  final item = _chat[index];
                  final isMe = item.senderId == _user?.id;
                  final isSystemMessage = item.id == -1;
                  final isLoadingMessage = item.id == -2;

                  if (item.content.isEmpty &&
                      (item.attachments == null || item.attachments!.isEmpty)) {
                    return const SizedBox.shrink();
                  }

                  // Loading state - cleaner iOS style
                  if (isLoadingMessage) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColorScheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.content,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // System message - iOS style info card
                  if (isSystemMessage) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isChatCancelled
                              ? Colors.red.shade200
                              : (_isChatExpired
                                    ? Colors.orange.shade200
                                    : Colors.blue.shade200),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isChatCancelled
                                  ? Colors.red.shade50
                                  : (_isChatExpired
                                        ? Colors.orange.shade50
                                        : Colors.blue.shade50),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _isChatCancelled
                                  ? Icons.cancel_rounded
                                  : (_isChatExpired
                                        ? Icons.hourglass_empty_rounded
                                        : Icons.info_rounded),
                              color: _isChatCancelled
                                  ? Colors.red
                                  : (_isChatExpired
                                        ? Colors.orange
                                        : Colors.blue),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.content,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final localTime = item.createdAt.toLocal();

                  // Regular message - iOS style bubbles
                  return Container(
                    margin: EdgeInsets.only(
                      top: 4,
                      bottom: 4,
                      left: isMe ? 50 : 8,
                      right: isMe ? 8 : 50,
                    ),
                    child: Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Message bubble
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: isMe
                                  ? LinearGradient(
                                      colors: [
                                        AppColorScheme.primaryColor,
                                        AppColorScheme.primaryColor.withOpacity(
                                          0.9,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isMe ? null : Colors.white,
                              borderRadius: BorderRadius.circular(18).copyWith(
                                bottomLeft: isMe
                                    ? const Radius.circular(18)
                                    : const Radius.circular(4),
                                bottomRight: isMe
                                    ? const Radius.circular(4)
                                    : const Radius.circular(18),
                              ),
                              border: isMe
                                  ? null
                                  : Border.all(
                                      color: Colors.grey.shade200,
                                      width: 0.5,
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: isMe
                                      ? AppColorScheme.primaryColor.withOpacity(
                                          0.2,
                                        )
                                      : Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Message content with loading indicator
                                if (item.isLoading == true)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.content,
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 15,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                isMe
                                                    ? Colors.white70
                                                    : Colors.grey.shade400,
                                              ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  SelectableText(
                                    item.content,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),

                                // Image attachments
                                if (item.attachments != null &&
                                    item.attachments!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: item.attachments!.map((att) {
                                      if (item.isLoading &&
                                          att.url.startsWith('/')) {
                                        return GestureDetector(
                                          onTap: () => _showImageDialog(
                                            File(att.url),
                                            navigatorKey.currentContext!,
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.file(
                                                  File(att.url),
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        width: 100,
                                                        height: 100,
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                              if (item.isLoading)
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Center(
                                                      child: SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        final normalizedPath = att.url
                                            .replaceAll("\\", "/")
                                            .replaceAll(RegExp(r'^/+'), '');
                                        final imageUrl =
                                            '$_baseImageUrl/$normalizedPath';

                                        return GestureDetector(
                                          onTap: () => _showImageDialogNetwork(
                                            imageUrl,
                                            navigatorKey.currentContext!,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.network(
                                              imageUrl,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  Container(
                                                    width: 100,
                                                    height: 100,
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        );
                                      }
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Timestamp
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              top: 4,
                            ),
                            child: Text(
                              item.isLoading == true
                                  ? 'Sending...'
                                  : DateFormat.jm().format(localTime),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _compressImage(XFile xfile) async {
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      xfile.path,
      '${xfile.path}_compressed.jpg',
      minWidth: 1024,
      minHeight: 1024,
      quality: 60,
    );

    if (compressedFile == null) return null;
    return File(compressedFile.path);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_canSendMessages) {
      SnackBarUtils.showWarning(
        navigatorKey.currentContext!,
        _isChatCancelled
            ? 'Cannot send messages: Service request has been cancelled'
            : 'Cannot send messages: Chat session has ended (7 days have passed)',
      );
      return;
    }

    final ImagePicker picker = ImagePicker();

    Future<File?> _compressImage(XFile xfile) async {
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        xfile.path,
        '${xfile.path}_compressed.jpg',
        minWidth: 1024,
        minHeight: 1024,
        quality: 60,
      );
      return compressedFile != null ? File(compressedFile.path) : null;
    }

    if (source == ImageSource.gallery) {
      final List<XFile>? images = await picker.pickMultiImage(
        requestFullMetadata: false,
      );

      if (images == null || images.isEmpty) return;

      if ((_images.length + images.length) > _maxImages) {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'You can upload a maximum of 5 images',
        );
        return;
      }

      final List<File> compressedImages = [];
      for (final xfile in images) {
        final file = await _compressImage(xfile);
        if (file != null) compressedImages.add(file);
      }

      setState(() {
        _images.addAll(compressedImages);
      });
    } else {
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      if (_images.length >= 3) {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'You can upload a maximum of 3 images',
        );
        return;
      }

      final File? compressed = await _compressImage(pickedFile);
      if (compressed == null) return;

      setState(() {
        _images.add(compressed);
      });
    }
  }

  void _showImageDialog(File image, BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ImageDialog(image: image, imageString: null),
    );
  }

  void _showImageDialogNetwork(String url, BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ImageDialog(image: null, imageString: url),
    );
  }

  Widget _buildStack() {
    if (_user == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (!widget.isFullScreen)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColorScheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chat,
                    color: AppColorScheme.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chat with ${_serviceRequest.manong?.appUser.firstName ?? 'Manong'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                  ),
                ),
              ],
            ),
          ),

        Expanded(child: _buildChatArea()),

        if (_canSendMessages)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              children: [
                if (_images.isNotEmpty) ...[
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemBuilder: (context, index) {
                        final img = _images[index];
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.all(4),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(img, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _images.remove(img)),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 5,
                                enabled: _canSendMessages && !_isSending,
                                decoration: InputDecoration(
                                  hintText: 'Message...',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.grey.shade600,
                                    size: 22,
                                  ),
                                  onPressed: _isSending
                                      ? null
                                      : () => _pickImage(ImageSource.camera),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.image_outlined,
                                    color: Colors.grey.shade600,
                                    size: 22,
                                  ),
                                  onPressed: _isSending
                                      ? null
                                      : () => _pickImage(ImageSource.gallery),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColorScheme.primaryColor,
                            AppColorScheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColorScheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward,
                                color: Colors.white,
                              ),
                        onPressed:
                            (_isButtonLoading ||
                                !_canSendMessages ||
                                _isSending)
                            ? null
                            : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (!_canSendMessages)
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isChatCancelled ? Icons.cancel : Icons.access_time,
                  color: _isChatCancelled ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _isChatCancelled
                      ? 'Chat ended: Service request cancelled'
                      : 'Chat ended: 7 days have passed',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(errorText: _error!, onPressed: _fetchUser);
    }

    if (_isLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColorScheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildStack();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: _buildState(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    if (_user != null) {
      _chatApiService.disconnect(
        userId: _serviceRequest.userId!,
        manongId: _serviceRequest.manongId!,
        serviceRequestId: _serviceRequest.id!,
      );
    }
    super.dispose();
  }
}
