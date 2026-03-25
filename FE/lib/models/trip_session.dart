class TripSession {
  final String id;
  final String tourId;
  final DateTime date;
  final String type; // "private" or "group"
  final String createdByUserId;
  final int maxSlots;
  final int bookedSlots;
  final String status; // "Open" or "Closed"

  TripSession({
    required this.id,
    required this.tourId,
    required this.date,
    required this.type,
    required this.createdByUserId,
    required this.maxSlots,
    this.bookedSlots = 0,
    this.status = 'Open',
  });

  int get remainingSlots => maxSlots - bookedSlots;

  factory TripSession.fromJson(Map<String, dynamic> json) {
    return TripSession(
      id: json['id'] ?? '',
      tourId: json['tourId'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      type: json['type'] ?? 'group',
      createdByUserId: json['createdByUserId'] ?? '',
      maxSlots: json['maxSlots'] ?? 0,
      bookedSlots: json['bookedSlots'] ?? 0,
      status: json['status'] ?? 'Open',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tourId': tourId,
      'date': date.toIso8601String(),
      'type': type,
      'createdByUserId': createdByUserId,
      'maxSlots': maxSlots,
      'bookedSlots': bookedSlots,
      'status': status,
    };
  }
}
