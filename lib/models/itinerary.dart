import 'activity.dart';

class Itinerary {
  final int? id;
  final int dayNumber;
  final String title;
  final String description;
  final List<Activity> activities;

  Itinerary({
    this.id,
    required this.dayNumber,
    required this.title,
    required this.description,
    required this.activities,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      dayNumber: json['dayNumber'],
      title: json['title'],
      description: json['description'] ?? '',
      activities: (json['activities'] as List? ?? [])
          .map((a) => Activity.fromJson(a))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayNumber': dayNumber,
      'title': title,
      'description': description,
      'activities': activities.map((a) => a.toJson()).toList(),
    };
  }
}
