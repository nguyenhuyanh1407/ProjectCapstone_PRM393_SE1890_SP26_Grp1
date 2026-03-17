class User {
  final String id;
  final String name;
  final String email;
  final String role; // traveler, guide, admin
  final String avatarUrl;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl = '',
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      avatarUrl: json['avatarUrl'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
