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
}
