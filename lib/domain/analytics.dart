import '../core/utils/time_utils.dart';
import 'models.dart';

class TimelineBuilder {
  const TimelineBuilder({this.minimumGap = const Duration(minutes: 1)});

  final Duration minimumGap;

  List<TimelineItem> build(
    List<EntryDetails> entries,
    DateRange day,
    DateTime now,
  ) {
    final sorted = [...entries]
      ..sort((a, b) => a.entry.startTime.compareTo(b.entry.startTime));
    final items = <TimelineItem>[];
    DateTime? previousEnd;
    for (final details in sorted) {
      final rawEnd = details.entry.endTime ?? now;
      final visibleStart = details.entry.startTime.isBefore(day.start)
          ? day.start
          : details.entry.startTime;
      final visibleEnd = rawEnd.isAfter(day.end) ? day.end : rawEnd;
      if (!visibleEnd.isAfter(visibleStart)) continue;
      if (previousEnd != null) {
        final gapStart =
            visibleStart.isAfter(previousEnd) ? previousEnd : visibleStart;
        if (visibleStart.difference(gapStart) >= minimumGap) {
          items.add(TimelineGapItem(gapStart, visibleStart));
        }
      }
      items.add(
        TimelineEntryItem(
          visibleStart,
          visibleEnd,
          details: details,
        ),
      );
      if (previousEnd == null || visibleEnd.isAfter(previousEnd)) {
        previousEnd = visibleEnd;
      }
    }
    return items;
  }
}

class StatisticsCalculator {
  const StatisticsCalculator();

  StatisticsSnapshot calculate({
    required DateRange range,
    required DateRange previous,
    required List<TimeEntry> currentEntries,
    required List<TimeEntry> previousEntries,
    required List<TimiqCategory> categories,
    required List<TimiqActivity> activities,
    required DateTime now,
  }) {
    final categoryById = <String, TimiqCategory>{
      for (final category in categories) category.id: category,
    };
    final activityById = <String, TimiqActivity>{
      for (final activity in activities) activity.id: activity,
    };

    final currentByActivity = _aggregateEntries(currentEntries, range, now);
    final previousByActivity =
        _aggregateEntries(previousEntries, previous, now);
    final currentByCategory = <String, Duration>{};
    final previousByCategory = <String, Duration>{};
    final activityTotals = <ActivityTotal>[];

    for (final item in currentByActivity.entries) {
      final activity = activityById[item.key];
      if (activity == null) continue;
      final category = categoryById[activity.categoryId];
      if (category == null) continue;
      activityTotals.add(
        ActivityTotal(
          activity: activity,
          category: category,
          duration: item.value,
        ),
      );
      currentByCategory[category.id] =
          (currentByCategory[category.id] ?? Duration.zero) + item.value;
    }

    for (final item in previousByActivity.entries) {
      final activity = activityById[item.key];
      if (activity == null) continue;
      previousByCategory[activity.categoryId] =
          (previousByCategory[activity.categoryId] ?? Duration.zero) +
              item.value;
    }

    activityTotals.sort((a, b) => b.duration.compareTo(a.duration));
    final categoryTotals = <CategoryTotal>[];
    for (final item in currentByCategory.entries) {
      final category = categoryById[item.key];
      if (category == null) continue;
      final childActivities = activityTotals
          .where((total) => total.category.id == item.key)
          .toList(growable: false);
      categoryTotals.add(
        CategoryTotal(
          category: category,
          duration: item.value,
          activities: childActivities,
        ),
      );
    }
    categoryTotals.sort((a, b) => b.duration.compareTo(a.duration));

    final allTrendCategoryIds = <String>{
      ...currentByCategory.keys,
      ...previousByCategory.keys,
    };
    final trends = <TrendValue>[];
    for (final categoryId in allTrendCategoryIds) {
      final category = categoryById[categoryId];
      if (category == null) continue;
      trends.add(
        TrendValue(
          category: category,
          current: currentByCategory[categoryId] ?? Duration.zero,
          previous: previousByCategory[categoryId] ?? Duration.zero,
        ),
      );
    }
    trends.sort((a, b) {
      final aDelta = (a.current - a.previous).inSeconds.abs();
      final bDelta = (b.current - b.previous).inSeconds.abs();
      return bDelta.compareTo(aDelta);
    });

    final dailyTotals = <DateTime, Duration>{};
    final dailyCategoryTotals = <DateTime, Map<String, Duration>>{};
    var day = startOfDay(range.start);
    while (day.isBefore(range.end)) {
      final dayRange = DateRange(day, addCalendarDays(day, 1));
      var total = Duration.zero;
      final categoryTotalsForDay = <String, Duration>{};
      for (final entry in currentEntries) {
        final duration = clippedDuration(
          entry.startTime,
          entry.endTime,
          dayRange,
          now,
        );
        total += duration;
        final activity = activityById[entry.activityId];
        if (activity != null && duration != Duration.zero) {
          categoryTotalsForDay[activity.categoryId] =
              (categoryTotalsForDay[activity.categoryId] ?? Duration.zero) +
                  duration;
        }
      }
      dailyTotals[day] = total;
      dailyCategoryTotals[day] = categoryTotalsForDay;
      day = addCalendarDays(day, 1);
    }

    final total = currentByActivity.values.fold(
      Duration.zero,
      (sum, item) => sum + item,
    );
    return StatisticsSnapshot(
      range: range,
      total: total,
      categories: categoryTotals,
      activities: activityTotals,
      trends: trends,
      dailyTotals: dailyTotals,
      dailyCategoryTotals: dailyCategoryTotals,
    );
  }

  Map<String, Duration> _aggregateEntries(
    List<TimeEntry> entries,
    DateRange range,
    DateTime now,
  ) {
    final totals = <String, Duration>{};
    for (final entry in entries) {
      final duration = clippedDuration(
        entry.startTime,
        entry.endTime,
        range,
        now,
      );
      if (duration == Duration.zero) continue;
      totals[entry.activityId] =
          (totals[entry.activityId] ?? Duration.zero) + duration;
    }
    return totals;
  }
}
