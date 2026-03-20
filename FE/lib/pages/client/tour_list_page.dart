import 'package:flutter/material.dart';
import '../../models/tour.dart';
import '../../models/user.dart';
import '../../services/tour_service.dart';
import '../../services/auth_service.dart';

import '../../widgets/tour_card.dart';
import '../../constants/app_colors.dart';

class TourListPage extends StatefulWidget {
  const TourListPage({super.key});

  @override
  State<TourListPage> createState() => _TourListPageState();
}

class _TourListPageState extends State<TourListPage> {
  final TourService _dataService = TourService();
  final AuthService _authService = AuthService();
  List<Tour> _tours = [];
  String _searchQuery = '';
  String _selectedProvince = 'All';
  String _selectedType = 'All';
  
  int _currentPage = 1;
  final int _pageSize = 2; // Thử nghiệm với 2 mục/trang

  final List<String> _provinces = ['All', 'Quảng Ninh', 'Lâm Đồng', 'Kiên Giang'];
  final List<String> _types = ['All', 'Group', 'Family', 'Private'];

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    final tours = await _dataService.filterTours(
      province: _selectedProvince,
      type: _selectedType,
    );
    setState(() {
      _currentPage = 1; // Reset lại trang khi đổi filter/search
      _tours = tours.where((t) => 
        t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.location.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Destinations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Dashboard',
            onPressed: () async {
              final user = await _authService.getCurrentUserData();
              if (context.mounted) {
                if (user?.role == UserRole.admin) {
                  Navigator.pushNamed(context, '/admin-dashboard');
                } else if (user?.role == UserRole.guide) {
                  Navigator.pushNamed(context, '/guide-dashboard');
                } else {
                  Navigator.pushNamed(context, '/profile');
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/login', 
                  (route) => false
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _loadTours();
              },
              decoration: InputDecoration(
                hintText: 'Search by title or location...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Province', _provinces, _selectedProvince, (val) {
                  setState(() => _selectedProvince = val!);
                  _loadTours();
                }),
                _buildFilterChip('Type', _types, _selectedType, (val) {
                  setState(() => _selectedType = val!);
                  _loadTours();
                }),
              ],
            ),
          ),
          Expanded(
            child: _tours.isEmpty 
              ? const Center(child: Text('No tours found.'))
              : () {
                  final startIndex = (_currentPage - 1) * _pageSize;
                  final endIndex = startIndex + _pageSize > _tours.length 
                      ? _tours.length 
                      : startIndex + _pageSize;
                  
                  final paginatedTours = _tours.sublist(startIndex, endIndex);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 50, left: 12, right: 12, top: 12),
                          itemCount: paginatedTours.length,
                          itemBuilder: (context, index) {
                            final tour = paginatedTours[index];
                            return GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context, 
                                '/tour-detail', 
                                arguments: tour.id
                              ),
                              child: TourCard(
                                title: tour.title,
                                description: tour.description,
                                price: tour.basePrice,
                                imageUrl: tour.images.isNotEmpty 
                                  ? tour.images.firstWhere((img) => img.isPrimary, orElse: () => tour.images.first).url 
                                  : '',
                              ),
                            );
                          },
                        ),
                      ),
                      // Controls Phân trang
                      if (_tours.length > _pageSize)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 1 
                                    ? () => setState(() => _currentPage--) 
                                    : null,
                              ),
                              Text('Page $_currentPage', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: endIndex < _tours.length 
                                    ? () => setState(() => _currentPage++) 
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, List<String> options, String selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButton<String>(
        value: selectedValue,
        onChanged: onChanged,
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
        hint: Text(label),
      ),
    );
  }
}
