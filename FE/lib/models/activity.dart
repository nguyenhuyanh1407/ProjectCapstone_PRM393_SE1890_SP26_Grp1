class Activity {
  final int? id;
  final String startTime;
  final String endTime;
  final String name;
  final String location;

  Activity({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.name,
    required this.location,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      name: json['name'],
      location: json['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'name': name,
      'location': location,
    };
  }
}
