import '../../domain/models.dart';

DateTime startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime addCalendarDays(DateTime value, int days) =>
    DateTime(value.year, value.month, value.day + days);

DateTime endOfDay(DateTime value) => addCalendarDays(value, 1);

DateTime startOfWeek(DateTime value, FirstDayOfWeek firstDay) {
  final day = startOfDay(value);
  final offset = firstDay == FirstDayOfWeek.monday
      ? day.weekday - DateTime.monday
      : day.weekday % 7;
  return addCalendarDays(day, -offset);
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
      return DateRange(start, addCalendarDays(start, 1));
    case StatisticsPeriod.week:
      final start = startOfWeek(anchor, firstDay);
      return DateRange(start, addCalendarDays(start, 7));
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

int calendarDayCount(DateRange range) {
  var count = 0;
  var cursor = startOfDay(range.start);
  while (cursor.isBefore(range.end)) {
    cursor = addCalendarDays(cursor, 1);
    count++;
  }
  return count;
}

DateRange shiftCalendarRange(DateRange range, int days) => DateRange(
      addCalendarDays(range.start, days),
      addCalendarDays(range.end, days),
    );

DateRange previousRange(DateRange range) {
  final dayCount = calendarDayCount(range);
  return shiftCalendarRange(range, -dayCount);
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
        addCalendarDays(current, -1),
        current,
      );
    case StatisticsPeriod.week:
      final current = startOfWeek(anchor, firstDay);
      return DateRange(
        addCalendarDays(current, -7),
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
  final inclusiveEnd = range.end.subtract(const Duration(milliseconds: 1));
  if (startOfDay(range.start) == startOfDay(inclusiveEnd)) {
    return formatDate(range.start);
  }
  return '${formatDate(range.start)} – ${formatDate(inclusiveEnd)}';
}

String csvEscape(String value) => '"${value.replaceAll('"', '""')}"';

int _idSequence = 0;

String newId([String prefix = 'id']) {
  _idSequence = (_idSequence + 1) & 0xFFFFF;
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_idSequence';
}
