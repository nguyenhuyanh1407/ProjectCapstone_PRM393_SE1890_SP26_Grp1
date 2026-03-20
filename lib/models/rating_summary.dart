class RatingSummary {
  final String tourId;
  final double averageRating;
  final int totalReviews;
  final Map<String, int> ratingDistribution;

  RatingSummary({
    required this.tourId,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    Map<String, int>? ratingDistribution,
  }) : ratingDistribution = ratingDistribution ?? {
          '1': 0,
          '2': 0,
          '3': 0,
          '4': 0,
          '5': 0,
        };

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    Map<String, int> distribution = {};
    if (json['ratingDistribution'] != null) {
      json['ratingDistribution'].forEach((key, value) {
        distribution[key.toString()] = value as int;
      });
    }
    // Ensure all keys exist
    for (var i = 1; i <= 5; i++) {
      distribution.putIfAbsent(i.toString(), () => 0);
    }

    return RatingSummary(
      tourId: json['tourId'] ?? '',
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: distribution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tourId': tourId,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
    };
  }

  RatingSummary copyWith({
    String? tourId,
    double? averageRating,
    int? totalReviews,
    Map<String, int>? ratingDistribution,
  }) {
    return RatingSummary(
      tourId: tourId ?? this.tourId,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
    );
  }
}