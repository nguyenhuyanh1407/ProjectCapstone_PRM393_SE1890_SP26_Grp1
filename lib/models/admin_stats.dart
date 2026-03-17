class AdminStats {
  final int totalUsers;
  final int totalGuides;
  final int totalTravelers;
  final int totalConversations;
  final int totalMessages;
  final int pendingReports;

  AdminStats({
    required this.totalUsers,
    required this.totalGuides,
    required this.totalTravelers,
    required this.totalConversations,
    required this.totalMessages,
    required this.pendingReports,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'],
      totalGuides: json['totalGuides'],
      totalTravelers: json['totalTravelers'],
      totalConversations: json['totalConversations'],
      totalMessages: json['totalMessages'],
      pendingReports: json['pendingReports'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalGuides': totalGuides,
      'totalTravelers': totalTravelers,
      'totalConversations': totalConversations,
      'totalMessages': totalMessages,
      'pendingReports': pendingReports,
    };
  }
}
