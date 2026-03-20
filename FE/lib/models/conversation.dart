import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderId;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.lastMessage = '',
    this.lastMessageAt,
    this.lastSenderId = '',
    this.unreadCounts = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Conversation.fromJson(Map<String, dynamic> json, String documentId) {
    return Conversation(
      id: documentId,
      participantIds: List<String>.from(json['participantIds'] ?? const []),
      participantNames: Map<String, String>.from(
        json['participantNames'] ?? const {},
      ),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: _parseDateTime(json['lastMessageAt']),
      lastSenderId: json['lastSenderId'] ?? '',
      unreadCounts: _parseUnreadCounts(json['unreadCounts']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastSenderId': lastSenderId,
      'unreadCounts': unreadCounts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String getDisplayName(String currentUserId) {
    for (final participantId in participantIds) {
      if (participantId != currentUserId) {
        return participantNames[participantId] ?? 'Unknown user';
      }
    }
    return 'Personal chat';
  }

  int unreadFor(String userId) => unreadCounts[userId] ?? 0;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static Map<String, int> _parseUnreadCounts(dynamic value) {
    if (value is! Map) return {};
    return value.map(
      (key, unreadCount) =>
          MapEntry(key.toString(), (unreadCount as num?)?.toInt() ?? 0),
    );
  }
}
