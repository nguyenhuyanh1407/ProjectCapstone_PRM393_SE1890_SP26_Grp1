import 'package:flutter/material.dart';
import '../../models/tour.dart';
import '../../services/tour_service.dart';
import '../../widgets/rating_star.dart';
import '../../constants/app_colors.dart';
import '../../utils/formatter.dart';

class TourDetailPage extends StatefulWidget {
  const TourDetailPage({super.key});

  @override
  State<TourDetailPage> createState() => _TourDetailPageState();
}

class _TourDetailPageState extends State<TourDetailPage> {
  final TourService _dataService = TourService();
  Tour? _tour;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tourId = ModalRoute.of(context)!.settings.arguments as String;
    _loadTour(tourId);
  }

  Future<void> _loadTour(String id) async {
    final tour = await _dataService.getTourById(id);
    setState(() {
      _tour = tour;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_tour == null) return const Scaffold(body: Center(child: Text('Tour not found.')));

    return Scaffold(
      bottomNavigationBar: _buildBottomBar(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                _tour!.images.firstWhere((img) => img.isPrimary).url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                  );
                },
              ),
            ),

          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_tour!.location, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                      RatingStar(rating: 4.5), // Placeholder rating
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_tour!.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_tour!.description),
                  const SizedBox(height: 24),
                  Text('Itinerary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...?_tour!.itinerary?.map((day) => _buildItineraryDay(day)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryDay(dynamic day) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: ExpansionTile(
        title: Text('Day ${day.dayNumber}: ${day.title}'),
        subtitle: Text(day.description),
        children: day.activities.map<Widget>((act) => ListTile(
          leading: Text(act.startTime),
          title: Text(act.name),
          subtitle: Text(act.location),
        )).toList(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Price', style: TextStyle(color: Colors.grey)),
              Text(Formatter.formatCurrency(_tour!.basePrice), 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }
}
