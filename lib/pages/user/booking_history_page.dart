import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import '../../routes/app_routes.dart';
import '../../constants/app_colors.dart';

// Mock booking data for demonstration
class MockBooking {
  final String id;
  final String tourId;
  final String tourName;
  final DateTime travelDate;
  final int numberOfPeople;
  final double totalPrice;
  final String status; // Pending, Confirmed, Completed, Cancelled

  MockBooking({
    required this.id,
    required this.tourId,
    required this.tourName,
    required this.travelDate,
    required this.numberOfPeople,
    required this.totalPrice,
    required this.status,
  });
}

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final ReviewService _reviewService = ReviewService();

  // Cache for review status
  final Map<String, Review?> _reviewCache = {};
  bool _isLoadingReviews = false;

  // Mock data - replace with actual API call
  // IMPORTANT: tourId must match IDs in assets/data/tours.json
  final List<MockBooking> _bookings = [
    MockBooking(
      id: 'booking1',
      tourId: 't1-uuid-1234', // Ha Long Bay
      tourName: 'Ha Long Bay Cruise 3 Days',
      travelDate: DateTime(2024, 12, 15),
      numberOfPeople: 2,
      totalPrice: 5000000,
      status: 'Completed',
    ),
    MockBooking(
      id: 'booking2',
      tourId: 't2-uuid-5678', // Da Lat
      tourName: 'Sapa Trekking Adventure',
      travelDate: DateTime(2025, 1, 20),
      numberOfPeople: 4,
      totalPrice: 8000000,
      status: 'Confirmed',
    ),
    MockBooking(
      id: 'booking3',
      tourId: 't3-uuid-9012', // Phu Quoc
      tourName: 'Hoi An Ancient Town Tour',
      travelDate: DateTime(2024, 11, 10),
      numberOfPeople: 3,
      totalPrice: 3500000,
      status: 'Completed',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadReviewStatus();
  }

  Future<void> _loadReviewStatus() async {
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final allReviews = await _reviewService.getAllReviews();
      for (final booking in _bookings) {
        final review = allReviews.firstWhere(
          (r) => r.bookingId == booking.id,
          orElse: () => Review(
            id: '',
            bookingId: booking.id,
            userId: '',
            tourId: booking.tourId,
            rating: 0,
            comment: '',
            createdAt: DateTime.now(),
          ),
        );
        if (review.id.isNotEmpty) {
          _reviewCache[booking.id] = review;
        } else {
          _reviewCache[booking.id] = null;
        }
      }
    } catch (e) {
      print('Error loading review status: $e');
    }

    setState(() {
      _isLoadingReviews = false;
    });
  }

  void _navigateToWriteReview(MockBooking booking) async {
    // Use mock userId for testing (replace with actual user ID from your auth system)
    final userId = 'user123';

    Navigator.pushNamed(
      context,
      AppRoutes.writeReview,
      arguments: {
        'tourId': booking.tourId,
        'tourName': booking.tourName,
        'bookingId': booking.id,
        'userId': userId,
      },
    ).then((_) => _loadReviewStatus());
  }

  Future<void> _navigateToEditReview(MockBooking booking, Review review) async {
    final result = await Navigator.pushNamed(
      context,
      '/edit-review',
      arguments: {
        'review': review,
        'tourName': booking.tourName,
      },
    );

    if (result == true) {
      await _loadReviewStatus();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Confirmed':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        actions: [
          IconButton(
            icon: _isLoadingReviews
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoadingReviews ? null : _loadReviewStatus,
          ),
        ],
      ),
      body: _bookings.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No bookings yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return _buildBookingCard(booking);
              },
            ),
    );
  }

  Widget _buildBookingCard(MockBooking booking) {
    final canReview = booking.status == 'Completed';
    final review = _reviewCache[booking.id];
    final canEdit = review != null && review.status == 'Rejected';
    final hasReviewed = review != null && !canEdit;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.tourName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(booking.status)),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Travel: ${booking.travelDate.day}/${booking.travelDate.month}/${booking.travelDate.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${booking.numberOfPeople} people',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasReviewed) ...[
              Row(
                children: [
                  Icon(
                    canEdit ? Icons.warning : Icons.check_circle,
                    size: 16,
                    color: canEdit ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    canEdit ? 'Rejected' : 'Reviewed',
                    style: TextStyle(
                      color: canEdit ? Colors.orange[700] : Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (canEdit && review!.adminNote != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '(${review.adminNote})',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Text(
              'Total: ${booking.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canReview && !hasReviewed)
                  ElevatedButton.icon(
                    onPressed: () => _navigateToWriteReview(booking),
                    icon: const Icon(Icons.rate_review, size: 14),
                    label: const Text('Write Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if (canEdit) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToEditReview(booking, review!),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Edit Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}