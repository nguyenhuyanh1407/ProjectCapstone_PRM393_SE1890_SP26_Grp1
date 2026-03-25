import 'itinerary.dart';

class Tour {
  final String id;
  final String? guideId;
  final String title;
  final String description;
  final String location;
  final double basePrice;
  final int maxParticipants;
  final String tourType;
  final int durationDays;
  final String status;
  final DateTime createdAt;
  final List<TourImage> images;
  final List<Itinerary>? itinerary;
  final List<TourReview> reviews;

  Tour({
    required this.id,
    this.guideId,
    required this.title,
    required this.description,
    required this.location,
    required this.basePrice,
    required this.maxParticipants,
    required this.tourType,
    required this.durationDays,
    required this.status,
    required this.createdAt,
    required this.images,
    this.itinerary,
    this.reviews = const [],
  });

  double get averageRating {
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  }

  factory Tour.fromJson(Map<String, dynamic> json) {
    return Tour(
      id: json['id']?.toString() ?? '',
      guideId: json['guideId']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      basePrice: double.tryParse(json['basePrice']?.toString() ?? '0') ?? 0.0,
      maxParticipants:
          int.tryParse(json['maxParticipants']?.toString() ?? '0') ?? 0,
      tourType: json['tourType']?.toString() ?? '',
      durationDays:
          int.tryParse(json['durationDays']?.toString() ?? '0') ?? 1,
      status: json['status']?.toString() ?? 'Draft',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      images: (json['images'] as List? ?? [])
          .map((i) => TourImage.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      itinerary: (json['itinerary'] as List? ?? [])
          .map((i) => Itinerary.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      reviews: (json['reviews'] as List? ?? [])
          .map((r) => TourReview.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guideId': guideId,
      'title': title,
      'description': description,
      'location': location,
      'basePrice': basePrice,
      'maxParticipants': maxParticipants,
      'tourType': tourType,
      'durationDays': durationDays,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'images': images.map((i) => i.toJson()).toList(),
      'itinerary': itinerary?.map((i) => i.toJson()).toList(),
      'reviews': reviews.map((r) => r.toJson()).toList(),
    };
  }
}

class TourImage {
  final String url;
  final bool isPrimary;

  TourImage({required this.url, required this.isPrimary});

  factory TourImage.fromJson(Map<String, dynamic> json) {
    return TourImage(
      url: json['url']?.toString() ?? '',
      isPrimary: json['isPrimary'] == true,
    );
  }

  Map<String, dynamic> toJson() => {'url': url, 'isPrimary': isPrimary};
}

class TourReview {
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  TourReview({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory TourReview.fromJson(Map<String, dynamic> json) {
    return TourReview(
      userName: json['userName']?.toString() ?? 'Anonymous',
      rating: int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };
}
