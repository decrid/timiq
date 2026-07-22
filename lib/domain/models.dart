import 'dart:ui';

enum FirstDayOfWeek { monday, sunday }

enum TimiqTimeFormat { twentyFourHour, twelveHour }

enum TimiqThemeMode { dark, light, system }

class TimiqCategory {
  const TimiqCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int colorValue;
  final int iconCodePoint;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color get color => Color(colorValue);

  TimiqCategory copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
    int? sortOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimiqCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TimiqActivity {
  const TimiqActivity({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.iconCodePoint,
    required this.isFavorite,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.customColorValue,
  });

  static const Object _unset = Object();

  final String id;
  final String categoryId;
  final String name;
  final int iconCodePoint;
  final int? customColorValue;
  final bool isFavorite;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimiqActivity copyWith({
    String? id,
    String? categoryId,
    String? name,
    int? iconCodePoint,
    Object? customColorValue = _unset,
    bool? isFavorite,
    int? sortOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimiqActivity(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      customColorValue: identical(customColorValue, _unset)
          ? this.customColorValue
          : customColorValue as int?,
      isFavorite: isFavorite ?? this.isFavorite,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.activityId,
    required this.startTime,
    required this.createdAt,
    required this.updatedAt,
    this.endTime,
    this.note = '',
  });

  static const Object _unset = Object();

  final String id;
  final String activityId;
  final DateTime startTime;
  final DateTime? endTime;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRunning => endTime == null;

  Duration durationAt(DateTime now) =>
      (endTime ?? now).difference(startTime).isNegative
          ? Duration.zero
          : (endTime ?? now).difference(startTime);

  TimeEntry copyWith({
    String? id,
    String? activityId,
    DateTime? startTime,
    Object? endTime = _unset,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      startTime: startTime ?? this.startTime,
      endTime: identical(endTime, _unset) ? this.endTime : endTime as DateTime?,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AppSettings {
  const AppSettings({
    this.firstDayOfWeek = FirstDayOfWeek.monday,
    this.timeFormat = TimiqTimeFormat.twentyFourHour,
    this.themeMode = TimiqThemeMode.dark,
    this.onboardingCompleted = false,
  });

  final FirstDayOfWeek firstDayOfWeek;
  final TimiqTimeFormat timeFormat;
  final TimiqThemeMode themeMode;
  final bool onboardingCompleted;

  AppSettings copyWith({
    FirstDayOfWeek? firstDayOfWeek,
    TimiqTimeFormat? timeFormat,
    TimiqThemeMode? themeMode,
    bool? onboardingCompleted,
  }) {
    return AppSettings(
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      timeFormat: timeFormat ?? this.timeFormat,
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

class ActivityDetails {
  const ActivityDetails({
    required this.activity,
    required this.category,
    this.lastUsedAt,
    this.trackedToday = Duration.zero,
  });

  final TimiqActivity activity;
  final TimiqCategory category;
  final DateTime? lastUsedAt;
  final Duration trackedToday;

  Color get color =>
      Color(activity.customColorValue ?? category.colorValue);
}

class EntryDetails {
  const EntryDetails({
    required this.entry,
    required this.activity,
    required this.category,
  });

  final TimeEntry entry;
  final TimiqActivity activity;
  final TimiqCategory category;

  Color get color =>
      Color(activity.customColorValue ?? category.colorValue);
}

class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);
}

enum StatisticsPeriod { day, week, month, year, custom }

class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.duration,
    required this.activities,
  });

  final TimiqCategory category;
  final Duration duration;
  final List<ActivityTotal> activities;
}

class ActivityTotal {
  const ActivityTotal({
    required this.activity,
    required this.category,
    required this.duration,
  });

  final TimiqActivity activity;
  final TimiqCategory category;
  final Duration duration;

  Color get color =>
      Color(activity.customColorValue ?? category.colorValue);
}

class TrendValue {
  const TrendValue({
    required this.category,
    required this.current,
    required this.previous,
  });

  final TimiqCategory category;
  final Duration current;
  final Duration previous;

  double? get percentChange {
    if (previous.inSeconds == 0) return null;
    return ((current.inSeconds - previous.inSeconds) /
            previous.inSeconds) *
        100;
  }
}

class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.range,
    required this.total,
    required this.categories,
    required this.activities,
    required this.trends,
    required this.dailyTotals,
    required this.dailyCategoryTotals,
  });

  final DateRange range;
  final Duration total;
  final List<CategoryTotal> categories;
  final List<ActivityTotal> activities;
  final List<TrendValue> trends;
  final Map<DateTime, Duration> dailyTotals;
  final Map<DateTime, Map<String, Duration>> dailyCategoryTotals;
}

sealed class TimelineItem {
  const TimelineItem(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class TimelineEntryItem extends TimelineItem {
  const TimelineEntryItem(
    super.start,
    super.end, {
    required this.details,
  });

  final EntryDetails details;
}

class TimelineGapItem extends TimelineItem {
  const TimelineGapItem(super.start, super.end);
}

class OverlapConflict {
  const OverlapConflict(this.entry);

  final TimeEntry entry;
}

class TimiqValidationException implements Exception {
  const TimiqValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
