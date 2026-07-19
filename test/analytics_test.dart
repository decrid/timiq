import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timiq/domain/analytics.dart';
import 'package:timiq/domain/models.dart';

void main() {
  final created = DateTime(2026, 1, 1);
  final work = TimiqCategory(
    id: 'work',
    name: 'Práce',
    colorValue: Colors.blue.toARGB32(),
    iconCodePoint: Icons.work.codePoint,
    sortOrder: 0,
    isArchived: false,
    createdAt: created,
    updatedAt: created,
  );
  final coding = TimiqActivity(
    id: 'coding',
    categoryId: work.id,
    name: 'Vývoj',
    iconCodePoint: Icons.code.codePoint,
    isFavorite: true,
    sortOrder: 0,
    isArchived: false,
    createdAt: created,
    updatedAt: created,
  );

  test('statistics clip entries to period boundaries and aggregate reality', () {
    final range = DateRange(
      DateTime(2026, 7, 19),
      DateTime(2026, 7, 20),
    );
    final previous = DateRange(
      DateTime(2026, 7, 18),
      DateTime(2026, 7, 19),
    );
    final entry = TimeEntry(
      id: 'e1',
      activityId: coding.id,
      startTime: DateTime(2026, 7, 18, 23),
      endTime: DateTime(2026, 7, 19, 2),
      createdAt: created,
      updatedAt: created,
    );

    final result = const StatisticsCalculator().calculate(
      range: range,
      previous: previous,
      currentEntries: <TimeEntry>[entry],
      previousEntries: const <TimeEntry>[],
      categories: <TimiqCategory>[work],
      activities: <TimiqActivity>[coding],
      now: DateTime(2026, 7, 20),
    );

    expect(result.total, const Duration(hours: 2));
    expect(result.categories.single.duration, const Duration(hours: 2));
    expect(result.activities.single.duration, const Duration(hours: 2));
  });

  test('timeline inserts only the real gap between entries', () {
    EntryDetails details(String id, int startHour, int endHour) {
      final entry = TimeEntry(
        id: id,
        activityId: coding.id,
        startTime: DateTime(2026, 7, 19, startHour),
        endTime: DateTime(2026, 7, 19, endHour),
        createdAt: created,
        updatedAt: created,
      );
      return EntryDetails(entry: entry, activity: coding, category: work);
    }

    final items = const TimelineBuilder().build(
      <EntryDetails>[details('a', 8, 12), details('b', 14, 16)],
      DateRange(DateTime(2026, 7, 19), DateTime(2026, 7, 20)),
      DateTime(2026, 7, 19, 18),
    );

    expect(items, hasLength(3));
    expect(items[1], isA<TimelineGapItem>());
    expect(items[1].start, DateTime(2026, 7, 19, 12));
    expect(items[1].end, DateTime(2026, 7, 19, 14));
  });
}
