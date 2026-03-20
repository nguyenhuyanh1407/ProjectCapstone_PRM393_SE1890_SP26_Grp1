import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../models/rating_summary.dart';
import '../../services/review_service.dart';
import '../../widgets/rating_input.dart';
import '../../widgets/review_card.dart';

class TourReviewsPage extends StatefulWidget {
  final String tourId;

  const TourReviewsPage({
    super.key,
    required this.tourId,
  });

  @override
  State<TourReviewsPage> createState() => _TourReviewsPageState();
}

class _TourReviewsPageState extends State<TourReviewsPage> {
  final ReviewService _reviewService = ReviewService();

  RatingSummary? _ratingSummary;
  List<Review> _reviews = [];
  bool _isLoading = true;
  String _sortBy = 'newest'; // newest, highest, lowest

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await _reviewService.getRatingSummary(widget.tourId);
      final reviews = await _reviewService.getReviewsByTour(widget.tourId);

      setState(() {
        _ratingSummary = summary;
        _reviews = reviews;
        _isLoading = false;
      });

      _sortReviews();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reviews: $e')),
        );
      }
    }
  }

  void _sortReviews() {
    setState(() {
      switch (_sortBy) {
        case 'highest':
          _reviews.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'lowest':
          _reviews.sort((a, b) => a.rating.compareTo(b.rating));
          break;
        case 'newest':
        default:
          _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _sortReviews();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20),
                    SizedBox(width: 8),
                    Text('Newest'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'highest',
                child: Row(
                  children: [
                    Icon(Icons.star, size: 20),
                    SizedBox(width: 8),
                    Text('Highest Rating'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'lowest',
                child: Row(
                  children: [
                    Icon(Icons.star_border, size: 20),
                    SizedBox(width: 8),
                    Text('Lowest Rating'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Reviews Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Be the first to share your experience with this tour!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Rating summary header
          SliverToBoxAdapter(
            child: _buildRatingSummary(),
          ),

          // Reviews list
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            sliver: _reviews.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No reviews match your filter',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final review = _reviews[index];
                        // Safe substring - handle short userIds
                        final userIdDisplay = review.userId.length >= 8 
                            ? review.userId.substring(0, 8) 
                            : review.userId;
                        return ReviewCard(
                          review: review,
                          userName: 'User $userIdDisplay',
                        );
                      },
                      childCount: _reviews.length,
                    ),
                  ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    if (_ratingSummary == null) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Average rating
          Row(
            children: [
              Column(
                children: [
                  Text(
                    _ratingSummary!.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  RatingDisplay(
                    rating: _ratingSummary!.averageRating,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_ratingSummary!.totalReviews} reviews',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              // Rating distribution
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = _ratingSummary!.ratingDistribution[star.toString()] ?? 0;
                    final percentage = _ratingSummary!.totalReviews > 0
                        ? count / _ratingSummary!.totalReviews
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                width: double.infinity,
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: percentage,
                                  child: Container(),
                                ),
                              ),
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick rating summary card for embedding in other pages
class RatingSummaryCard extends StatelessWidget {
  final RatingSummary summary;
  final VoidCallback? onTap;

  const RatingSummaryCard({
    super.key,
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
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
                    summary.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  RatingDisplay(
                    rating: summary.averageRating,
                    size: 18,
                    showCount: true,
                    reviewCount: summary.totalReviews,
                  ),
                ],
              ),
              const Spacer(),
              // Distribution preview
              Row(
                children: [5, 4, 3, 2, 1].map((star) {
                  final count = summary.ratingDistribution[star.toString()] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            color: count > 0 ? Colors.amber[700] : Colors.grey[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Icon(
                          Icons.star,
                          size: 14,
                          color: count > 0 ? Colors.amber : Colors.grey[300],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 16),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}