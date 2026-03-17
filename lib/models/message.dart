class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final bool isMine;
  final String type;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.sentAt,
    required this.isRead,
    required this.isMine,
    required this.type,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversationId'],
      senderId: json['senderId'],
      senderRole: json['senderRole'],
      content: json['content'],
      sentAt: DateTime.parse(json['sentAt']),
      isRead: json['isRead'],
      isMine: json['isMine'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderRole': senderRole,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'isMine': isMine,
      'type': type,
    };
  }
}
