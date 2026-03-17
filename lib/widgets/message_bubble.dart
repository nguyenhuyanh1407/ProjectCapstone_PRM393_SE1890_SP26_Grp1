import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.isMine ? AppColors.primary : Colors.white;
    final textColor = message.isMine ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: message.isMine ? 56 : 0,
            right: message.isMine ? 0 : 56,
            bottom: 10,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: alignment,
            children: [
              Text(
                message.content,
                style: TextStyle(color: textColor, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat.Hm().format(message.sentAt),
                style: TextStyle(
                  color: message.isMine ? Colors.white70 : Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
