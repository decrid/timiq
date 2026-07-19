import '../../domain/models.dart';

DateTime startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime endOfDay(DateTime value) => startOfDay(value).add(const Duration(days: 1));

DateTime startOfWeek(DateTime value, FirstDayOfWeek firstDay) {
  final day = startOfDay(value);
  final offset = firstDay == FirstDayOfWeek.monday
      ? day.weekday - DateTime.monday
      : day.weekday % 7;
  return day.subtract(Duration(days: offset));
}

DateRange rangeForPeriod(
  StatisticsPeriod period,
  DateTime anchor,
  FirstDayOfWeek firstDay, {
  DateRange? custom,
}) {
  switch (period) {
    case StatisticsPeriod.day:
      final start = startOfDay(anchor);
      return DateRange(start, start.add(const Duration(days: 1)));
    case StatisticsPeriod.week:
      final start = startOfWeek(anchor, firstDay);
      return DateRange(start, start.add(const Duration(days: 7)));
    case StatisticsPeriod.month:
      final start = DateTime(anchor.year, anchor.month);
      return DateRange(start, DateTime(anchor.year, anchor.month + 1));
    case StatisticsPeriod.year:
      final start = DateTime(anchor.year);
      return DateRange(start, DateTime(anchor.year + 1));
    case StatisticsPeriod.custom:
      if (custom == null) {
        throw const TimiqValidationException('Vyberte vlastní období.');
      }
      return custom;
  }
}

DateRange previousRange(DateRange range) {
  final duration = range.duration;
  return DateRange(range.start.subtract(duration), range.start);
}

DateRange previousRangeForPeriod(
  StatisticsPeriod period,
  DateTime anchor,
  FirstDayOfWeek firstDay, {
  DateRange? custom,
}) {
  switch (period) {
    case StatisticsPeriod.day:
      final current = startOfDay(anchor);
      return DateRange(
        current.subtract(const Duration(days: 1)),
        current,
      );
    case StatisticsPeriod.week:
      final current = startOfWeek(anchor, firstDay);
      return DateRange(
        current.subtract(const Duration(days: 7)),
        current,
      );
    case StatisticsPeriod.month:
      return DateRange(
        DateTime(anchor.year, anchor.month - 1),
        DateTime(anchor.year, anchor.month),
      );
    case StatisticsPeriod.year:
      return DateRange(DateTime(anchor.year - 1), DateTime(anchor.year));
    case StatisticsPeriod.custom:
      if (custom == null) {
        throw const TimiqValidationException('Vyberte vlastní období.');
      }
      return previousRange(custom);
  }
}

Duration clippedDuration(
  DateTime start,
  DateTime? end,
  DateRange range,
  DateTime now,
) {
  final actualStart = start.isBefore(range.start) ? range.start : start;
  final candidateEnd = end ?? now;
  final actualEnd = candidateEnd.isAfter(range.end) ? range.end : candidateEnd;
  if (!actualEnd.isAfter(actualStart)) return Duration.zero;
  return actualEnd.difference(actualStart);
}

bool entriesOverlap(
  DateTime firstStart,
  DateTime firstEnd,
  DateTime secondStart,
  DateTime secondEnd,
) =>
    firstStart.isBefore(secondEnd) && secondStart.isBefore(firstEnd);

String twoDigits(int value) => value.toString().padLeft(2, '0');

String formatClock(
  DateTime value, {
  TimiqTimeFormat format = TimiqTimeFormat.twentyFourHour,
}) {
  if (format == TimiqTimeFormat.twentyFourHour) {
    return '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '$hour:${twoDigits(value.minute)} ${value.hour < 12 ? 'AM' : 'PM'}';
}

String formatTimer(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60);
  final seconds = safe.inSeconds.remainder(60);
  return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
}

String formatDuration(Duration duration, {bool compact = false}) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60);
  if (compact) {
    if (hours > 0) return '$hours h ${minutes > 0 ? '$minutes min' : ''}'.trim();
    return '${safe.inMinutes} min';
  }
  if (hours > 0) {
    return '$hours h ${twoDigits(minutes)} min';
  }
  if (safe.inMinutes > 0) return '${safe.inMinutes} min';
  return '${safe.inSeconds} s';
}

const List<String> _months = <String>[
  'leden',
  'únor',
  'březen',
  'duben',
  'květen',
  'červen',
  'červenec',
  'srpen',
  'září',
  'říjen',
  'listopad',
  'prosinec',
];

const List<String> _weekdays = <String>[
  'pondělí',
  'úterý',
  'středa',
  'čtvrtek',
  'pátek',
  'sobota',
  'neděle',
];

String formatDate(DateTime value, {bool includeYear = true}) {
  final base = '${value.day}. ${_months[value.month - 1]}';
  return includeYear ? '$base ${value.year}' : base;
}

String formatDateWithWeekday(DateTime value) =>
    '${_weekdays[value.weekday - 1]}, ${formatDate(value)}';

String formatRange(DateRange range) {
  final inclusiveEnd = range.end.subtract(const Duration(days: 1));
  if (startOfDay(range.start) == startOfDay(inclusiveEnd)) {
    return formatDate(range.start);
  }
  return '${formatDate(range.start)} – ${formatDate(inclusiveEnd)}';
}

String csvEscape(String value) => '"${value.replaceAll('"', '""')}"';

String newId([String prefix = 'id']) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
