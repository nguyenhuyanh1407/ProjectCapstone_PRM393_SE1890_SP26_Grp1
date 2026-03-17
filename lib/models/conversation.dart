class Conversation {
  final String id;
  final String travelerId;
  final String guideId;
  final String travelerName;
  final String guideName;
  final String travelerAvatar;
  final String guideAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.travelerId,
    required this.guideId,
    required this.travelerName,
    required this.guideName,
    required this.travelerAvatar,
    required this.guideAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      travelerId: json['travelerId'],
      guideId: json['guideId'],
      travelerName: json['travelerName'],
      guideName: json['guideName'],
      travelerAvatar: json['travelerAvatar'],
      guideAvatar: json['guideAvatar'],
      lastMessage: json['lastMessage'],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: json['unreadCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'travelerId': travelerId,
      'guideId': guideId,
      'travelerName': travelerName,
      'guideName': guideName,
      'travelerAvatar': travelerAvatar,
      'guideAvatar': guideAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return Conversation(
      id: id,
      travelerId: travelerId,
      guideId: guideId,
      travelerName: travelerName,
      guideName: guideName,
      travelerAvatar: travelerAvatar,
      guideAvatar: guideAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
