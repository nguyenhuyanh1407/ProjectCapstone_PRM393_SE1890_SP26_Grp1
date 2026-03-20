import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/conversation.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final AdminService _adminService = AdminService();

  AppUser? _currentUser;
  bool _loadingCurrentUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUserData();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _loadingCurrentUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCurrentUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Please log in again to use chat.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCurrentUser,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Recent conversations'),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: StreamBuilder<List<Conversation>>(
                stream: _chatService.getConversationsForUser(_currentUser!.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final conversations = snapshot.data ?? const [];
                  if (conversations.isEmpty) {
                    return const _EmptyCard(
                      title: 'No conversations yet',
                      subtitle: 'Start a chat with another user below.',
                    );
                  }

                  return ListView.separated(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) => _ConversationTile(
                      conversation: conversations[index],
                      currentUserId: _currentUser!.id,
                      onTap: () => _openConversation(conversations[index]),
                    ),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Start a new chat'),
            const SizedBox(height: 12),
            StreamBuilder<List<AppUser>>(
              stream: _adminService.streamUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = (snapshot.data ?? const [])
                    .where(
                      (user) =>
                          user.id != _currentUser!.id &&
                          user.isActive &&
                          _chatService.canStartDirectConversation(
                            currentUserRole: _currentUser!.role,
                            otherUserRole: user.role,
                          ),
                    )
                    .toList();

                if (users.isEmpty) {
                  return _EmptyCard(
                    title: 'No available users to chat',
                    subtitle: _emptyStateSubtitle(_currentUser!.role),
                  );
                }

                return Column(
                  children: users
                      .map(
                        (user) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _colorForRole(
                                user.role,
                              ).withValues(alpha: 0.12),
                              child: Icon(
                                _iconForRole(user.role),
                                color: _colorForRole(user.role),
                              ),
                            ),
                            title: Text(
                              user.fullName.isEmpty
                                  ? user.email
                                  : user.fullName,
                            ),
                            subtitle: Text(
                              '${user.role.displayName} • ${user.email}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _startConversation(user),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  String _emptyStateSubtitle(UserRole role) {
    switch (role) {
      case UserRole.traveler:
        return 'Traveler accounts can only start direct chat with guides.';
      case UserRole.guide:
        return 'Guide accounts can chat with travelers or admins.';
      case UserRole.admin:
        return 'Admin accounts can chat with guides or other admins.';
    }
  }

  Future<void> _startConversation(AppUser otherUser) async {
    final conversationId = await _chatService.createOrGetDirectConversation(
      currentUser: _currentUser!,
      otherUser: otherUser,
    );

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/chat-detail',
      arguments: {'conversationId': conversationId},
    );
  }

  Future<void> _openConversation(Conversation conversation) async {
    await _chatService.markConversationAsRead(
      conversationId: conversation.id,
      userId: _currentUser!.id,
    );

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/chat-detail',
      arguments: {'conversationId': conversation.id},
    );
  }

  static Color _colorForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.deepOrange;
      case UserRole.guide:
        return Colors.green;
      case UserRole.traveler:
        return AppColors.primary;
    }
  }

  static IconData _iconForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.guide:
        return Icons.hiking;
      case UserRole.traveler:
        return Icons.luggage;
    }
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  final Conversation conversation;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadFor(currentUserId);
    final name = conversation.getDisplayName(currentUserId);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name),
        subtitle: Text(
          conversation.lastMessage.isEmpty
              ? 'No messages yet'
              : conversation.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: unread > 0
            ? CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.accent,
                child: Text(
                  unread.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 36, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
