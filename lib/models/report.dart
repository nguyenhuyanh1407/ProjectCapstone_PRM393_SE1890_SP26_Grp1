class Report {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reporterName;
  final String reportedUserName;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String messagePreview;

  Report({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reporterName,
    required this.reportedUserName,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.messagePreview,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      reporterId: json['reporterId'],
      reportedUserId: json['reportedUserId'],
      reporterName: json['reporterName'],
      reportedUserName: json['reportedUserName'],
      reason: json['reason'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      messagePreview: json['messagePreview'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reporterName': reporterName,
      'reportedUserName': reportedUserName,
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'messagePreview': messagePreview,
    };
  }

  Report copyWith({String? status}) {
    return Report(
      id: id,
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      reporterName: reporterName,
      reportedUserName: reportedUserName,
      reason: reason,
      status: status ?? this.status,
      createdAt: createdAt,
      messagePreview: messagePreview,
    );
  }
}
