import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tour.dart';
import '../../services/tour_service.dart';
import '../../widgets/rating_star.dart';
import '../../constants/app_colors.dart';
import '../../utils/formatter.dart';
import '../../widgets/floating_chat_button.dart';

class TourDetailPage extends StatefulWidget {
  const TourDetailPage({super.key});

  @override
  State<TourDetailPage> createState() => _TourDetailPageState();
}

class _TourDetailPageState extends State<TourDetailPage> {
  final TourService _dataService = TourService();
  Tour? _tour;
  bool _isLoading = true;
  bool _loadedOnce = false;
  bool _hasBookedTour = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      final tourId = ModalRoute.of(context)!.settings.arguments as String;
      _loadTour(tourId);
    }
  }

  Future<void> _loadTour(String id) async {
    final tour = await _dataService.getTourById(id);
    setState(() {
      _tour = tour;
      _isLoading = false;
    });
    _checkUserBooking(id);
  }

  Future<void> _checkUserBooking(String tourId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('tourId', isEqualTo: tourId)
        .get();

    final hasPaidBooking = snapshot.docs.any((doc) {
      final status = doc.data()['status']?.toString() ?? '';
      return status == 'Paid' || status == 'Completed';
    });

    if (mounted) {
      setState(() => _hasBookedTour = hasPaidBooking);
    }
  }

  void _showAddReviewDialog() {
    int selectedRating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Write a Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Star rating selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedRating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            i < selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null || _tour == null) return;

                    final review = {
                      'userName': user.displayName ?? user.email ?? 'User',
                      'rating': selectedRating,
                      'comment': commentCtrl.text.trim(),
                      'createdAt': DateTime.now().toIso8601String(),
                    };

                    // Save to Firestore
                    await FirebaseFirestore.instance
                        .collection('tours')
                        .doc(_tour!.id)
                        .update({
                      'reviews': FieldValue.arrayUnion([review]),
                    });

                    Navigator.pop(ctx);
                    // Reload tour
                    _loadTour(_tour!.id);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Review submitted!'),
                            backgroundColor: Colors.green),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_tour == null) {
      return const Scaffold(body: Center(child: Text('Tour not found.')));
    }

    final avgRating = _tour!.averageRating;
    final reviewCount = _tour!.reviews.length;

    return Scaffold(
      floatingActionButton: const FloatingChatButton(),
      bottomNavigationBar: _buildBottomBar(),
      body: CustomScrollView(
        slivers: [
          // Hero image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _tour!.images.isNotEmpty
                        ? _tour!.images
                            .firstWhere((img) => img.isPrimary,
                                orElse: () => _tour!.images.first)
                            .url
                        : '',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image,
                          size: 80, color: Colors.grey),
                    ),
                  ),
                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                  // Title overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _tour!.tourType,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tour!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black45)
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips row
                  Row(
                    children: [
                      _infoChip(Icons.location_on_outlined, _tour!.location),
                      const SizedBox(width: 8),
                      _infoChip(Icons.calendar_today,
                          '${_tour!.durationDays} day${_tour!.durationDays > 1 ? 's' : ''}'),
                      const SizedBox(width: 8),
                      _infoChip(Icons.group_outlined,
                          'Max ${_tour!.maxParticipants}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rating summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade100),
                    ),
                    child: Row(
                      children: [
                        Text(
                          avgRating > 0 ? avgRating.toStringAsFixed(1) : '--',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RatingStar(rating: avgRating),
                            const SizedBox(height: 2),
                            Text(
                              reviewCount > 0
                                  ? '$reviewCount review${reviewCount > 1 ? 's' : ''}'
                                  : 'No reviews yet',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text('Description',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _tour!.description,
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),

                  // Itinerary
                  if (_tour!.itinerary != null &&
                      _tour!.itinerary!.isNotEmpty) ...[
                    const Text('Itinerary',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._tour!.itinerary!
                        .map((day) => _buildItineraryDay(day)),
                    const SizedBox(height: 24),
                  ],

                  // Reviews section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews ($reviewCount)',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_hasBookedTour)
                        TextButton.icon(
                          onPressed: _showAddReviewDialog,
                          icon: const Icon(Icons.rate_review_outlined, size: 18),
                          label: const Text('Write Review'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_tour!.reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.reviews_outlined,
                                size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                                _hasBookedTour
                                    ? 'No reviews yet. Be the first!'
                                    : 'No reviews yet.',
                                style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._tour!.reviews.map((r) => _buildReviewCard(r)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(TourReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      Formatter.formatDate(review.createdAt),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: TextStyle(
                  fontSize: 13, height: 1.4, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItineraryDay(dynamic day) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('Day ${day.dayNumber}: ${day.title}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(day.description,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        children: day.activities
            .map<Widget>(
              (act) => ListTile(
                dense: true,
                leading: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(act.startTime,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
                title: Text(act.name, style: const TextStyle(fontSize: 14)),
                subtitle: Text(act.location,
                    style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Price',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(
                Formatter.formatCurrency(_tour!.basePrice),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/booking',
                  arguments: _tour!.id);
            },
            icon: const Icon(Icons.shopping_cart_outlined, size: 20),
            label: const Text('Book Now',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
