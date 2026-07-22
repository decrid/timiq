import 'package:timiq/core/utils/time_utils.dart';
import 'package:timiq/data/timiq_repository.dart';
import 'package:timiq/domain/models.dart';
import 'package:timiq/platform/platform_bridge.dart';

class NoopPlatformBridge extends PlatformBridge {
  const NoopPlatformBridge();

  @override
  Future<void> requestNotificationPermission() async {}

  @override
  Future<void> sync({
    required EntryDetails? active,
    required List<ActivityDetails> favorites,
  }) async {}

  @override
  Future<void> resetPlatform() async {}
}

class MemoryTimiqRepository implements TimiqRepository {
  final List<TimiqCategory> categories = <TimiqCategory>[];
  final List<TimiqActivity> activities = <TimiqActivity>[];
  final List<TimeEntry> entries = <TimeEntry>[];
  AppSettings settings = const AppSettings(onboardingCompleted: true);

  @override
  Future<void> initialize() async {}

  @override
  Future<List<TimiqCategory>> loadCategories({
    bool includeArchived = true,
  }) async =>
      categories
          .where((item) => includeArchived || !item.isArchived)
          .toList();

  @override
  Future<List<TimiqActivity>> loadActivities({
    bool includeArchived = true,
  }) async =>
      activities
          .where((item) => includeArchived || !item.isArchived)
          .toList(growable: false);

  @override
  Future<TimeEntry?> loadActiveEntry() async {
    final active = entries.where((item) => item.endTime == null);
    return active.isEmpty ? null : active.single;
  }

  @override
  Future<List<TimeEntry>> loadEntries(DateRange range) async => entries
      .where(
        (item) =>
            item.startTime.isBefore(range.end) &&
            (item.endTime == null || item.endTime!.isAfter(range.start)),
      )
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  @override
  Future<List<TimeEntry>> loadRecentEntries({int limit = 30}) async {
    final result = List<TimeEntry>.of(entries)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return result.take(limit).toList(growable: false);
  }

  @override
  Future<List<OverlapConflict>> findConflicts(
    DateTime start,
    DateTime end, {
    String? excludingId,
  }) async =>
      entries
          .where(
            (item) =>
                item.id != excludingId &&
                entriesOverlap(
                  start,
                  end,
                  item.startTime,
                  item.endTime ?? DateTime(9999),
                ),
          )
          .map(OverlapConflict.new)
          .toList(growable: false);

  @override
  Future<void> saveCategory(TimiqCategory category) async {
    categories.removeWhere((item) => item.id == category.id);
    categories.add(category);
  }

  @override
  Future<void> saveActivity(TimiqActivity activity) async {
    activities.removeWhere((item) => item.id == activity.id);
    activities.add(activity);
  }

  @override
  Future<void> reorderCategories(List<String> ids) async {
    for (var index = 0; index < ids.length; index++) {
      final item = categories.firstWhere((item) => item.id == ids[index]);
      categories[categories.indexOf(item)] = item.copyWith(sortOrder: index);
    }
  }

  @override
  Future<void> reorderActivities(List<String> ids) async {
    for (var index = 0; index < ids.length; index++) {
      final item = activities.firstWhere((item) => item.id == ids[index]);
      activities[activities.indexOf(item)] =
          item.copyWith(sortOrder: index);
    }
  }

  @override
  Future<TimeEntry> startActivity(String activityId, DateTime at) async {
    if (entries.any((item) => item.endTime == null)) {
      throw const TimiqValidationException('Timer už běží.');
    }
    final entry = TimeEntry(
      id: newId('entry'),
      activityId: activityId,
      startTime: at,
      createdAt: at,
      updatedAt: at,
    );
    entries.add(entry);
    return entry;
  }

  @override
  Future<TimeEntry?> stopActivity(DateTime at) async {
    final active = await loadActiveEntry();
    if (active == null) return null;
    final stopped = active.copyWith(endTime: at, updatedAt: at);
    entries[entries.indexOf(active)] = stopped;
    return stopped;
  }

  @override
  Future<TimeEntry> switchActivity(String activityId, DateTime at) async {
    final active = await loadActiveEntry();
    if (active != null) {
      entries[entries.indexOf(active)] =
          active.copyWith(endTime: at, updatedAt: at);
    }
    return startActivity(activityId, at);
  }

  @override
  Future<void> saveEntry(TimeEntry entry) async {
    final end = entry.endTime;
    if (end == null) throw const TimiqValidationException('Chybí konec.');
    if ((await findConflicts(
      entry.startTime,
      end,
      excludingId: entry.id,
    ))
        .isNotEmpty) {
      throw const TimiqValidationException('Překryv.');
    }
    entries.removeWhere((item) => item.id == entry.id);
    entries.add(entry);
  }

  @override
  Future<void> deleteEntry(String id) async {
    entries.removeWhere((item) => item.id == id);
  }

  @override
  Future<AppSettings> loadSettings() async => settings;

  @override
  Future<void> saveSettings(AppSettings value) async {
    settings = value;
  }

  @override
  Future<void> resetAll() async {
    entries.clear();
    activities.clear();
    categories.clear();
    settings = const AppSettings(onboardingCompleted: false);
  }

  @override
  Future<Map<String, Object?>> exportAll() async => <String, Object?>{
        'categories': <Object?>[],
        'activities': <Object?>[],
        'timeEntries': <Object?>[],
        'settings': <Object?>[],
      };
}
