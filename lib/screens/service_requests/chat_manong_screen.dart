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
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ChatManongScreen extends StatefulWidget {
  final ServiceRequest serviceRequest;
  const ChatManongScreen({super.key, required this.serviceRequest});

  @override
  State<ChatManongScreen> createState() => _ChatManongScreenState();
}

class _ChatManongScreenState extends State<ChatManongScreen> {
  final Logger logger = Logger('ChatManongScreen');
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
  final List<Chat> _chat = []; // Start with empty list
  bool _canSendMessages = true;
  bool _isChatExpired = false;
  bool _isChatCancelled = false;
  bool _hasLoadedHistory = false; // Track if history has been loaded
  final int _maxImages = 3;

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

    // User can only send messages if chat is NOT expired AND NOT cancelled
    _canSendMessages = !_isChatExpired && !_isChatCancelled;

    // Remove any existing system messages with id -1
    _chat.removeWhere((c) => c.id == -1);

    // Only add system message AFTER history is loaded
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

      // Insert system message at the beginning
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

      // Clear chat and show loading
      setState(() {
        _chat.clear();
        // Add a temporary loading message
        _chat.add(
          Chat(
            id: -2,
            roomId: '',
            content: "Loading chat history...",
            senderId: -2,
            receiverId: -2,
            createdAt: DateTime.now(),
          ),
        );
      });

      // Set up listeners FIRST
      _chatApiService.onHistory((data) {
        logger.info('Processing chat history with ${data.length} messages');
        if (mounted) {
          setState(() {
            // Clear all messages including loading
            _chat.clear();

            // Add history messages
            _chat.addAll(data.map((json) => Chat.fromJson(json)));

            // Mark history as loaded
            _hasLoadedHistory = true;

            // Add system message based on chat status
            checkChatStatus();
          });

          _scrollToBottom();
        }
      });

      _chatApiService.onMessageUpdate((data) {
        if (!mounted) return;
        final updated = Chat.fromJson(data);
        setState(() {
          final index = _chat.indexWhere((c) => c.id == updated.id);
          if (index != -1) {
            // replace existing message
            _chat[index] = updated;
          } else {
            // add new one
            _chat.add(updated);
          }
        });

        _scrollToBottom();
      });

      // Now join the room - this should trigger the history callback
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

      // Add timeout in case history doesn't arrive
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && !_hasLoadedHistory) {
          logger.warning('Chat history timeout - no messages received');
          setState(() {
            _hasLoadedHistory = true;
            // Remove loading message if still present
            _chat.removeWhere((c) => c.id == -2);
            // Add system message
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
          // Remove loading message
          _chat.removeWhere((c) => c.id == -2);
          // Add system message
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

    // Prevent sending if chat is expired or cancelled
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
      _isButtonLoading = true;
      _error = null;
    });

    try {
      if (_user == null) return;

      // 1️ Send message first without attachments
      final response = await _chatApiService.sendMessage(
        senderId: _user!.id,
        receiverId: _user!.id == _serviceRequest.manongId!
            ? _serviceRequest.userId!
            : _serviceRequest.manongId!,
        userId: _serviceRequest.userId!,
        manongId: _serviceRequest.manongId!,
        serviceRequestId: _serviceRequest.id!,
        content: _messageController.text,
        attachments: null,
      );

      if (response == null) {
        logger.warning('Message not sent, aborting image upload');
        return;
      }

      final messageId = response.id;

      // 3️ Upload images if there are any
      if (_images.isNotEmpty) {
        await _imageUploadService.uploadImages(
          serviceRequestId: _serviceRequest.id!,
          messageId: messageId,
          images: _images,
        );
      }

      // 4️ Clear input & images
      _messageController.clear();
      _images.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error sending message $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Widget _buildChatArea() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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

                // Loading message styling
                if (isLoadingMessage) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // System message styling
                if (isSystemMessage) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                      border: Border.all(
                        color: _isChatCancelled
                            ? Colors.red.shade100
                            : (_isChatExpired
                                  ? Colors.orange.shade100
                                  : Colors.blue.shade100),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isChatCancelled
                              ? Icons.cancel
                              : (_isChatExpired
                                    ? Icons.access_time
                                    : Icons.info),
                          color: _isChatCancelled
                              ? Colors.red
                              : (_isChatExpired ? Colors.orange : Colors.blue),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.content,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Convert UTC time to local time
                final localTime = item.createdAt.toLocal(); // Add this line

                // Regular message styling
                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isMe
                          ? AppColorScheme.primaryColor
                          : Colors.grey[300],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (item.attachments != null &&
                            item.attachments!.isNotEmpty) ...[
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: item.attachments!.map((att) {
                              final normalizedPath = att.url
                                  .replaceAll("\\", "/")
                                  .replaceAll(RegExp(r'^/+'), '');
                              final imageUrl = '$_baseImageUrl/$normalizedPath';

                              return GestureDetector(
                                onTap: () => _showImageDialogNetwork(
                                  imageUrl,
                                  navigatorKey.currentContext!,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 4),
                        ],

                        // Use localTime instead of item.createdAt
                        Text(
                          DateFormat.jm().format(localTime), // Changed here
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
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

    // Helper function for compression
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

      // Check combined total
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

      // Check max images
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
      builder: (_) => ImageDialog(image: image),
    );
  }

  void _showImageDialogNetwork(String url, BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.all(8), // less padding, bigger dialog
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            alignment: Alignment.center,
            child: Image.network(
              url,
              fit: BoxFit.contain, // scale while keeping aspect ratio
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStack() {
    if (_user == null) return const SizedBox.shrink();
    return SafeArea(
      child: Column(
        children: [
          Expanded(child: _buildChatArea()),

          // Only show input area if chat is still active
          if (_canSendMessages)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  if (_images.isNotEmpty) ...[
                    SizedBox(
                      height: 110,
                      child: Row(
                        children: [
                          // Image previews
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              itemBuilder: (context, index) {
                                final img = _images[index];
                                return Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: InkWell(
                                        onTap: () => _showImageDialog(
                                          img,
                                          navigatorKey.currentContext!,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.file(
                                            img,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Close button
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _images.remove(img);
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Image count
                          Container(
                            margin: const EdgeInsets.only(left: 8, right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_images.length}/$_maxImages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 150),
                          child: TextFormField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: null,
                            enabled: _canSendMessages,
                            keyboardType: TextInputType.multiline,
                            decoration: inputDecoration(
                              'Send a message...',
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _pickImage(ImageSource.camera),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Icon(Icons.camera_alt),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () =>
                                        _pickImage(ImageSource.gallery),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Icon(Icons.image),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColorScheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),

                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _isButtonLoading || !_canSendMessages
                              ? null
                              : _sendMessage,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Show a message when chat is ended
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
      ),
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(errorText: _error!, onPressed: _fetchUser);
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
      );
    }

    return _buildStack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(
        title: _title ?? 'Manong',
        subtitle: !_canSendMessages ? 'View only' : null,
        leading: CircleAvatar(
          backgroundColor: AppColorScheme.backgroundGrey,
          foregroundColor: AppColorScheme.primaryDark,
          child: Icon(Icons.person),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: _buildState(),
      ),
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
