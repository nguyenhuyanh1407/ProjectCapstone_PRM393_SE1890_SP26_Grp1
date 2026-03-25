import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_session.dart';

class TripSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'trip_sessions';

  /// Tim TripSession group Open cho tour + ngay cu the
  Future<TripSession?> findGroupSession(String tourId, DateTime date) async {
    final dateStr = _dateToString(date);

    final snapshot = await _firestore
        .collection(_collection)
        .where('tourId', isEqualTo: tourId)
        .where('type', isEqualTo: 'group')
        .where('status', isEqualTo: 'Open')
        .get();

    // Filter by date (compare date string)
    for (final doc in snapshot.docs) {
      final sessionDate = DateTime.parse(doc.data()['date']);
      if (_dateToString(sessionDate) == dateStr) {
        return TripSession.fromJson(doc.data());
      }
    }
    return null;
  }

  /// Lay tat ca group sessions Open cho 1 tour
  Future<List<TripSession>> getOpenGroupSessions(String tourId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('tourId', isEqualTo: tourId)
        .where('type', isEqualTo: 'group')
        .where('status', isEqualTo: 'Open')
        .get();

    return snapshot.docs
        .map((doc) => TripSession.fromJson(doc.data()))
        .where((s) => s.date.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Tao TripSession moi
  Future<TripSession> createSession(TripSession session) async {
    await _firestore
        .collection(_collection)
        .doc(session.id)
        .set(session.toJson());
    return session;
  }

  /// Cap nhat bookedSlots, neu day thi dong
  Future<void> addSlots(String sessionId, int count, int maxSlots) async {
    await _firestore.collection(_collection).doc(sessionId).update({
      'bookedSlots': FieldValue.increment(count),
    });

    // Check neu day slot
    final doc = await _firestore.collection(_collection).doc(sessionId).get();
    final bookedSlots = doc.data()?['bookedSlots'] ?? 0;
    if (bookedSlots >= maxSlots) {
      await _firestore.collection(_collection).doc(sessionId).update({
        'status': 'Closed',
      });
    }
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
