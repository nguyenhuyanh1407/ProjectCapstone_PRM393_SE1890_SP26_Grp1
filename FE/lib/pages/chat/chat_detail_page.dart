import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../models/conversation.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();

  AppUser? _currentUser;
  String? _conversationId;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_conversationId != null) return;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _conversationId = args?['conversationId'] as String?;
    _init();
  }

  Future<void> _init() async {
    final user = await _authService.getCurrentUserData();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _loading = false;
    });

    if (_conversationId != null && user != null) {
      await _chatService.markConversationAsRead(
        conversationId: _conversationId!,
        userId: user.id,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null || _conversationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat detail')),
        body: const Center(child: Text('Conversation not found.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .snapshots(),
      builder: (context, conversationSnapshot) {
        if (conversationSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = conversationSnapshot.data?.data();
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat detail')),
            body: const Center(child: Text('Conversation not found.')),
          );
        }

        final conversation = Conversation.fromJson(
          data,
          conversationSnapshot.data!.id,
        );
        final title = conversation.getDisplayName(_currentUser!.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.getMessages(conversation.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data ?? const [];
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('No messages yet. Send the first one.'),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _chatService.markConversationAsRead(
                        conversationId: conversation.id,
                        userId: _currentUser!.id,
                      );
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMine = message.senderId == _currentUser!.id;
                        return _MessageBubble(message: message, isMine: isMine);
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _sendMessage(conversation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                        ),
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage(Conversation conversation) async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _currentUser == null) return;

    _messageController.clear();
    await _chatService.sendMessage(
      conversation: conversation,
      sender: _currentUser!,
      content: content,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMine ? AppColors.primary : Colors.white;
    final textColor = isMine ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            Text(message.content, style: TextStyle(color: textColor)),
            const SizedBox(height: 6),
            Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isMine ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
