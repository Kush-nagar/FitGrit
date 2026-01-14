import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/chat_message.dart';
import '../../services/akira_chatbot_service.dart';
import '../../widgets/custom_bottom_bar.dart';
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
            "Hello! I'm Atlas 👋\n\nI'm your personal health and fitness assistant. I can help you with:\n\n• Nutrition and meal planning\n\n• Fitness and exercise guidance\n\n• Mental health and wellness\n\n• Presidential Fitness Test info\n\n• General health questions\n\nHow can I assist you today?",
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(
          'Clear Chat History',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        content: Text(
          'Are you sure you want to clear all chat messages?',
          style: TextStyle(
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    id: 'welcome',
                    content:
                        "Hello again! I'm Atlas. How can I help you with your health and fitness journey?",
                    role: MessageRole.assistant,
                    timestamp: DateTime.now(),
                  ),
                );
              });
              _chatbotService.clearHistory();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        elevation: 0,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0A84FF), const Color(0xFF5E5CE6)]
                      : [const Color(0xFF007AFF), const Color(0xFF5856D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atlas',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6C6C70),
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
            ),
            onPressed: _clearChat,
            tooltip: 'New chat',
          ),
          SizedBox(width: 0.5.w),
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
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/akira-chat-screen',
        onNavigate: (route) {
          if (route != '/akira-chat-screen') {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatarIcon(),
            SizedBox(width: 2.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 75.w),
              padding: EdgeInsets.symmetric(
                horizontal: 3.5.w,
                vertical: 1.8.h,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF))
                    : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
                borderRadius: BorderRadius.circular(18),
                boxShadow: isUser
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.3,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 16,
                              height: 1.45,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.3,
                            ),
                            strong: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                              letterSpacing: -0.3,
                            ),
                            em: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.black.withOpacity(0.9),
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              height: 1.45,
                            ),
                            listBullet: TextStyle(
                              color: isDark
                                  ? const Color(0xFF0A84FF)
                                  : const Color(0xFF007AFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            h1: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              letterSpacing: -0.4,
                            ),
                            h2: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              letterSpacing: -0.4,
                            ),
                            h3: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            code: TextStyle(
                              backgroundColor: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFE5E5EA),
                              color: isDark
                                  ? const Color(0xFF0A84FF)
                                  : const Color(0xFF007AFF),
                              fontSize: 15,
                              fontFamily: 'monospace',
                            ),
                            blockquote: TextStyle(
                              color: isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6C6C70),
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          shrinkWrap: true,
                        ),
                  if (message.isStreaming)
                    Padding(
                      padding: EdgeInsets.only(top: 1.h),
                      child: _buildStreamingIndicator(),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 2.w),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarIcon() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0A84FF), const Color(0xFF5E5CE6)]
              : [const Color(0xFF007AFF), const Color(0xFF5856D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.bolt_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: isDark ? Colors.white : const Color(0xFF3C3C43),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildStreamingIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
            ),
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          'Thinking...',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatarIcon(),
          SizedBox(width: 2.w),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 3.5.w,
              vertical: 1.8.h,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                SizedBox(width: 1.w),
                _buildTypingDot(200),
                SizedBox(width: 1.w),
                _buildTypingDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final value = (_typingAnimationController.value * 1500 - delay) % 1500;
        final opacity = (value < 500) ? (value / 500) : ((1500 - value) / 1000);

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70))
                .withOpacity(opacity.clamp(0.3, 1.0)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.fromLTRB(3.w, 2.w, 3.w, 1.5.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF38383A)
                : const Color(0xFFC6C6C8),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.5.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFD1D1D6),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    letterSpacing: -0.3,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6C6C70),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.3,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: _isTyping ? null : _sendMessage,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _isTyping
                      ? (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6))
                      : (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: _isTyping
                      ? (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70))
                      : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
