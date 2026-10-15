import 'package:intl/intl.dart';

/// Date utility functions for date normalization and formatting.
class AppDateUtils {
  /// Normalizes a DateTime object to YYYY-MM-DD (start of day: 00:00:00).
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Formats a DateTime into ISO date string 'YYYY-MM-DD'.
  static String toIsoDateString(DateTime date) {
    final normalized = normalizeDate(date);
    return DateFormat('yyyy-MM-dd').format(normalized);
  }

  /// Parses 'YYYY-MM-DD' string back into normalized DateTime.
  static DateTime parseIsoDateString(String dateStr) {
    return normalizeDate(DateFormat('yyyy-MM-dd').parse(dateStr));
  }

  /// Formats date for UI display (e.g., '14 Oct 2026' or '14.10.2026').
  static String formatDateDisplay(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Formats date with full month name for headers (e.g., '14 October 2026').
  static String formatDateFullHeader(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  /// Checks if two dates represent the same calendar day.
  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Returns today's date normalized.
  static DateTime get today => normalizeDate(DateTime.now());
}
