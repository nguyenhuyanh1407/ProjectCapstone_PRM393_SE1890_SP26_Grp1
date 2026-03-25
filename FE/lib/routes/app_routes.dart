import 'package:flutter/material.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/auth/forgot_password_page.dart';
import '../pages/client/home_page.dart';
import '../pages/client/tour_list_page.dart';
import '../pages/client/tour_detail_page.dart';
import '../pages/user/booking_page.dart';
import '../pages/user/booking_history_page.dart';
import '../pages/user/profile_page.dart';
import '../pages/user/edit_profile_page.dart';
import '../pages/guide/guide_dashboard_page.dart';
import '../pages/guide/tour_schedule_page.dart';
import '../pages/admin/admin_dashboard_page.dart';
import '../pages/admin/manage_tours_page.dart';
import '../pages/admin/edit_tour_page.dart';
import '../pages/admin/manage_users_page.dart';
import '../pages/chat/chat_detail_page.dart';
import '../pages/chat/chat_list_page.dart';
import '../models/user.dart';
import '../widgets/role_guard.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String home = '/';
  static const String tourList = '/tour-list';
  static const String tourDetail = '/tour-detail';

  static const String booking = '/booking';
  static const String bookingHistory = '/booking-history';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  static const String guideDashboard = '/guide-dashboard';
  static const String tourSchedule = '/tour-schedule';

  static const String adminDashboard = '/admin-dashboard';
  static const String manageTours = '/manage-tours';
  static const String editTour = '/edit-tour';
  static const String manageUsers = '/manage-users';

  static const String chatList = '/chat-list';
  static const String chatDetail = '/chat-detail';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      forgotPassword: (context) => const ForgotPasswordPage(),

      home: (context) => const HomePage(),
      tourList: (context) => const TourListPage(),
      tourDetail: (context) => const TourDetailPage(),
      '/menu': (context) => const HomePage(),

      booking: (context) => const BookingPage(),
      bookingHistory: (context) => const BookingHistoryPage(),
      profile: (context) => const ProfilePage(),
      editProfile: (context) => const EditProfilePage(),

      guideDashboard: (context) => const RoleGuard(
        allowedRoles: [UserRole.guide],
        pageTitle: 'Guide Dashboard',
        child: GuideDashboardPage(),
      ),
      tourSchedule: (context) => const RoleGuard(
        allowedRoles: [UserRole.guide],
        pageTitle: 'Tour Schedule',
        child: TourSchedulePage(),
      ),

      adminDashboard: (context) => const RoleGuard(
        allowedRoles: [UserRole.admin],
        pageTitle: 'Admin Dashboard',
        child: AdminDashboardPage(),
      ),
      manageTours: (context) => const RoleGuard(
        allowedRoles: [UserRole.admin],
        pageTitle: 'Manage Tours',
        child: ManageToursPage(),
      ),
      editTour: (context) => const RoleGuard(
        allowedRoles: [UserRole.admin],
        pageTitle: 'Edit Tour',
        child: EditTourPage(),
      ),
      manageUsers: (context) => const RoleGuard(
        allowedRoles: [UserRole.admin],
        pageTitle: 'Manage Users',
        child: ManageUsersPage(),
      ),

      chatList: (context) => const ChatListPage(),
      chatDetail: (context) => const ChatDetailPage(),
    };
  }
}
