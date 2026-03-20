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
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => _showRoleSelector(context),
            tooltip: 'Switch Role',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: AppColors.primary,
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.travel_explore, size: 60, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      'Tour Booking App',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Explore amazing destinations',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Client Section
            _buildSectionTitle('For Travelers'),
            const SizedBox(height: 10),
            
            _buildNavButton(
              context,
              'Browse Tours',
              Icons.explore,
              '/tour-list',
              Colors.blue,
            ),
            const SizedBox(height: 10),
            
            _buildNavButton(
              context,
              'Booking History & Reviews',
              Icons.rate_review,
              '/booking-history',
              Colors.green,
            ),
            const SizedBox(height: 10),
            
            _buildNavButton(
              context,
              'My Profile',
              Icons.person,
              '/profile',
              Colors.teal,
            ),
            
            const SizedBox(height: 20),
            
            // Guide Section
            _buildSectionTitle('For Guides'),
            const SizedBox(height: 10),
            
            _buildNavButton(
              context,
              'Guide Dashboard',
              Icons.dashboard,
              '/guide-dashboard',
              Colors.orange,
            ),
            const SizedBox(height: 10),
            
            _buildNavButton(
              context,
              'Tour Schedule',
              Icons.calendar_today,
              '/tour-schedule',
              Colors.deepOrange,
            ),
            
            const SizedBox(height: 20),
            
            // Admin Section
            _buildSectionTitle('For Admin'),
            const SizedBox(height: 10),
            
            _buildNavButton(
              context,
              'Admin Dashboard',
              Icons.admin_panel_settings,
              '/admin-dashboard',
              Colors.purple,
            ),
            const SizedBox(height: 10),
            
            _buildNavButton(
              context,
              'Manage Tours',
              Icons.flight_takeoff,
              '/manage-tours',
              Colors.indigo,
            ),
            const SizedBox(height: 10),
            
            _buildNavButton(
              context,
              'Manage Reviews',
              Icons.star_rate,
              '/manage-reviews',
              Colors.pink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String label, IconData icon, String route, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoleSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Quick Navigation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.explore, color: Colors.blue),
              title: const Text('Browse Tours'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tour-list');
              },
            ),
            ListTile(
              leading: const Icon(Icons.rate_review, color: Colors.green),
              title: const Text('Booking History & Reviews'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/booking-history');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin-dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_rate, color: Colors.pink),
              title: const Text('Manage Reviews'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/manage-reviews');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

