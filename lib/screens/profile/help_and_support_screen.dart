import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/models/chat_message.dart';
import 'package:manong_application/models/quick_response.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/help_utils.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  final Logger logger = Logger('HelpAndSupportScreen');
  bool _isLoading = false;
  bool _isButtonLoading = false;
  bool _showQuickResponses = true; // NEW: Control variable for showing/hiding
  final TextEditingController _messageController = TextEditingController();
  late ScrollController _scrollController;

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: -1,
      content: "Hello! I'm Manong Support Bot 🤖\n\nHow can I help you today?",
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

    // Generate intelligent response based on message content
    final response = HelpUtils().generateResponse(message);
    _addSupportMessage(response);
  }

  // UPDATED: Modified to include toggle button
  Widget _buildQuickResponseChips() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.white,
        child: Column(
          children: [
            // Toggle Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Responses',
                  style: TextStyle(
                    color: AppColorScheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showQuickResponses
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColorScheme.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _showQuickResponses = !_showQuickResponses;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _showQuickResponses ? 'Hide' : 'Show',
                ),
              ],
            ),
            // Quick Response Chips (conditionally shown)
            if (_showQuickResponses) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HelpUtils().quickResponses.map((response) {
                  return GestureDetector(
                    onTap: () => _sendQuickResponse(response),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorScheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColorScheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        response.text,
                        style: TextStyle(
                          color: AppColorScheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  // Alternative: Simple toggle without header
  Widget _buildSimpleToggleQuickResponseChips() {
    return Column(
      children: [
        // Toggle button row
        Container(
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Quick Responses',
                style: TextStyle(
                  color: AppColorScheme.primaryColor,
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showQuickResponses ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: AppColorScheme.primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _showQuickResponses = !_showQuickResponses;
                  });
                },
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
        ),
        // Quick responses with animation
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showQuickResponses
              ? Container(
                  key: const ValueKey('quickResponses'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: HelpUtils().quickResponses.map((response) {
                      return GestureDetector(
                        onTap: () => _sendQuickResponse(response),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorScheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColorScheme.primaryColor.withOpacity(
                                0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            response.text,
                            style: TextStyle(
                              color: AppColorScheme.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Choose one of these:
          _buildQuickResponseChips(), // Option 1: With header toggle
          // _buildSimpleToggleQuickResponseChips(), // Option 2: Simple toggle
          // _buildDraggableQuickResponseArea(), // Option 3: Draggable area
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: TextFormField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: inputDecoration('Type your message here...'),
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
                  onTap: _isButtonLoading ? null : _sendMessage,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Padding(
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

                return Align(
                  alignment: isSupport
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSupport
                          ? Colors.grey[300]
                          : AppColorScheme.primaryColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: isSupport ? Colors.black : Colors.white,
                              fontSize: 16,
                            ),
                            children: _parseFormattedText(
                              message.content,
                              isSupport: isSupport,
                              context: context,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.jm().format(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSupport
                                ? Colors.grey[600]
                                : Colors.white70,
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
                fontWeight: FontWeight.bold,
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
              style: const TextStyle(fontWeight: FontWeight.bold),
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
          const SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> launchInBrowser(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
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
