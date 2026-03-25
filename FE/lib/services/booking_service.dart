import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  Future<Booking> createBooking(Booking booking) async {
    final docRef = _firestore.collection(_collection).doc(booking.id);
    await docRef.set(booking.toJson());
    return booking;
  }

  Future<List<Booking>> getBookingHistory(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('bookingDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Booking.fromJson(doc.data()))
        .toList();
  }

  Future<void> cancelBooking(String bookingId) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': 'Cancelled',
    });
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': status,
    });
  }
}
