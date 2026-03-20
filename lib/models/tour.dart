import 'itinerary.dart';

class Tour {
  final String id;
  final String? guideId;
  final String title;
  final String description;
  final String location; // Province/City
  final double basePrice;
  final int maxParticipants;
  final String tourType; // Group, Family, Private
  final int durationDays;
  final String status; // Draft, Pending, Published, Hidden
  final DateTime createdAt;
  final List<TourImage> images;
  final List<Itinerary>? itinerary;

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
  });

  factory Tour.fromJson(Map<String, dynamic> json) {
    return Tour(
      id: json['id'],
      guideId: json['guideId'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      basePrice: (json['basePrice'] as num).toDouble(),
      maxParticipants: json['maxParticipants'],
      tourType: json['tourType'],
      durationDays: json['durationDays'],
      status: json['status'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      images: (json['images'] as List? ?? [])
          .map((i) => TourImage.fromJson(i))
          .toList(),
      itinerary: (json['itinerary'] as List? ?? [])
          .map((i) => Itinerary.fromJson(i))
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
    };
  }
}

class TourImage {
  final String url;
  final bool isPrimary;

  TourImage({required this.url, required this.isPrimary});

  factory TourImage.fromJson(Map<String, dynamic> json) {
    return TourImage(
      url: json['url'],
      isPrimary: json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'url': url, 'isPrimary': isPrimary};
}
