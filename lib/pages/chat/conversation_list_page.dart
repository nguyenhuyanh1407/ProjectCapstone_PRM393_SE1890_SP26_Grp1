import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/conversation.dart';
import '../../services/chat_service.dart';
import '../../widgets/conversation_tile.dart';
import 'chat_detail_page.dart';

class ConversationListPage extends StatefulWidget {
  const ConversationListPage({super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final conversations = await _chatService.getConversations();
    if (!mounted) return;
    setState(() {
      _conversations = conversations;
      _isLoading = false;
    });
  }

  Future<void> _openChat(Conversation conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(conversation: conversation),
      ),
    );
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Traveler - Guide chat demo',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Messages are loaded from local mock JSON and new messages stay in memory for the current app session.',
                        ),
                      ],
                    ),
                  ),
                  ..._conversations.map(
                    (conversation) => ConversationTile(
                      conversation: conversation,
                      onTap: () => _openChat(conversation),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
