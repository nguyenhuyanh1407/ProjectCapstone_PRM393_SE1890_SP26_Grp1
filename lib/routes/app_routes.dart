import 'package:flutter/material.dart';
import '../pages/client/home_page.dart';
import '../pages/client/tour_list_page.dart';
import '../pages/client/tour_detail_page.dart';
import '../pages/user/booking_page.dart';
import '../pages/user/booking_history_page.dart';
import '../pages/user/profile_page.dart';
import '../pages/guide/guide_dashboard_page.dart';
import '../pages/guide/tour_schedule_page.dart';
import '../pages/admin/admin_dashboard_page.dart';
import '../pages/admin/manage_tours_page.dart';
import '../pages/admin/edit_tour_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String tourList = '/tour-list';
  static const String tourDetail = '/tour-detail';
  static const String booking = '/booking';
  static const String bookingHistory = '/booking-history';
  static const String profile = '/profile';
  static const String guideDashboard = '/guide-dashboard';
  static const String tourSchedule = '/tour-schedule';
  static const String adminDashboard = '/admin-dashboard';
  static const String manageTours = '/manage-tours';
  static const String editTour = '/edit-tour';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomePage(),
      tourList: (context) => const TourListPage(),
      tourDetail: (context) => const TourDetailPage(),
      booking: (context) => const BookingPage(),
      bookingHistory: (context) => const BookingHistoryPage(),
      profile: (context) => const ProfilePage(),
      guideDashboard: (context) => const GuideDashboardPage(),
      tourSchedule: (context) => const TourSchedulePage(),
      adminDashboard: (context) => const AdminDashboardPage(),
      manageTours: (context) => const ManageToursPage(),
      editTour: (context) => const EditTourPage(),
    };
  }
}

