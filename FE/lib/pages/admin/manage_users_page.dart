import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: adminService.streamUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? const [];
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: Text(
                              user.fullName.isEmpty
                                  ? '?'
                                  : user.fullName[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName.isEmpty
                                      ? user.email
                                      : user.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(user.email),
                              ],
                            ),
                          ),
                          Switch(
                            value: user.isActive,
                            onChanged: (value) async {
                              await adminService.updateUserStatus(
                                userId: user.id,
                                isActive: value,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _InfoChip(
                            icon: Icons.badge_outlined,
                            label: user.role.displayName,
                          ),
                          _InfoChip(
                            icon: user.isActive
                                ? Icons.check_circle
                                : Icons.block,
                            label: user.isActive ? 'Active' : 'Blocked',
                          ),
                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<UserRole>(
                              initialValue: user.role,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: UserRole.values
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role.displayName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (role) async {
                                if (role == null || role == user.role) return;
                                await adminService.updateUserRole(
                                  userId: user.id,
                                  role: role,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 10),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}
