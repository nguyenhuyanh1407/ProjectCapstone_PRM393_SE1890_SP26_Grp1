import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tour.dart';

class TourService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tours';

  Future<List<Tour>> getTours() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      // Ensure the ID from Firestore document is preserved if needed, 
      // but current model stores 'id' in the JSON itself.
      return Tour.fromJson(data);
    }).toList();
  }

  Future<Tour> getTourById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) throw Exception('Tour not found');
    return Tour.fromJson(doc.data()!);
  }

  Future<void> addTour(Tour tour) async {
    await _firestore.collection(_collection).doc(tour.id).set(tour.toJson());
  }

  Future<void> updateTour(Tour tour) async {
    await _firestore.collection(_collection).doc(tour.id).update(tour.toJson());
  }

  Future<void> deleteTour(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<List<Tour>> filterTours({String? province, String? type}) async {
    final tours = await getTours();
    return tours.where((tour) {
      bool provinceMatch = province == null || province == 'All' || tour.location == province;
      bool typeMatch = type == null || type == 'All' || tour.tourType == type;
      return provinceMatch && typeMatch;
    }).toList();
  }
}

