import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/user.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversationCollection =>
      _firestore.collection('conversations');

  Stream<List<Conversation>> getConversationsForUser(String userId) {
    return _conversationCollection
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Conversation.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _conversationCollection
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  bool canStartDirectConversation({
    required UserRole currentUserRole,
    required UserRole otherUserRole,
  }) {
    if (currentUserRole == UserRole.traveler &&
        otherUserRole == UserRole.admin) {
      return false;
    }

    if (currentUserRole == UserRole.traveler) {
      return otherUserRole == UserRole.guide;
    }

    if (currentUserRole == UserRole.guide) {
      return otherUserRole == UserRole.traveler ||
          otherUserRole == UserRole.admin;
    }

    if (currentUserRole == UserRole.admin) {
      return otherUserRole != UserRole.traveler;
    }

    return false;
  }

  Future<String> createOrGetDirectConversation({
    required AppUser currentUser,
    required AppUser otherUser,
  }) async {
    if (!canStartDirectConversation(
      currentUserRole: currentUser.role,
      otherUserRole: otherUser.role,
    )) {
      throw Exception('This user role is not allowed for direct chat.');
    }

    final participantIds = [currentUser.id, otherUser.id]..sort();

    final existing = await _conversationCollection
        .where('participantIds', isEqualTo: participantIds)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final now = DateTime.now();
    final data = Conversation(
      id: '',
      participantIds: participantIds,
      participantNames: {
        currentUser.id: currentUser.fullName,
        otherUser.id: otherUser.fullName,
      },
      unreadCounts: {currentUser.id: 0, otherUser.id: 0},
      createdAt: now,
      updatedAt: now,
    ).toJson();

    final docRef = await _conversationCollection.add(data);
    return docRef.id;
  }

  Future<void> sendMessage({
    required Conversation conversation,
    required AppUser sender,
    required String content,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return;

    final message = ChatMessage(
      id: '',
      conversationId: conversation.id,
      senderId: sender.id,
      senderName: sender.fullName,
      content: trimmedContent,
      createdAt: DateTime.now(),
    );

    final unreadCounts = <String, int>{...conversation.unreadCounts};
    for (final participantId in conversation.participantIds) {
      if (participantId == sender.id) {
        unreadCounts[participantId] = 0;
      } else {
        unreadCounts[participantId] = (unreadCounts[participantId] ?? 0) + 1;
      }
    }

    await _conversationCollection
        .doc(conversation.id)
        .collection('messages')
        .add(message.toJson());
    await _conversationCollection.doc(conversation.id).update({
      'lastMessage': trimmedContent,
      'lastSenderId': sender.id,
      'lastMessageAt': message.createdAt.toIso8601String(),
      'updatedAt': message.createdAt.toIso8601String(),
      'unreadCounts': unreadCounts,
      'participantNames.${sender.id}': sender.fullName,
    });
  }

  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await _conversationCollection.doc(conversationId).update({
      'unreadCounts.$userId': 0,
    });
  }
}
