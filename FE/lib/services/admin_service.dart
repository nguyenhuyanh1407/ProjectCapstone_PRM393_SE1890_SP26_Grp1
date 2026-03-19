import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_stats.dart';
import '../models/user.dart';

class AdminService {
  AdminService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AppUser>> streamUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList(),
        );
  }

  Stream<List<AppUser>> streamUsersByRole(UserRole role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role.name)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList(),
        );
  }

  Future<void> updateUserRole({
    required String userId,
    required UserRole role,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'role': role.name,
    });
  }

  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
    });
  }

  Future<AdminStats> getAdminStats() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final conversationsSnapshot = await _firestore
        .collection('conversations')
        .get();

    var totalGuides = 0;
    var totalTravelers = 0;
    var activeUsers = 0;

    for (final doc in usersSnapshot.docs) {
      final user = AppUser.fromJson(doc.data());
      if (user.role == UserRole.guide) totalGuides++;
      if (user.role == UserRole.traveler) totalTravelers++;
      if (user.isActive) activeUsers++;
    }

    var totalMessages = 0;
    for (final conversation in conversationsSnapshot.docs) {
      final messagesSnapshot = await conversation.reference
          .collection('messages')
          .get();
      totalMessages += messagesSnapshot.size;
    }

    return AdminStats(
      totalUsers: usersSnapshot.size,
      totalGuides: totalGuides,
      totalTravelers: totalTravelers,
      activeUsers: activeUsers,
      totalConversations: conversationsSnapshot.size,
      totalMessages: totalMessages,
    );
  }
}
