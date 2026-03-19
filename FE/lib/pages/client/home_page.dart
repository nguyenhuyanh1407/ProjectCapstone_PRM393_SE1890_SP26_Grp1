import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/user.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/floating_chat_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _authService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currentUser = snapshot.data;
        final isAdmin = currentUser?.role == UserRole.admin;
        final isGuide = currentUser?.role == UserRole.guide;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              currentUser == null
                  ? 'Tour Booking App'
                  : 'Tour Booking App • ${currentUser.role.displayName}',
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  await _authService.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
          floatingActionButton: const FloatingChatButton(),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  currentUser == null
                      ? 'Dashboard'
                      : 'Hello ${currentUser.fullName.isEmpty ? currentUser.email : currentUser.fullName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildNavButton(
                  context,
                  'View Tour List',
                  Icons.explore,
                  AppRoutes.tourList,
                  Colors.blue,
                ),
                if (isGuide) ...[
                  const SizedBox(height: 15),
                  _buildNavButton(
                    context,
                    'Guide Dashboard',
                    Icons.badge_outlined,
                    AppRoutes.guideDashboard,
                    Colors.green,
                  ),
                ],
                if (isAdmin) ...[
                  const SizedBox(height: 15),
                  _buildNavButton(
                    context,
                    'Manage Tours',
                    Icons.admin_panel_settings,
                    AppRoutes.manageTours,
                    Colors.orange,
                  ),
                  const SizedBox(height: 15),
                  _buildNavButton(
                    context,
                    'Admin Dashboard',
                    Icons.analytics_outlined,
                    AppRoutes.adminDashboard,
                    Colors.deepPurple,
                  ),
                  const SizedBox(height: 15),
                  _buildNavButton(
                    context,
                    'Manage Users',
                    Icons.manage_accounts,
                    AppRoutes.manageUsers,
                    Colors.redAccent,
                  ),
                ],
                const SizedBox(height: 40),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      isAdmin
                          ? 'Admin routes are enabled for this account.'
                          : 'Admin routes are hidden for non-admin accounts.',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    String label,
    IconData icon,
    String route,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, route),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
