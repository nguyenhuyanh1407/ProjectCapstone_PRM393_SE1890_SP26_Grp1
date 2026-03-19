import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await AuthService().logout();
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
              '/tour-list',
              Colors.blue,
            ),
            const SizedBox(height: 15),
            
            _buildNavButton(
              context,
              'Manage Tours (Admin)',
              Icons.admin_panel_settings,
              '/manage-tours',
              Colors.orange,
            ),
            
            const SizedBox(height: 40),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Note: You can also test by adding /#/tour-list or /#/manage-tours to the URL in your browser.',
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

