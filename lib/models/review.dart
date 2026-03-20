import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String bookingId;
  final String userId;
  final String tourId;
  final int rating;
  final String comment;
  final List<String> reviewImages;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.tourId,
    required this.rating,
    required this.comment,
    this.reviewImages = const [],
    this.status = 'Pending',
    this.adminNote,
    required this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      userId: json['userId'] ?? '',
      tourId: json['tourId'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
      reviewImages: json['reviewImages'] != null
          ? List<String>.from(json['reviewImages'])
          : [],
      status: json['status'] ?? 'Pending',
      adminNote: json['adminNote'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt']))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'tourId': tourId,
      'rating': rating,
      'comment': comment,
      'reviewImages': reviewImages,
      'status': status,
      'adminNote': adminNote,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Review copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? tourId,
    int? rating,
    String? comment,
    List<String>? reviewImages,
    String? status,
    String? adminNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      tourId: tourId ?? this.tourId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      reviewImages: reviewImages ?? this.reviewImages,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}