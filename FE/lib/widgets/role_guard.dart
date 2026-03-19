import 'package:flutter/material.dart';

import '../models/user.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.pageTitle = 'Protected page',
  });

  final List<UserRole> allowedRoles;
  final Widget child;
  final String pageTitle;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: AuthService().getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return _AccessDeniedPage(
            title: pageTitle,
            message: 'You need to log in again to continue.',
            actionLabel: 'Go to login',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (route) => false,
            ),
          );
        }

        if (!allowedRoles.contains(user.role)) {
          return _AccessDeniedPage(
            title: pageTitle,
            message: 'Your role does not have permission to access this page.',
            actionLabel: 'Back to home',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            ),
          );
        }

        return child;
      },
    );
  }
}

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Access denied',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onPressed, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
