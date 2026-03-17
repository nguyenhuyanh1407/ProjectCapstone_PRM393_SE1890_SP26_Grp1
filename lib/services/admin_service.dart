import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/admin_stats.dart';
import '../models/user.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  List<User> _users = [];
  AdminStats? _stats;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final usersResponse = await rootBundle.loadString('assets/data/users.json');
    final statsResponse = await rootBundle.loadString('assets/data/admin_stats.json');

    final usersData = json.decode(usersResponse) as List;
    final statsData = json.decode(statsResponse) as Map<String, dynamic>;

    _users = usersData.map((json) => User.fromJson(json)).toList();
    _stats = AdminStats.fromJson(statsData);
    _isInitialized = true;
  }

  Future<AdminStats> getAdminStats() async {
    await init();
    return _buildStats();
  }

  Future<List<User>> getUsers() async {
    await init();
    return List<User>.from(_users);
  }

  Future<List<User>> searchUsers(String keyword) async {
    await init();
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) return getUsers();

    return _users.where((user) {
      return user.name.toLowerCase().contains(normalized) ||
          user.email.toLowerCase().contains(normalized);
    }).toList();
  }

  Future<List<User>> filterUsersByRole(String role) async {
    await init();
    if (role == 'All') return getUsers();
    return _users.where((user) => user.role == role).toList();
  }

  Future<void> toggleUserStatus(String userId) async {
    await init();
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) return;
    final user = _users[index];
    _users[index] = user.copyWith(isActive: !user.isActive);
  }

  AdminStats _buildStats() {
    final totalGuides = _users.where((user) => user.role == 'Guide').length;
    final totalTravelers = _users.where((user) => user.role == 'Traveler').length;

    return AdminStats(
      totalUsers: _users.length,
      totalGuides: totalGuides,
      totalTravelers: totalTravelers,
      totalConversations: _stats?.totalConversations ?? 0,
      totalMessages: _stats?.totalMessages ?? 0,
      pendingReports: _stats?.pendingReports ?? 0,
    );
  }
}
