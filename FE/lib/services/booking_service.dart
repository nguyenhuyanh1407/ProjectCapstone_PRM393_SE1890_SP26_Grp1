import '../models/booking.dart';
import 'api_service.dart';

class BookingService {
  final ApiService _apiService = ApiService();

  Future<Booking> createBooking(Booking booking) async {
    final response = await _apiService.post('/bookings', booking.toJson());
    return Booking.fromJson(response);
  }

  Future<List<Booking>> getBookingHistory(String userId) async {
    final response = await _apiService.get('/bookings/user/$userId');
    return (response as List).map((json) => Booking.fromJson(json)).toList();
  }
}
