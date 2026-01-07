import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/chat_message.dart';
import '../../services/akira_chatbot_service.dart';
import '../../theme/app_theme.dart';
import 'dart:async';

class AkiraChatScreen extends StatefulWidget {
  const AkiraChatScreen({super.key});

  @override
  State<AkiraChatScreen> createState() => _AkiraChatScreenState();
}

class _AkiraChatScreenState extends State<AkiraChatScreen>
    with SingleTickerProviderStateMixin {
  final AkiraChatbotService _chatbotService = AkiraChatbotService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  StreamSubscription<ChatMessage>? _messageSubscription;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Add welcome message
    _messages.add(
      ChatMessage(
        id: 'welcome',
        content:
            "Hello! I'm Akira 👋\n\nI'm your personal health and fitness assistant. I can help you with:\n\n• Nutrition and meal planning\n\n• Fitness and exercise guidance\n\n• Mental health and wellness\n\n• Presidential Fitness Test info\n\n• General health questions\n\nHow can I assist you today?",
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().toString(),
          content: message,
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Cancel any existing subscription
    await _messageSubscription?.cancel();

    // Listen to streaming response
    _messageSubscription =
        _chatbotService.sendMessageStream(message).listen((chatMessage) {
      setState(() {
        // Remove previous streaming message if exists
        _messages.removeWhere((msg) =>
            msg.id == chatMessage.id && msg.role == MessageRole.assistant);

        _messages.add(chatMessage);

        if (!chatMessage.isStreaming) {
          _isTyping = false;
        }
      });
      _scrollToBottom();
    }, onError: (error) {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            id: DateTime.now().toString(),
            content:
                "I apologize, but I'm having trouble right now. Please try again.",
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          ),
        );
      });
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.dialogDark,
        title: const Text('Clear Chat History'),
        content:
            const Text('Are you sure you want to clear all chat messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    id: 'welcome',
                    content:
                        "Hello again! I'm Akira. How can I help you with your health and fitness journey?",
                    role: MessageRole.assistant,
                    timestamp: DateTime.now(),
                  ),
                );
              });
              _chatbotService.clearHistory();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryLime, AppTheme.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryLime.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Akira',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLime,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 1.5.w),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.restart_alt_rounded, size: 22),
            onPressed: _clearChat,
            tooltip: 'New chat',
          ),
          SizedBox(width: 1.w),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(4.w),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                } else {
                  return _buildTypingIndicator();
                }
              },
            ),
          ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatarIcon(),
            SizedBox(width: 3.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: EdgeInsets.only(bottom: 1.h, left: 1.w),
                    child: Text(
                      'Akira',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(maxWidth: 85.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.5.w,
                    vertical: 2.5.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryLime,
                              AppTheme.primaryLime.withOpacity(0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 24 : 6),
                      topRight: Radius.circular(isUser ? 6 : 24),
                      bottomLeft: const Radius.circular(24),
                      bottomRight: const Radius.circular(24),
                    ),
                    border: !isUser
                        ? Border.all(
                            color: AppTheme.borderColor.withOpacity(0.2),
                            width: 1,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? AppTheme.primaryLime.withOpacity(0.15)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isUser
                          ? Text(
                              message.content,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            )
                          : MarkdownBody(
                              data: message.content,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  height: 1.7,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.15,
                                ),
                                strong: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.7,
                                  letterSpacing: 0.15,
                                ),
                                em: TextStyle(
                                  color: AppTheme.textPrimary.withOpacity(0.9),
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  height: 1.7,
                                ),
                                listBullet: TextStyle(
                                  color: AppTheme.primaryLime,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                h1: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                  letterSpacing: 0.3,
                                ),
                                h2: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                  letterSpacing: 0.3,
                                ),
                                h3: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                                code: TextStyle(
                                  backgroundColor:
                                      AppTheme.backgroundDark.withOpacity(0.5),
                                  color: AppTheme.primaryLime,
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                ),
                                blockquote: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              shrinkWrap: true,
                            ),
                      if (message.isStreaming)
                        Padding(
                          padding: EdgeInsets.only(top: 1.5.h),
                          child: _buildStreamingIndicator(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 3.w),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLime, AppTheme.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLime.withOpacity(0.25),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.psychology_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPurple,
            AppTheme.accentPurple.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPurple.withOpacity(0.25),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildStreamingIndicator() {
    return Row(
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryLime.withOpacity(0.6),
            ),
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          'Generating...',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatarIcon(),
          SizedBox(width: 3.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 1.h, left: 1.w),
                child: Text(
                  'Akira',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 5.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: AppTheme.borderColor.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0),
                    SizedBox(width: 1.5.w),
                    _buildTypingDot(200),
                    SizedBox(width: 1.5.w),
                    _buildTypingDot(400),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final value = (_typingAnimationController.value * 1500 - delay) % 1500;
        final opacity = (value < 500) ? (value / 500) : ((1500 - value) / 1000);

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryLime.withOpacity(opacity.clamp(0.2, 1.0)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 3.w, 4.w, 2.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.5.w),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.borderColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ask Akira anything...',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 1.8.h),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 2.5.w),
            GestureDetector(
              onTap: _isTyping ? null : _sendMessage,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: _isTyping
                      ? LinearGradient(
                          colors: [
                            AppTheme.textSecondary.withOpacity(0.5),
                            AppTheme.textTertiary.withOpacity(0.5),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            AppTheme.primaryLime,
                            AppTheme.accentBlue,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  shape: BoxShape.circle,
                  boxShadow: !_isTyping
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryLime.withOpacity(0.4),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                            spreadRadius: -2,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  _isTyping
                      ? Icons.hourglass_empty_rounded
                      : Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
