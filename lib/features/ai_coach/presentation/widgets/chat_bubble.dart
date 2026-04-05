import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/enums.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.role,
    required this.content,
    this.timestamp,
  });

  final MessageRole role;
  final String content;
  final DateTime? timestamp;

  bool get _isUser => role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final bgColor = _isUser ? AppColors.lime : AppColors.darkSurface;
    final fgColor = _isUser ? Colors.black : Colors.white;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: _isUser ? const Radius.circular(16) : Radius.zero,
      bottomRight: _isUser ? Radius.zero : const Radius.circular(16),
    );

    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: _isUser
                ? null
                : Border.all(color: AppColors.darkSurfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: textTheme.bodyMedium?.copyWith(
                  color: fgColor,
                  fontWeight:
                      _isUser ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatTime(timestamp!),
                  style: textTheme.bodySmall?.copyWith(
                    color: fgColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
