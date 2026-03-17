import 'package:flutter/material.dart';

import '../models/user.dart';

class UserListTile extends StatelessWidget {
  final User user;
  final VoidCallback onToggleStatus;

  const UserListTile({
    super.key,
    required this.user,
    required this.onToggleStatus,
  });

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.deepPurple;
      case 'Guide':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
          child: user.avatarUrl.isEmpty ? Text(user.name.substring(0, 1)) : null,
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user.isActive ? 'Active' : 'Blocked',
                    style: TextStyle(
                      color: user.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: FilledButton.tonal(
          onPressed: onToggleStatus,
          child: Text(user.isActive ? 'Block' : 'Activate'),
        ),
      ),
    );
  }
}
