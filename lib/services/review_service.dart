import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import '../models/rating_summary.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _reviewsCollection => _firestore.collection('reviews');
  DocumentReference _ratingDoc(String tourId) => _firestore.collection('ratings').doc(tourId);

  /// Create a new review
  Future<String> createReview(Review review) async {
    try {
      final docRef = await _reviewsCollection.add(review.toJson());
      
      // Update rating summary
      await updateRatingSummary(review.tourId);
      
      return docRef.id;
    } catch (e) {
      print('Error creating review: $e');
      rethrow;
    }
  }

  /// Get review by ID
  Future<Review?> getReviewById(String reviewId) async {
    try {
      final doc = await _reviewsCollection.doc(reviewId).get();
      if (doc.exists) {
        return Review.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting review: $e');
      return null;
    }
  }

  /// Get all approved reviews for a tour
  Future<List<Review>> getReviewsByTour(String tourId, {int limit = 50}) async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('tourId', isEqualTo: tourId)
          .where('status', isEqualTo: 'Approved')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting reviews by tour: $e');
      return [];
    }
  }

  /// Get pending reviews for admin
  Future<List<Review>> getPendingReviews() async {
    try {
      // Get all reviews and filter client-side to avoid index issues
      final querySnapshot = await _reviewsCollection
          .where('status', isEqualTo: 'Pending')
          .get();

      var reviews = querySnapshot.docs
          .map((doc) => Review.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
      
      // Sort client-side
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return reviews;
    } catch (e) {
      print('Error getting pending reviews: $e');
      return [];
    }
  }

  /// Get all reviews for admin (with status filter)
  Future<List<Review>> getAllReviews({String? statusFilter}) async {
    try {
      QuerySnapshot querySnapshot;
      
      // First, get all reviews without filter to debug
      querySnapshot = await _reviewsCollection.get();
      
      print('Total reviews in Firestore: ${querySnapshot.docs.length}');
      
      var reviews = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('Review data: status=${data['status']}, id=${doc.id}');
            return Review.fromJson({...data, 'id': doc.id});
          })
          .toList();
      
      // Filter client-side
      if (statusFilter != null && statusFilter.isNotEmpty) {
        reviews = reviews.where((r) => r.status == statusFilter).toList();
        print('Filtered reviews for $statusFilter: ${reviews.length}');
      }
      
      // Sort client-side by createdAt
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return reviews;
    } catch (e) {
      print('Error getting all reviews: $e');
      return [];
    }
  }

  /// Get reviews by user
  Future<List<Review>> getReviewsByUser(String userId) async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting reviews by user: $e');
      return [];
    }
  }

  /// Check if user has already reviewed a booking
  Future<bool> hasUserReviewedBooking(String bookingId) async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user reviewed booking: $e');
      return false;
    }
  }

  /// Approve a review
  Future<void> approveReview(String reviewId) async {
    try {
      await _reviewsCollection.doc(reviewId).update({
        'status': 'Approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the review to update rating
      final review = await getReviewById(reviewId);
      if (review != null) {
        await updateRatingSummary(review.tourId);
      }
    } catch (e) {
      print('Error approving review: $e');
      rethrow;
    }
  }

  /// Reject a review
  Future<void> rejectReview(String reviewId, String adminNote) async {
    try {
      await _reviewsCollection.doc(reviewId).update({
        'status': 'Rejected',
        'adminNote': adminNote,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error rejecting review: $e');
      rethrow;
    }
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      final review = await getReviewById(reviewId);
      if (review != null) {
        await _reviewsCollection.doc(reviewId).delete();
        await updateRatingSummary(review.tourId);
      }
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }

  /// Update a review (for editing rejected reviews)
  Future<void> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    required List<String> reviewImages,
  }) async {
    try {
      print('Updating review $reviewId...');
      
      await _reviewsCollection.doc(reviewId).update({
        'rating': rating,
        'comment': comment,
        'reviewImages': reviewImages,
        'status': 'Pending', // Reset to pending for re-approval
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Review updated successfully');

      // Get the review to update rating summary
      final review = await getReviewById(reviewId);
      if (review != null) {
        await updateRatingSummary(review.tourId);
      }
    } catch (e) {
      print('Error updating review: $e');
      rethrow;
    }
  }

  /// Update rating summary for a tour
  Future<void> updateRatingSummary(String tourId) async {
    try {
      print('Updating rating summary for tourId: $tourId');
      
      // Get all approved reviews for this tour
      final querySnapshot = await _reviewsCollection
          .where('tourId', isEqualTo: tourId)
          .where('status', isEqualTo: 'Approved')
          .get();

      print('Found ${querySnapshot.docs.length} approved reviews');

      int totalReviews = querySnapshot.docs.length;
      double averageRating = 0.0;
      Map<String, int> distribution = {
        '1': 0,
        '2': 0,
        '3': 0,
        '4': 0,
        '5': 0,
      };

      if (totalReviews > 0) {
        int sum = 0;
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          int rating = data['rating'] ?? 5;
          print('Review rating: $rating');
          sum += rating;
          distribution[rating.toString()] = (distribution[rating.toString()] ?? 0) + 1;
        }
        averageRating = sum / totalReviews;
        print('Calculated average: $averageRating, total: $totalReviews');
      }

      // Update or create rating summary document
      await _ratingDoc(tourId).set({
        'tourId': tourId,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'ratingDistribution': distribution,
      }, SetOptions(merge: true));
      
      print('Rating summary updated successfully');
    } catch (e) {
      print('Error updating rating summary: $e');
    }
  }

  /// Manual rebuild rating summary for a tour (for fixing broken summaries)
  Future<void> rebuildRatingSummary(String tourId) async {
    print('Manually rebuilding rating summary for tourId: $tourId');
    await updateRatingSummary(tourId);
  }

  /// Get rating summary for a tour
  Future<RatingSummary?> getRatingSummary(String tourId) async {
    try {
      final doc = await _ratingDoc(tourId).get();
      if (doc.exists) {
        return RatingSummary.fromJson({...doc.data() as Map<String, dynamic>, 'tourId': doc.id});
      }
      // Return empty summary if not found
      return RatingSummary(tourId: tourId);
    } catch (e) {
      print('Error getting rating summary: $e');
      return RatingSummary(tourId: tourId);
    }
  }

  /// Stream of reviews for a tour (real-time updates)
  Stream<List<Review>> streamReviewsByTour(String tourId) {
    return _reviewsCollection
        .where('tourId', isEqualTo: tourId)
        .where('status', isEqualTo: 'Approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }

  /// Stream of pending reviews for admin
  Stream<List<Review>> streamPendingReviews() {
    return _reviewsCollection
        .where('status', isEqualTo: 'Pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }
}