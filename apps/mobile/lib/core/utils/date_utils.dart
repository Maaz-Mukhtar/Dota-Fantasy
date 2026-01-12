import 'package:intl/intl.dart';

/// Utility class for date formatting and manipulation
class AppDateUtils {
  AppDateUtils._();

  /// Format a date as "Jan 15, 2026"
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format a date as "January 15, 2026"
  static String formatDateLong(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  /// Format a date as "01/15/2026"
  static String formatDateShort(DateTime date) {
    return DateFormat('MM/dd/y').format(date);
  }

  /// Format a time as "3:30 PM"
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// Format a date and time as "Jan 15, 2026 at 3:30 PM"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y \'at\' h:mm a').format(dateTime);
  }

  /// Format a date range as "Jan 15 - Jan 20, 2026"
  static String formatDateRange(DateTime start, DateTime? end) {
    if (end == null) {
      return formatDate(start);
    }

    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${DateFormat('MMM d').format(start)} - ${DateFormat('d, y').format(end)}';
      }
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, y').format(end)}';
    }

    return '${formatDate(start)} - ${formatDate(end)}';
  }

  /// Get relative time string (e.g., "2 hours ago", "in 3 days")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      // Past
      final absDiff = difference.abs();
      if (absDiff.inMinutes < 1) {
        return 'just now';
      } else if (absDiff.inMinutes < 60) {
        final minutes = absDiff.inMinutes;
        return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (absDiff.inHours < 24) {
        final hours = absDiff.inHours;
        return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
      } else if (absDiff.inDays < 7) {
        final days = absDiff.inDays;
        return '$days ${days == 1 ? 'day' : 'days'} ago';
      } else {
        return formatDate(dateTime);
      }
    } else {
      // Future
      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return 'in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return 'in $hours ${hours == 1 ? 'hour' : 'hours'}';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return 'in $days ${days == 1 ? 'day' : 'days'}';
      } else {
        return formatDate(dateTime);
      }
    }
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if a date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if a date is within the next N hours
  static bool isWithinHours(DateTime date, int hours) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(hours: hours));
    return date.isAfter(now) && date.isBefore(cutoff);
  }

  /// Format duration in seconds as "MM:SS" or "H:MM:SS"
  static String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
