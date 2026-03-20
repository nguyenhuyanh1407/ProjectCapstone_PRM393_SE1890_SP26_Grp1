import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/admin_stats.dart';
import '../../services/admin_service.dart';
import '../../widgets/floating_chat_button.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminService _adminService = AdminService();
  late Future<AdminStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _adminService.getAdminStats();
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = _adminService.getAdminStats();
    });
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Home',
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        ),
      ),
      floatingActionButton: const FloatingChatButton(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<AdminStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Failed to load dashboard: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }

            final stats = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
              children: [
                const Text(
                  'System overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      title: 'Total Tours',
                      value: stats.totalTours.toString(),
                      icon: Icons.map,
                      color: Colors.blueAccent,
                    ),
                    _StatCard(
                      title: 'Total users',
                      value: stats.totalUsers.toString(),
                      icon: Icons.groups,
                      color: AppColors.primary,
                    ),
                    _StatCard(
                      title: 'Active users',
                      value: stats.activeUsers.toString(),
                      icon: Icons.verified_user,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: 'Guides',
                      value: stats.totalGuides.toString(),
                      icon: Icons.hiking,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: 'Travelers',
                      value: stats.totalTravelers.toString(),
                      icon: Icons.luggage,
                      color: Colors.teal,
                    ),
                    _StatCard(
                      title: 'Conversations',
                      value: stats.totalConversations.toString(),
                      icon: Icons.forum,
                      color: Colors.deepPurple,
                    ),
                    _StatCard(
                      title: 'Messages',
                      value: stats.totalMessages.toString(),
                      icon: Icons.message,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Quick actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.map,
                  title: 'Manage tours',
                  subtitle: 'Add, edit, or delete tours on Firebase',
                  onTap: () => Navigator.pushNamed(context, '/manage-tours'),
                ),
                _ActionTile(
                  icon: Icons.manage_accounts,
                  title: 'Manage users',
                  subtitle: 'Update role and lock or unlock accounts',
                  onTap: () => Navigator.pushNamed(context, '/manage-users'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
