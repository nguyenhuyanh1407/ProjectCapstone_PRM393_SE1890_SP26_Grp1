import 'package:flutter/material.dart';
import '../models/review.dart';
import '../pages/admin/admin_dashboard_page.dart';
import '../pages/admin/manage_tours_page.dart';
import '../pages/admin/manage_reviews_page.dart';
import '../pages/admin/edit_tour_page.dart';
import '../pages/client/home_page.dart';
import '../pages/client/tour_list_page.dart';
import '../pages/client/tour_detail_page.dart';
import '../pages/client/tour_reviews_page.dart';
import '../pages/client/write_review_page.dart';
import '../pages/user/booking_page.dart';
import '../pages/user/booking_history_page.dart';
import '../pages/user/profile_page.dart';
import '../pages/user/edit_review_page.dart';
import '../pages/guide/guide_dashboard_page.dart';
import '../pages/guide/tour_schedule_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String tourList = '/tour-list';
  static const String tourDetail = '/tour-detail';
  static const String tourReviews = '/tour-reviews';
  static const String writeReview = '/write-review';
  static const String editReview = '/edit-review';
  static const String booking = '/booking';
  static const String bookingHistory = '/booking-history';
  static const String profile = '/profile';
  static const String guideDashboard = '/guide-dashboard';
  static const String tourSchedule = '/tour-schedule';
  static const String adminDashboard = '/admin-dashboard';
  static const String manageTours = '/manage-tours';
  static const String manageReviews = '/manage-reviews';
  static const String editTour = '/edit-tour';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomePage(),
      tourList: (context) => const TourListPage(),
      tourDetail: (context) => const TourDetailPage(),
      tourReviews: (context) => TourReviewsPage(
            tourId: ModalRoute.of(context)!.settings.arguments as String,
          ),
      writeReview: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return WriteReviewPage(
          tourId: args['tourId'] as String,
          tourName: args['tourName'] as String,
          bookingId: args['bookingId'] as String,
          userId: args['userId'] as String,
        );
      },
      editReview: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return EditReviewPage(
          review: args['review'] as Review,
          tourName: args['tourName'] as String,
        );
      },
      booking: (context) => const BookingPage(),
      bookingHistory: (context) => const BookingHistoryPage(),
      profile: (context) => const ProfilePage(),
      guideDashboard: (context) => const GuideDashboardPage(),
      tourSchedule: (context) => const TourSchedulePage(),
      adminDashboard: (context) => const AdminDashboardPage(),
      manageTours: (context) => const ManageToursPage(),
      manageReviews: (context) => const ManageReviewsPage(),
      editTour: (context) => const EditTourPage(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case tourDetail:
        final tourId = args as String?;
        if (tourId == null) {
          return _errorRoute();
        }
        return MaterialPageRoute(
          builder: (context) => const TourDetailPage(),
          settings: settings,
        );

      case tourReviews:
        final tourId = args as String?;
        if (tourId == null) {
          return _errorRoute();
        }
        return MaterialPageRoute(
          builder: (context) => TourReviewsPage(tourId: tourId),
          settings: settings,
        );

      case writeReview:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (context) => WriteReviewPage(
              tourId: args['tourId'],
              tourName: args['tourName'],
              bookingId: args['bookingId'],
              userId: args['userId'],
            ),
            settings: settings,
          );
        }
        return _errorRoute();

      case editReview:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (context) => EditReviewPage(
              review: args['review'],
              tourName: args['tourName'],
            ),
            settings: settings,
          );
        }
        return _errorRoute();

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      ),
    );
  }
}