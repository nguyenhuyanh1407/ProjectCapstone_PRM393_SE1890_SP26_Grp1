import '../models/tour.dart';
import 'api_service.dart';

class TourService {
  final ApiService _apiService = ApiService();

  Future<List<Tour>> getTours() async {
    final response = await _apiService.get('/tours');
    return (response as List).map((json) => Tour.fromJson(json)).toList();
  }

  Future<Tour> getTourById(String id) async {
    final response = await _apiService.get('/tours/$id');
    return Tour.fromJson(response);
  }
}
