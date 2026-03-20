import 'package:flutter/material.dart';
import '../../models/tour.dart';
import '../../services/mock_data_service.dart';
import '../../services/review_service.dart';
import '../../widgets/rating_star.dart';
import '../../widgets/rating_input.dart';
import '../../constants/app_colors.dart';
import '../../utils/formatter.dart';
import '../../routes/app_routes.dart';

class TourDetailPage extends StatefulWidget {
  const TourDetailPage({super.key});

  @override
  State<TourDetailPage> createState() => _TourDetailPageState();
}

class _TourDetailPageState extends State<TourDetailPage> {
  final MockDataService _dataService = MockDataService();
  final ReviewService _reviewService = ReviewService();
  Tour? _tour;
  bool _isLoading = true;
  dynamic _ratingSummary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tourId = ModalRoute.of(context)!.settings.arguments as String;
    _loadTour(tourId);
    _loadRatingSummary(tourId);
  }

  Future<void> _loadTour(String id) async {
    final tour = await _dataService.getTourById(id);
    setState(() {
      _tour = tour;
      _isLoading = false;
    });
  }

  Future<void> _loadRatingSummary(String tourId) async {
    print('Loading rating summary for tourId: $tourId');
    final summary = await _reviewService.getRatingSummary(tourId);
    print('Rating summary: avg=${summary?.averageRating}, total=${summary?.totalReviews}');
    setState(() {
      _ratingSummary = summary;
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
                      _ratingSummary != null
                          ? RatingDisplay(rating: _ratingSummary.averageRating, size: 20, showCount: true, reviewCount: _ratingSummary.totalReviews)
                          : const RatingStar(rating: 4.5),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_tour!.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_tour!.description),
                  const SizedBox(height: 24),
                  if (_ratingSummary != null) ...[
                    _buildRatingSection(),
                    const SizedBox(height: 24),
                  ],
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

  Widget _buildRatingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.tourReviews,
            arguments: _tour!.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Average rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ratingSummary.averageRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  RatingDisplay(
                    rating: _ratingSummary.averageRating,
                    size: 18,
                    showCount: true,
                    reviewCount: _ratingSummary.totalReviews,
                  ),
                ],
              ),
              const Spacer(),
              // Distribution preview
              Row(
                children: [5, 4, 3, 2, 1].map((star) {
                  final count = _ratingSummary.ratingDistribution[star.toString()] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 14,
                            color: count > 0 ? Colors.amber[700] : Colors.grey[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Icon(
                          Icons.star,
                          size: 16,
                          color: count > 0 ? Colors.amber : Colors.grey[300],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
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
          Row(
            children: [
              // See Reviews button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.tourReviews,
                    arguments: _tour!.id,
                  );
                },
                icon: const Icon(Icons.rate_review, size: 18),
                label: const Text('Reviews'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
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
        ],
      ),
    );
  }
}
