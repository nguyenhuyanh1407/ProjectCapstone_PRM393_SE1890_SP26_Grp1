import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/conversation.dart';
import '../models/message.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final conversationsResponse = await rootBundle.loadString('assets/data/conversations.json');
    final messagesResponse = await rootBundle.loadString('assets/data/messages.json');

    final conversationsData = json.decode(conversationsResponse) as List;
    final messagesData = json.decode(messagesResponse) as List;

    _conversations = conversationsData.map((json) => Conversation.fromJson(json)).toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    _messages = messagesData.map((json) => Message.fromJson(json)).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    _isInitialized = true;
  }

  Future<List<Conversation>> getConversations() async {
    await init();
    return List<Conversation>.from(_conversations);
  }

  Future<List<Message>> getMessagesByConversation(String conversationId) async {
    await init();
    return _messages
        .where((message) => message.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  Future<Message> sendMessage(String conversationId, Message message) async {
    await init();
    _messages.add(message);

    final index = _conversations.indexWhere((conversation) => conversation.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: message.content,
        lastMessageTime: message.sentAt,
        unreadCount: 0,
      );
      _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    }

    return message;
  }
}
