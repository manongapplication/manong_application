import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/models/chat_message.dart';
import 'package:manong_application/models/quick_response.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/help_utils.dart';
import 'package:manong_application/utils/url_utils.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  final Logger logger = Logger('HelpAndSupportScreen');
  bool _isLoading = false;
  bool _isButtonLoading = false;
  bool _showQuickResponses = true;
  final TextEditingController _messageController = TextEditingController();
  late ScrollController _scrollController;

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: -1,
      content:
          "Hello! I'm Manong Support Bot 🤖\n\nNote: This is an automated assistant. Your chat is completely private and not shared with anyone.\n\nHow can I help you today?",
      senderId: -1,
      receiverId: -1,
      createdAt: DateTime.now(),
      isSupport: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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

  void _sendQuickResponse(QuickResponse quickResponse) {
    FocusScope.of(context).unfocus();
    _addUserMessage(quickResponse.text);
    _addSupportMessage(quickResponse.response);
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(
          id: _messages.length,
          content: text,
          senderId: 1,
          receiverId: -1,
          createdAt: DateTime.now(),
          isSupport: false,
        ),
      );
    });
    _scrollToBottom();
  }

  void _addSupportMessage(String text) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: _messages.length,
              content: text,
              senderId: -1,
              receiverId: 1,
              createdAt: DateTime.now(),
              isSupport: true,
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();
    _addUserMessage(message);

    final response = HelpUtils().generateResponse(message);
    _addSupportMessage(response);
  }

  Widget _buildQuickResponseChips() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
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
        ),
        child: Column(
          children: [
            // Toggle Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColorScheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: AppColorScheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Help',
                      style: TextStyle(
                        color: AppColorScheme.primaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _showQuickResponses
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColorScheme.primaryColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _showQuickResponses = !_showQuickResponses;
                      });
                    },
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: _showQuickResponses ? 'Hide' : 'Show',
                  ),
                ),
              ],
            ),

            // Quick Response Chips
            if (_showQuickResponses) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HelpUtils().quickResponses.map((response) {
                  return GestureDetector(
                    onTap: () => _sendQuickResponse(response),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorScheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColorScheme.primaryColor.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        response.text,
                        style: TextStyle(
                          color: AppColorScheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          _buildQuickResponseChips(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
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
                    icon: _isButtonLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                    onPressed: _isButtonLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isSupport = message.isSupport;

                  return Container(
                    margin: EdgeInsets.only(
                      top: 4,
                      bottom: 4,
                      left: isSupport ? 8 : 50,
                      right: isSupport ? 50 : 8,
                    ),
                    child: Align(
                      alignment: isSupport
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
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
                              gradient: isSupport
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        AppColorScheme.primaryColor,
                                        AppColorScheme.primaryColor.withOpacity(
                                          0.9,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: isSupport ? Colors.white : null,
                              borderRadius: BorderRadius.circular(18).copyWith(
                                bottomLeft: isSupport
                                    ? const Radius.circular(4)
                                    : const Radius.circular(18),
                                bottomRight: isSupport
                                    ? const Radius.circular(18)
                                    : const Radius.circular(4),
                              ),
                              border: isSupport
                                  ? Border.all(
                                      color: Colors.grey.shade200,
                                      width: 0.5,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: isSupport
                                      ? Colors.black.withOpacity(0.02)
                                      : AppColorScheme.primaryColor.withOpacity(
                                          0.2,
                                        ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: SelectableText.rich(
                              TextSpan(
                                style: TextStyle(
                                  color: isSupport
                                      ? Colors.black87
                                      : Colors.white,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                                children: _parseFormattedText(
                                  message.content,
                                  isSupport: isSupport,
                                  context: context,
                                ),
                              ),
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
                              DateFormat.jm().format(message.createdAt),
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

  List<TextSpan> _parseFormattedText(
    String text, {
    required bool isSupport,
    required BuildContext context,
  }) {
    final spans = <TextSpan>[];
    int currentIndex = 0;

    final linkPattern = RegExp(r"\[link url='(.+?)'\](.+?)\[/link\]");
    final boldPattern = RegExp(r'\*\*(.+?)\*\*');

    while (currentIndex < text.length) {
      final nextLink = linkPattern.firstMatch(text.substring(currentIndex));
      final nextBold = boldPattern.firstMatch(text.substring(currentIndex));

      int? nextMatchStart;
      int? nextMatchEnd;
      bool isLink = false;
      String? url;
      String? content;

      if (nextLink != null && nextBold != null) {
        if (nextLink.start < nextBold.start) {
          nextMatchStart = nextLink.start + currentIndex;
          nextMatchEnd = nextLink.end + currentIndex;
          isLink = true;
          url = nextLink.group(1);
          content = nextLink.group(2);
        } else {
          nextMatchStart = nextBold.start + currentIndex;
          nextMatchEnd = nextBold.end + currentIndex;
          content = nextBold.group(1);
        }
      } else if (nextLink != null) {
        nextMatchStart = nextLink.start + currentIndex;
        nextMatchEnd = nextLink.end + currentIndex;
        isLink = true;
        url = nextLink.group(1);
        content = nextLink.group(2);
      } else if (nextBold != null) {
        nextMatchStart = nextBold.start + currentIndex;
        nextMatchEnd = nextBold.end + currentIndex;
        content = nextBold.group(1);
      }

      if (nextMatchStart != null && nextMatchStart > currentIndex) {
        final beforeText = text.substring(currentIndex, nextMatchStart);
        spans.add(TextSpan(text: beforeText));
      }

      if (nextMatchStart != null && content != null) {
        if (isLink && url != null) {
          spans.add(
            TextSpan(
              text: content,
              style: TextStyle(
                color: isSupport
                    ? AppColorScheme.primaryColor
                    : Colors.blue[200],
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _handleLinkTap(url ?? '', context);
                },
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: content,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        }

        currentIndex = nextMatchEnd!;
      } else {
        final remainingText = text.substring(currentIndex);
        spans.add(TextSpan(text: remainingText));
        break;
      }
    }

    return spans;
  }

  Future<void> _handleLinkTap(String url, BuildContext context) async {
    try {
      await launchInBrowser(url);
    } catch (e) {
      logger.severe('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(
        title: 'Help & Support',
        leading: CircleAvatar(
          backgroundColor: AppColorScheme.backgroundGrey,
          foregroundColor: AppColorScheme.primaryDark,
          child: const Icon(Icons.support_agent),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(child: _buildChatArea()),
            SafeArea(child: _buildInputArea()),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
