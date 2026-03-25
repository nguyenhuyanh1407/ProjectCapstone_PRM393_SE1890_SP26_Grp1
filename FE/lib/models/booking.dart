class Booking {
  final String id;
  final String tourId;
  final String userId;
  final DateTime bookingDate;
  final String status;
  final int participants;
  final double totalPrice;
  final int? paymentOrderCode;
  final String bookingType; // "private" or "group"
  final String? tripSessionId;

  Booking({
    required this.id,
    required this.tourId,
    required this.userId,
    required this.bookingDate,
    required this.status,
    this.participants = 1,
    this.totalPrice = 0,
    this.paymentOrderCode,
    this.bookingType = 'private',
    this.tripSessionId,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      tourId: json['tourId'] ?? '',
      userId: json['userId'] ?? '',
      bookingDate: json['bookingDate'] != null
          ? DateTime.parse(json['bookingDate'])
          : DateTime.now(),
      status: json['status'] ?? 'Pending',
      participants: json['participants'] ?? 1,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      paymentOrderCode: json['paymentOrderCode'],
      bookingType: json['bookingType'] ?? 'private',
      tripSessionId: json['tripSessionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tourId': tourId,
      'userId': userId,
      'bookingDate': bookingDate.toIso8601String(),
      'status': status,
      'participants': participants,
      'totalPrice': totalPrice,
      'paymentOrderCode': paymentOrderCode,
      'bookingType': bookingType,
      'tripSessionId': tripSessionId,
    };
  }

  Booking copyWith({
    String? id,
    String? tourId,
    String? userId,
    DateTime? bookingDate,
    String? status,
    int? participants,
    double? totalPrice,
    int? paymentOrderCode,
    String? bookingType,
    String? tripSessionId,
  }) {
    return Booking(
      id: id ?? this.id,
      tourId: tourId ?? this.tourId,
      userId: userId ?? this.userId,
      bookingDate: bookingDate ?? this.bookingDate,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentOrderCode: paymentOrderCode ?? this.paymentOrderCode,
      bookingType: bookingType ?? this.bookingType,
      tripSessionId: tripSessionId ?? this.tripSessionId,
    );
  }
}
