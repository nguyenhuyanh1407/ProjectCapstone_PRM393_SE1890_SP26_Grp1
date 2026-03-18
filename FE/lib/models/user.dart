// Enum cho vai trò người dùng
enum UserRole {
  admin,
  guide,
  traveler;

  // Chuyển từ String sang Enum
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'guide':
        return UserRole.guide;
      case 'traveler':
      default:
        return UserRole.traveler;
    }
  }

  // Chuyển từ Enum sang String (hiển thị đẹp)
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.guide:
        return 'Guide';
      case UserRole.traveler:
        return 'Traveler';
    }
  }
}

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String avatarUrl;
  final UserRole role;
  final String address;
  final DateTime createdAt;
  final bool isActive;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber = '',
    this.avatarUrl = '',
    this.role = UserRole.traveler,
    this.address = '',
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  // Tạo AppUser từ dữ liệu Firestore
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'traveler'),
      address: json['address'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  // Chuyển AppUser thành Map để lưu lên Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
