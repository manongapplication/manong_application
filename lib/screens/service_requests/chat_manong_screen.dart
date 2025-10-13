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
  final List<Chat> _chat = [
    Chat(
      id: -1,
      roomId: '',
      content:
          "Hello! 👋 You can chat here with Manong. Describe your problem or any concerns you have.",
      senderId: -1,
      receiverId: -1,
      createdAt: DateTime.now(),
    ),
  ];

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
    });

    try {
      if (_user == null) {
        logger.info('Empty user');
        return;
      }

      // Set up listeners FIRST
      _chatApiService.onHistory((data) {
        logger.info('Processing chat history with ${data.length} messages');
        if (mounted) {
          setState(() {
            // Clear existing messages except system message
            _chat.clear();

            // Add system message back
            _chat.add(
              Chat(
                id: -1,
                roomId: '',
                content:
                    "Hello! 👋 You can chat here with Manong. Describe your problem or any concerns you have.",
                senderId: -1,
                receiverId: -1,
                createdAt: DateTime.now(),
              ),
            );

            // Add history messages
            _chat.addAll(data.map((json) => Chat.fromJson(json)));
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
    } catch (e) {
      logger.severe('Error loading chats: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
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

      // if (_images.isEmpty) {
      //   setState(() {
      //     _chat.add(response);
      //   });
      // }

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
                if (item.content.isEmpty &&
                    (item.attachments == null || item.attachments!.isEmpty)) {
                  return const SizedBox.shrink();
                }
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

                        Text(
                          DateFormat.jm().format(item.createdAt),
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage(
      requestFullMetadata: false,
    );

    if (images == null || images.isEmpty) return;

    if (images.length > 3) {
      SnackBarUtils.showWarning(
        navigatorKey.currentContext!,
        'You can upload a maximum of 3 images',
      );
      return;
    }

    List<File> compressedImages = [];

    for (var xfile in images) {
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        xfile.path,
        '${xfile.path}_compressed.jpg',
        minWidth: 1024, // maximum width
        minHeight: 1024, // maximum height
        quality: 60,
      );

      if (compressedFile != null) {
        // Convert XFile to File
        compressedImages.add(File(compressedFile.path));
      }
    }

    setState(() {
      _images = compressedImages;
    });
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

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                if (_images.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
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
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    img,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _images.remove(img);
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 24,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 150),
                        child: TextFormField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: inputDecoration(
                            'Send a message...',
                            suffixIcon: InkWell(
                              onTap: _pickImage,
                              child: Icon(Icons.image),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColorScheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),

                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _isButtonLoading ? null : _sendMessage,
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
        leading: CircleAvatar(
          backgroundColor: AppColorScheme.backgroundGrey,
          foregroundColor: AppColorScheme.primaryDark,
          child: Icon(Icons.person),
        ),
      ),
      body: _buildState(),
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
