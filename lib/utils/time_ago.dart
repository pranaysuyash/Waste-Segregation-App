/// Formats a [DateTime] as a human-readable relative time string.
class TimeAgo {
  static String format(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    }
    if (duration.inDays >= 1) {
      return '${duration.inDays}d ago';
    }
    if (duration.inHours >= 1) {
      return '${duration.inHours}h ago';
    }
    if (duration.inMinutes >= 1) {
      return '${duration.inMinutes}m ago';
    }
    return 'Just now';
  }
}
