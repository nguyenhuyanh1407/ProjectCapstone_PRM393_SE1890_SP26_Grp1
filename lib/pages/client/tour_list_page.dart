import 'package:flutter/material.dart';
import '../../models/tour.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/tour_card.dart';
import '../../constants/app_colors.dart';

class TourListPage extends StatefulWidget {
  const TourListPage({super.key});

  @override
  State<TourListPage> createState() => _TourListPageState();
}

class _TourListPageState extends State<TourListPage> {
  final MockDataService _dataService = MockDataService();
  List<Tour> _tours = [];
  String _searchQuery = '';
  String _selectedProvince = 'All';
  String _selectedType = 'All';

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
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tours.length,
                  itemBuilder: (context, index) {
                    final tour = _tours[index];
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
                        imageUrl: tour.images.firstWhere((img) => img.isPrimary).url,
                      ),
                    );
                  },
                ),
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
