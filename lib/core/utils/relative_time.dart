/// Converts a [DateTime] to a compact relative string
/// like "just now", "2m ago", "3h ago", "Yesterday", or "Apr 17".
String formatRelativeTime(DateTime? when) {
  if (when == null) return '';
  final now = DateTime.now();
  final diff = now.difference(when);

  if (diff.isNegative) return 'just now';
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24 && _isSameDay(now, when)) return '${diff.inHours}h ago';

  final yesterday = now.subtract(const Duration(days: 1));
  if (_isSameDay(yesterday, when)) return 'Yesterday';

  if (diff.inDays < 7) return '${diff.inDays}d ago';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  if (when.year == now.year) {
    return '${months[when.month - 1]} ${when.day}';
  }
  return '${months[when.month - 1]} ${when.day}, ${when.year}';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
