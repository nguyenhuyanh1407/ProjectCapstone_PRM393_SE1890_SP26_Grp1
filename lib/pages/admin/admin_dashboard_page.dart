import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/admin_stats.dart';
import '../../services/admin_service.dart';
import '../../widgets/stats_card.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<AdminStats>(
        future: AdminService().getAdminStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF4FC3F7)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'All values are loaded from local mock data for frontend demo.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.45,
                    children: [
                      StatsCard(
                        label: 'Total Users',
                        value: '${stats.totalUsers}',
                        icon: Icons.people_alt_rounded,
                        color: Colors.blue,
                      ),
                      StatsCard(
                        label: 'Guides',
                        value: '${stats.totalGuides}',
                        icon: Icons.badge_rounded,
                        color: Colors.teal,
                      ),
                      StatsCard(
                        label: 'Travelers',
                        value: '${stats.totalTravelers}',
                        icon: Icons.luggage_rounded,
                        color: Colors.indigo,
                      ),
                      StatsCard(
                        label: 'Conversations',
                        value: '${stats.totalConversations}',
                        icon: Icons.forum_rounded,
                        color: Colors.orange,
                      ),
                      StatsCard(
                        label: 'Messages',
                        value: '${stats.totalMessages}',
                        icon: Icons.mark_chat_read_rounded,
                        color: Colors.green,
                      ),
                      StatsCard(
                        label: 'Pending Reports',
                        value: '${stats.pendingReports}',
                        icon: Icons.report_problem_rounded,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Use the dedicated pages to demo user management and report moderation. The dashboard is intentionally read-only because this module is frontend-only.',
                        style: TextStyle(height: 1.5),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
