import 'package:flutter_test/flutter_test.dart';
import 'package:timiq/core/utils/time_utils.dart';
import 'package:timiq/domain/models.dart';

void main() {
  test('duration uses start and current time for a running entry', () {
    final start = DateTime(2026, 7, 19, 8);
    final entry = TimeEntry(
      id: 'e1',
      activityId: 'a1',
      startTime: start,
      createdAt: start,
      updatedAt: start,
    );

    expect(
      entry.durationAt(DateTime(2026, 7, 19, 10, 30)),
      const Duration(hours: 2, minutes: 30),
    );
  });

  test('overlap treats touching intervals as non-overlapping', () {
    final eight = DateTime(2026, 7, 19, 8);
    final nine = DateTime(2026, 7, 19, 9);
    final ten = DateTime(2026, 7, 19, 10);

    expect(entriesOverlap(eight, nine, nine, ten), isFalse);
    expect(
      entriesOverlap(eight, ten, nine, DateTime(2026, 7, 19, 11)),
      isTrue,
    );
  });

  test('calendar month compares with the actual previous month', () {
    final previous = previousRangeForPeriod(
      StatisticsPeriod.month,
      DateTime(2026, 3, 20),
      FirstDayOfWeek.monday,
    );

    expect(previous.start, DateTime(2026, 2));
    expect(previous.end, DateTime(2026, 3));
  });

  test('week respects Sunday as first day', () {
    final start = startOfWeek(
      DateTime(2026, 7, 22),
      FirstDayOfWeek.sunday,
    );
    expect(start, DateTime(2026, 7, 19));
  });

  test('calendar helpers advance date components across month boundaries', () {
    final spring = DateTime(2026, 3, 29);
    final autumn = DateTime(2026, 10, 25);

    expect(addCalendarDays(spring, 1), DateTime(2026, 3, 30));
    expect(addCalendarDays(autumn, 1), DateTime(2026, 10, 26));
    expect(endOfDay(DateTime(2026, 1, 31, 20)), DateTime(2026, 2));
  });

  test('custom calendar range shifts by whole calendar dates', () {
    final range = DateRange(DateTime(2026, 3, 28), DateTime(2026, 4, 2));
    final previous = previousRange(range);

    expect(calendarDayCount(range), 5);
    expect(previous.start, DateTime(2026, 3, 23));
    expect(previous.end, DateTime(2026, 3, 28));
  });

  test('multi-day entry clips independently into each calendar day', () {
    final start = DateTime(2026, 7, 19, 22);
    final end = DateTime(2026, 7, 21, 2);

    expect(
      clippedDuration(
        start,
        end,
        DateRange(DateTime(2026, 7, 19), DateTime(2026, 7, 20)),
        end,
      ),
      const Duration(hours: 2),
    );
    expect(
      clippedDuration(
        start,
        end,
        DateRange(DateTime(2026, 7, 20), DateTime(2026, 7, 21)),
        end,
      ),
      const Duration(hours: 24),
    );
    expect(
      clippedDuration(
        start,
        end,
        DateRange(DateTime(2026, 7, 21), DateTime(2026, 7, 22)),
        end,
      ),
      const Duration(hours: 2),
    );
  });
}
