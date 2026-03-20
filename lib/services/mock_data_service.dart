import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/tour.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  List<Tour> _tours = [];

  Future<void> init() async {
    if (_tours.isNotEmpty) return;
    final String response = await rootBundle.loadString('assets/data/tours.json');
    final data = await json.decode(response);
    _tours = (data as List).map((json) => Tour.fromJson(json)).toList();
  }

  Future<List<Tour>> getTours() async {
    await init();
    return _tours;
  }

  Future<List<Tour>> searchTours(String query) async {
    await init();
    if (query.isEmpty) return _tours;
    return _tours.where((tour) =>
      tour.title.toLowerCase().contains(query.toLowerCase()) ||
      tour.location.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<List<Tour>> filterTours({String? province, String? type}) async {
    await init();
    return _tours.where((tour) {
      bool provinceMatch = province == null || province == 'All' || tour.location == province;
      bool typeMatch = type == null || type == 'All' || tour.tourType == type;
      return provinceMatch && typeMatch;
    }).toList();
  }

  Future<Tour> getTourById(String id) async {
    await init();
    return _tours.firstWhere((tour) => tour.id == id);
  }

  // Admin Mock CRUD
  Future<void> addTour(Tour tour) async {
    _tours.add(tour);
  }

  Future<void> updateTour(Tour tour) async {
    int index = _tours.indexWhere((t) => t.id == tour.id);
    if (index != -1) {
      _tours[index] = tour;
    }
  }

  Future<void> deleteTour(String id) async {
    _tours.removeWhere((t) => t.id == id);
  }
}
