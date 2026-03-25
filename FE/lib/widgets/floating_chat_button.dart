import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class FloatingChatButton extends StatelessWidget {
  const FloatingChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.chatList),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        mini: true,
        child: const Icon(Icons.chat_bubble_outline, size: 20),
      ),
    );
  }
}
