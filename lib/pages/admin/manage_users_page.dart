import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';
import '../../widgets/user_list_tile.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  bool _isLoading = true;
  String _selectedRole = 'All';

  final List<String> _roles = ['All', 'Admin', 'Guide', 'Traveler'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    List<User> users = await _adminService.getUsers();
    final keyword = _searchController.text.trim().toLowerCase();

    if (_selectedRole != 'All') {
      users = users.where((user) => user.role == _selectedRole).toList();
    }

    if (keyword.isNotEmpty) {
      users = users.where((user) {
        return user.name.toLowerCase().contains(keyword) ||
            user.email.toLowerCase().contains(keyword);
      }).toList();
    }

    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _toggleUserStatus(User user) async {
    await _adminService.toggleUserStatus(user.id);
    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _loadUsers(),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _roles.map((role) {
                      final isSelected = role == _selectedRole;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(role),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedRole = role);
                            _loadUsers();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                ..._users.map(
                  (user) => UserListTile(
                    user: user,
                    onToggleStatus: () => _toggleUserStatus(user),
                  ),
                ),
              ],
            ),
    );
  }
}
