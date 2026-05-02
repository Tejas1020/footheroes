/// Season utility — season runs July 1 to June 30 (mid-next year).
class SeasonUtil {
  /// e.g. DateTime(2025, 7, 15) → "2025/26"
  ///      DateTime(2026, 3, 1)  → "2025/26"
  ///      DateTime(2026, 6, 30) → "2025/26"
  ///      DateTime(2026, 7, 1)  → "2026/27"
  static String seasonLabel(DateTime date) {
    final year = date.year;
    if (date.month >= 7) {
      return '$year/${((year + 1) % 100).toString().padLeft(2, '0')}';
    }
    return '${year - 1}/${(year % 100).toString().padLeft(2, '0')}';
  }

  /// Returns (start, end) DateTime range for a season label like "2025/26".
  /// Start: July 1 of the first year. End: June 30 of the next year, 23:59:59.
  static (DateTime, DateTime) seasonDateRange(String season) {
    final parts = season.split('/');
    final startYear = int.parse(parts[0]);
    final start = DateTime(startYear, 7, 1);
    final end = DateTime(startYear + 1, 6, 30, 23, 59, 59);
    return (start, end);
  }

  /// Extract unique season labels from matches, sorted newest first.
  static List<String> availableSeasons(List<DateTime> matchDates) {
    final labels = matchDates.map(seasonLabel).toSet().toList();
    labels.sort((a, b) => b.compareTo(a));
    return labels;
  }

  /// Filter dates that fall within a given season label.
  static bool isInSeason(DateTime date, String season) {
    final (start, end) = seasonDateRange(season);
    return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(end.add(const Duration(seconds: 1)));
  }
}
