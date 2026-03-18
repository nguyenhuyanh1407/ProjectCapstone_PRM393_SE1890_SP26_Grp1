class Booking {
  final String id;
  final String tourId;
  final String userId;
  final DateTime bookingDate;
  final String status;

  Booking({
    required this.id,
    required this.tourId,
    required this.userId,
    required this.bookingDate,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      tourId: json['tourId'],
      userId: json['userId'],
      bookingDate: DateTime.parse(json['bookingDate']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tourId': tourId,
      'userId': userId,
      'bookingDate': bookingDate.toIso8601String(),
      'status': status,
    };
  }
}
