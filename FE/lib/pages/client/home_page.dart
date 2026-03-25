import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  void _showUserMenu(AppUser? currentUser) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        backgroundImage:
                            (currentUser?.avatarUrl ?? '').isNotEmpty
                                ? NetworkImage(currentUser!.avatarUrl)
                                : null,
                        child: (currentUser?.avatarUrl ?? '').isEmpty
                            ? Text(
                                _getInitials(currentUser?.fullName ?? ''),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.fullName ?? 'User',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentUser?.email ?? '',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.profile);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.favorite_outline,
                  title: 'Favorite Tours',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.tourList);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.history,
                  title: 'Booking History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.bookingHistory);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {
                    Navigator.pop(context);
                    _showChangePasswordDialog();
                  },
                ),
                const Divider(),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  color: Colors.red,
                  onTap: () async {
                    Navigator.pop(context);
                    await _authService.logout();
                    if (mounted) {
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
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(title,
          style: TextStyle(
              fontSize: 16,
              color: color ?? Colors.black87,
              fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog() {
    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPwCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12))),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPwCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_reset),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12))),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPwCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_reset),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12))),
                  validator: (v) {
                    if (v != newPwCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final cred = EmailAuthProvider.credential(
                      email: user.email!, password: currentPwCtrl.text);
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPwCtrl.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                          content: Text('Password changed successfully!'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _authService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final currentUser = snapshot.data;
        final isAdmin = currentUser?.role == UserRole.admin;
        final isGuide = currentUser?.role == UserRole.guide;
        final firstName = (currentUser?.fullName ?? 'Traveler').split(' ').first;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          floatingActionButton: const FloatingChatButton(),
          body: CustomScrollView(
            slivers: [
              // ===== HEADER =====
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top bar: logo + avatar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.flight_takeoff,
                                      color: Colors.white, size: 28),
                                  SizedBox(width: 8),
                                  Text(
                                    'TripTour',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => _showUserMenu(currentUser),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white54, width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.white24,
                                    backgroundImage:
                                        (currentUser?.avatarUrl ?? '')
                                                .isNotEmpty
                                            ? NetworkImage(
                                                currentUser!.avatarUrl)
                                            : null,
                                    child: (currentUser?.avatarUrl ?? '')
                                            .isEmpty
                                        ? Text(
                                            _getInitials(
                                                currentUser?.fullName ?? ''),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Greeting
                          Text(
                            'Hello, $firstName! \u{1F44B}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Where do you want to go today?',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ===== BODY =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Explore card
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.tourList),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E88E5)
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Explore Tours',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Discover amazing destinations\nacross Vietnam',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(25),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'View All Tours',
                                            style: TextStyle(
                                              color: Color(0xFF1E88E5),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_rounded,
                                              color: Color(0xFF1E88E5),
                                              size: 18),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.explore,
                                    color: Colors.white, size: 40),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildQuickAction(
                            icon: Icons.history,
                            label: 'Bookings',
                            color: const Color(0xFFFF7043),
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.bookingHistory),
                          ),
                          const SizedBox(width: 12),
                          _buildQuickAction(
                            icon: Icons.person_outline,
                            label: 'Profile',
                            color: const Color(0xFF66BB6A),
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.profile),
                          ),
                          const SizedBox(width: 12),
                          _buildQuickAction(
                            icon: Icons.favorite_outline,
                            label: 'Favorites',
                            color: const Color(0xFFEF5350),
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.tourList),
                          ),
                        ],
                      ),

                      // Admin / Guide section
                      if (isAdmin || isGuide) ...[
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.admin_panel_settings,
                                      color: AppColors.primary, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAdmin
                                        ? 'Admin Panel'
                                        : 'Guide Panel',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (isGuide)
                                _buildPanelTile(
                                  icon: Icons.badge_outlined,
                                  title: 'Guide Dashboard',
                                  subtitle: 'Manage your tours & schedule',
                                  color: Colors.green,
                                  onTap: () => Navigator.pushNamed(
                                      context, AppRoutes.guideDashboard),
                                ),
                              if (isAdmin) ...[
                                _buildPanelTile(
                                  icon: Icons.analytics_outlined,
                                  title: 'Admin Dashboard',
                                  subtitle: 'View stats & analytics',
                                  color: Colors.deepPurple,
                                  onTap: () => Navigator.pushNamed(
                                      context, AppRoutes.adminDashboard),
                                ),
                                _buildPanelTile(
                                  icon: Icons.tour_outlined,
                                  title: 'Manage Tours',
                                  subtitle: 'Create, edit & delete tours',
                                  color: Colors.orange,
                                  onTap: () => Navigator.pushNamed(
                                      context, AppRoutes.manageTours),
                                ),
                                _buildPanelTile(
                                  icon: Icons.manage_accounts,
                                  title: 'Manage Users',
                                  subtitle: 'View & manage user accounts',
                                  color: Colors.redAccent,
                                  onTap: () => Navigator.pushNamed(
                                      context, AppRoutes.manageUsers),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // About section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.flight_takeoff,
                                    color: Color(0xFF1565C0), size: 28),
                                SizedBox(width: 8),
                                Text(
                                  'TripTour',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Your trusted companion for discovering the beauty of Vietnam. '
                              'Book tours, explore destinations, and create unforgettable memories.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildInfoChip(Icons.verified, 'Trusted'),
                                const SizedBox(width: 8),
                                _buildInfoChip(
                                    Icons.support_agent, '24/7 Support'),
                                const SizedBox(width: 8),
                                _buildInfoChip(Icons.payments, 'Secure Pay'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle:
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing:
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
      onTap: onTap,
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1565C0)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
