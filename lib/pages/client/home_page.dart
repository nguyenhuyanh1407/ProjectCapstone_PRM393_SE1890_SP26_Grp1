import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Booking App'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Testing Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            _buildNavButton(
              context,
              'View Tour List (Client)',
              Icons.explore,
              AppRoutes.tourList,
              Colors.blue,
            ),
            const SizedBox(height: 15),
            
            _buildNavButton(
              context,
              'Manage Tours (Admin)',
              Icons.admin_panel_settings,
              AppRoutes.manageTours,
              Colors.orange,
            ),
            const SizedBox(height: 15),

            _buildNavButton(
              context,
              'Chat Demo',
              Icons.chat_bubble_outline,
              AppRoutes.conversations,
              Colors.teal,
            ),
            const SizedBox(height: 15),

            _buildNavButton(
              context,
              'Admin Dashboard',
              Icons.dashboard_customize_outlined,
              AppRoutes.adminDashboard,
              Colors.indigo,
            ),
            const SizedBox(height: 15),

            _buildNavButton(
              context,
              'Manage Users',
              Icons.manage_accounts_outlined,
              AppRoutes.manageUsers,
              Colors.deepPurple,
            ),
            const SizedBox(height: 15),

            _buildNavButton(
              context,
              'Manage Reports',
              Icons.flag_outlined,
              AppRoutes.reportManagement,
              Colors.redAccent,
            ),
            
            const SizedBox(height: 40),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Demo pages in this app use local mock data only. Chat messages, user status updates and report status updates are stored in memory for the current session.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String label, IconData icon, String route, Color color) {
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

