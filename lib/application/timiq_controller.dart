import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/time_utils.dart';
import '../data/timiq_repository.dart';
import '../domain/analytics.dart';
import '../domain/models.dart';
import '../platform/platform_bridge.dart';

class TimiqController extends ChangeNotifier {
  TimiqController({
    required this.repository,
    this.platformBridge = const PlatformBridge(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final TimiqRepository repository;
  final PlatformBridge platformBridge;
  final DateTime Function() _clock;
  final StatisticsCalculator _statisticsCalculator =
      const StatisticsCalculator();

  bool isInitialized = false;
  bool isBusy = false;
  int revision = 0;
  String? fatalError;
  AppSettings settings = const AppSettings();
  List<TimiqCategory> categories = const <TimiqCategory>[];
  List<TimiqActivity> activities = const <TimiqActivity>[];
  List<TimeEntry> todayEntries = const <TimeEntry>[];
  List<TimeEntry> recentEntries = const <TimeEntry>[];
  TimeEntry? activeEntry;

  DateTime get now => _clock();

  List<TimiqCategory> get activeCategories =>
      categories.where((item) => !item.isArchived).toList(growable: false);

  List<TimiqActivity> get activeActivities => activities
      .where(
        (item) =>
            !item.isArchived &&
            (categoryById(item.categoryId)?.isArchived == false),
      )
      .toList(growable: false);

  TimiqCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  TimiqActivity? activityById(String id) {
    for (final activity in activities) {
      if (activity.id == id) return activity;
    }
    return null;
  }

  EntryDetails? get activeDetails {
    final entry = activeEntry;
    if (entry == null) return null;
    return detailsForEntry(entry);
  }

  EntryDetails? detailsForEntry(TimeEntry entry) {
    final activity = activityById(entry.activityId);
    if (activity == null) return null;
    final category = categoryById(activity.categoryId);
    if (category == null) return null;
    return EntryDetails(
      entry: entry,
      activity: activity,
      category: category,
    );
  }

  List<ActivityDetails> get activityDeck {
    final nowValue = now;
    final todayRange = DateRange(startOfDay(nowValue), endOfDay(nowValue));
    final recentUse = <String, DateTime>{};
    for (final entry in recentEntries) {
      recentUse.putIfAbsent(entry.activityId, () => entry.startTime);
    }
    final result = <ActivityDetails>[];
    for (final activity in activeActivities) {
      final category = categoryById(activity.categoryId);
      if (category == null) continue;
      var total = Duration.zero;
      for (final entry in todayEntries) {
        if (entry.activityId != activity.id) continue;
        total += clippedDuration(
          entry.startTime,
          entry.endTime,
          todayRange,
          nowValue,
        );
      }
      result.add(
        ActivityDetails(
          activity: activity,
          category: category,
          lastUsedAt: recentUse[activity.id],
          trackedToday: total,
        ),
      );
    }
    result.sort((a, b) {
      if (a.activity.isFavorite != b.activity.isFavorite) {
        return a.activity.isFavorite ? -1 : 1;
      }
      final aRecent = a.lastUsedAt;
      final bRecent = b.lastUsedAt;
      if (aRecent != null || bRecent != null) {
        if (aRecent == null) return 1;
        if (bRecent == null) return -1;
        final comparison = bRecent.compareTo(aRecent);
        if (comparison != 0) return comparison;
      }
      return a.activity.sortOrder.compareTo(b.activity.sortOrder);
    });
    return result;
  }

  List<ActivityDetails> get favoriteActivities => activityDeck
      .where((item) => item.activity.isFavorite)
      .toList(growable: false);

  Duration get todayTotal {
    final nowValue = now;
    final range = DateRange(startOfDay(nowValue), endOfDay(nowValue));
    return todayEntries.fold(
      Duration.zero,
      (sum, entry) =>
          sum +
          clippedDuration(
            entry.startTime,
            entry.endTime,
            range,
            nowValue,
          ),
    );
  }

  List<CategoryTotal> get todayCategoryTotals {
    final nowValue = now;
    final range = DateRange(startOfDay(nowValue), endOfDay(nowValue));
    final byActivity = <String, Duration>{};
    for (final entry in todayEntries) {
      final duration = clippedDuration(
        entry.startTime,
        entry.endTime,
        range,
        nowValue,
      );
      if (duration == Duration.zero) continue;
      byActivity[entry.activityId] =
          (byActivity[entry.activityId] ?? Duration.zero) + duration;
    }
    final byCategory = <String, List<ActivityTotal>>{};
    for (final item in byActivity.entries) {
      final activity = activityById(item.key);
      if (activity == null) continue;
      final category = categoryById(activity.categoryId);
      if (category == null) continue;
      byCategory.putIfAbsent(category.id, () => <ActivityTotal>[]).add(
            ActivityTotal(
              activity: activity,
              category: category,
              duration: item.value,
            ),
          );
    }
    final result = <CategoryTotal>[];
    for (final item in byCategory.entries) {
      final category = categoryById(item.key);
      if (category == null) continue;
      final activities = item.value
        ..sort((a, b) => b.duration.compareTo(a.duration));
      result.add(
        CategoryTotal(
          category: category,
          duration: activities.fold(
            Duration.zero,
            (sum, activity) => sum + activity.duration,
          ),
          activities: activities,
        ),
      );
    }
    result.sort((a, b) => b.duration.compareTo(a.duration));
    return result;
  }

  Future<void> initialize() async {
    try {
      await repository.initialize();
      settings = await repository.loadSettings();
      await refresh(notify: false);
      isInitialized = true;
      await _syncPlatformBestEffort();
    } catch (error) {
      fatalError =
          'TimIQ se nepodařilo bezpečně otevřít. Vaše data nebyla smazána.';
      debugPrint('TimIQ initialization failed: $error');
    }
    notifyListeners();
  }

  Future<void> refresh({bool notify = true}) async {
    categories = await repository.loadCategories();
    activities = await repository.loadActivities();
    activeEntry = await repository.loadActiveEntry();
    recentEntries = await repository.loadRecentEntries();
    final nowValue = now;
    todayEntries = await repository.loadEntries(
      DateRange(startOfDay(nowValue), endOfDay(nowValue)),
    );
    revision++;
    if (notify) notifyListeners();
  }

  Future<void> refreshAfterResume() async {
    try {
      await refresh();
      await _syncPlatformBestEffort();
    } catch (error) {
      debugPrint('TimIQ resume refresh failed: $error');
    }
  }

  Future<void> completeOnboarding({required bool useStarterSet}) async {
    await _runMutation(() async {
      if (useStarterSet && categories.isEmpty) {
        await _createStarterSet();
      }
      settings = settings.copyWith(onboardingCompleted: true);
      await repository.saveSettings(settings);
    });
  }

  Future<void> _createStarterSet() async {
    final createdAt = now;
    final definitions = <({
      String category,
      int color,
      int icon,
      List<String> activities,
    })>[
      (
        category: 'Práce',
        color: 0xFF4D8DFF,
        icon: Icons.work_outline.codePoint,
        activities: <String>['Soustředěná práce', 'Schůzky'],
      ),
      (
        category: 'Rodina',
        color: 0xFFFF9F43,
        icon: Icons.family_restroom.codePoint,
        activities: <String>['Společný čas'],
      ),
      (
        category: 'Projekty',
        color: 0xFF9A8CFF,
        icon: Icons.rocket_launch_outlined.codePoint,
        activities: <String>['Osobní projekt'],
      ),
      (
        category: 'Dům',
        color: 0xFF4DD6A0,
        icon: Icons.home_outlined.codePoint,
        activities: <String>['Domácnost'],
      ),
      (
        category: 'Volný čas',
        color: 0xFFFF6FAE,
        icon: Icons.sports_esports_outlined.codePoint,
        activities: <String>['Odpočinek'],
      ),
      (
        category: 'Spánek',
        color: 0xFF6C7CFF,
        icon: Icons.bedtime_outlined.codePoint,
        activities: <String>['Spánek'],
      ),
    ];
    for (var categoryIndex = 0;
        categoryIndex < definitions.length;
        categoryIndex++) {
      final definition = definitions[categoryIndex];
      final categoryId = newId('category');
      await repository.saveCategory(
        TimiqCategory(
          id: categoryId,
          name: definition.category,
          colorValue: definition.color,
          iconCodePoint: definition.icon,
          sortOrder: categoryIndex,
          isArchived: false,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      for (var activityIndex = 0;
          activityIndex < definition.activities.length;
          activityIndex++) {
        await repository.saveActivity(
          TimiqActivity(
            id: newId('activity'),
            categoryId: categoryId,
            name: definition.activities[activityIndex],
            iconCodePoint: definition.icon,
            isFavorite: activityIndex == 0,
            sortOrder: activityIndex,
            isArchived: false,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
      }
    }
  }

  Future<void> saveCategory(TimiqCategory category) async {
    final name = category.name.trim();
    if (name.isEmpty) {
      throw const TimiqValidationException(
        'Název kategorie nesmí být prázdný.',
      );
    }
    await _runMutation(
      () => repository.saveCategory(category.copyWith(name: name)),
    );
  }

  Future<void> archiveCategory(TimiqCategory category, bool archived) {
    return _runMutation(() async {
      if (archived) {
        final children = activities
            .where((activity) => activity.categoryId == category.id)
            .toList(growable: false);
        if (children.any((item) => item.id == activeEntry?.activityId)) {
          await repository.stopActivity(now);
        }
      }
      final restoredOrder = archived
          ? category.sortOrder
          : activeCategories.fold<int>(
              -1,
              (maximum, item) =>
                  item.sortOrder > maximum ? item.sortOrder : maximum,
            ) +
              1;
      await repository.saveCategory(category.copyWith(
        isArchived: archived,
        sortOrder: restoredOrder,
        updatedAt: now,
      ));
    });
  }

  Future<void> reorderCategoryIds(List<String> ids) =>
      _runMutation(() => repository.reorderCategories(ids));

  Future<void> saveActivity(TimiqActivity activity) async {
    final name = activity.name.trim();
    if (name.isEmpty) {
      throw const TimiqValidationException(
        'Název aktivity nesmí být prázdný.',
      );
    }
    final category = categoryById(activity.categoryId);
    if (category == null || category.isArchived) {
      throw const TimiqValidationException(
        'Vybraná kategorie není dostupná.',
      );
    }
    await _runMutation(
      () => repository.saveActivity(activity.copyWith(name: name)),
    );
  }

  Future<void> archiveActivity(TimiqActivity activity, bool archived) {
    return _runMutation(() async {
      if (archived && activeEntry?.activityId == activity.id) {
        await repository.stopActivity(now);
      }
      final restoredOrder = archived
          ? activity.sortOrder
          : activeActivities.fold<int>(
                -1,
                (maximum, item) =>
                    item.sortOrder > maximum ? item.sortOrder : maximum,
              ) +
              1;
      await repository.saveActivity(activity.copyWith(
        isArchived: archived,
        sortOrder: restoredOrder,
        updatedAt: now,
      ));
    });
  }

  Future<void> toggleFavorite(TimiqActivity activity) => _runMutation(
        () => repository.saveActivity(
          activity.copyWith(
            isFavorite: !activity.isFavorite,
            updatedAt: now,
          ),
        ),
      );

  Future<void> reorderActivityIds(List<String> ids) =>
      _runMutation(() => repository.reorderActivities(ids));

  Future<void> startOrSwitch(String activityId) async {
    final activity = activityById(activityId);
    if (activity == null ||
        activity.isArchived ||
        categoryById(activity.categoryId)?.isArchived != false) {
      throw const TimiqValidationException('Tato aktivita není dostupná.');
    }
    if (activeEntry?.activityId == activityId) return;
    await _runMutation(() async {
      if (activeEntry == null) {
        await repository.startActivity(activityId, now);
      } else {
        await repository.switchActivity(activityId, now);
      }
    });
    await _requestNotificationPermissionBestEffort();
  }

  Future<void> stop() => _runMutation(() async {
        await repository.stopActivity(now);
      });

  Future<List<OverlapConflict>> findConflicts(
    DateTime start,
    DateTime end, {
    String? excludingId,
  }) =>
      repository.findConflicts(start, end, excludingId: excludingId);

  Future<void> saveEntry(TimeEntry entry) async {
    if (activityById(entry.activityId) == null) {
      throw const TimiqValidationException('Vybraná aktivita neexistuje.');
    }
    final end = entry.endTime;
    if (end != null && end.isAfter(now)) {
      throw const TimiqValidationException(
        'Konec záznamu nesmí být v budoucnosti.',
      );
    }
    await _runMutation(() => repository.saveEntry(entry));
  }

  Future<void> deleteEntry(String id) =>
      _runMutation(() => repository.deleteEntry(id));

  Future<List<EntryDetails>> entriesForDay(DateTime day) async {
    final entries = await repository.loadEntries(
      DateRange(startOfDay(day), endOfDay(day)),
    );
    return entries.map(detailsForEntry).whereType<EntryDetails>().toList();
  }

  Future<StatisticsSnapshot> statistics(
    StatisticsPeriod period,
    DateTime anchor, {
    DateRange? custom,
  }) async {
    final range = rangeForPeriod(
      period,
      anchor,
      settings.firstDayOfWeek,
      custom: custom,
    );
    final previous = previousRangeForPeriod(
      period,
      anchor,
      settings.firstDayOfWeek,
      custom: custom,
    );
    final currentEntries = await repository.loadEntries(range);
    final previousEntries = await repository.loadEntries(previous);
    return _statisticsCalculator.calculate(
      range: range,
      previous: previous,
      currentEntries: currentEntries,
      previousEntries: previousEntries,
      categories: categories,
      activities: activities,
      now: now,
    );
  }

  Future<void> updateSettings(AppSettings updated) async {
    await repository.saveSettings(updated);
    settings = updated;
    revision++;
    notifyListeners();
  }

  Future<void> resetApplication() async {
    isBusy = true;
    notifyListeners();
    try {
      await repository.resetAll();
      settings = const AppSettings(onboardingCompleted: false);
      categories = const <TimiqCategory>[];
      activities = const <TimiqActivity>[];
      todayEntries = const <TimeEntry>[];
      recentEntries = const <TimeEntry>[];
      activeEntry = null;
      revision++;
      await _resetPlatformBestEffort();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> exportCsv() async {
    final data = await repository.exportAll();
    await _shareFile(
      'timiq-time-entries.csv',
      buildCsvExport(data, now),
      'text/csv',
    );
  }

  Future<void> exportJsonBackup() async {
    final data = await repository.exportAll();
    await _shareFile(
      'timiq-backup.json',
      prettyJson(data),
      'application/json',
    );
  }

  Future<void> _shareFile(
    String name,
    String contents,
    String mimeType,
  ) async {
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, name));
    await file.writeAsString(contents, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Export TimIQ',
        text: 'Vaše data z TimIQ',
        files: <XFile>[XFile(file.path, mimeType: mimeType)],
      ),
    );
  }

  Future<void> _runMutation(Future<void> Function() operation) async {
    isBusy = true;
    notifyListeners();
    try {
      await operation();
      await refresh(notify: false);
      await _syncPlatformBestEffort();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _syncPlatform() => platformBridge.sync(
        active: activeDetails,
        favorites: favoriteActivities,
      );

  Future<void> _syncPlatformBestEffort() async {
    try {
      await _syncPlatform();
    } catch (error, stackTrace) {
      debugPrint('TimIQ Android surface sync failed: $error\n$stackTrace');
    }
  }

  Future<void> _requestNotificationPermissionBestEffort() async {
    try {
      await platformBridge.requestNotificationPermission();
    } catch (error, stackTrace) {
      debugPrint(
        'TimIQ notification permission request failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> _resetPlatformBestEffort() async {
    try {
      await platformBridge.resetPlatform();
    } catch (error, stackTrace) {
      debugPrint('TimIQ Android surface reset failed: $error\n$stackTrace');
    }
  }
}

String buildCsvExport(Map<String, Object?> data, DateTime now) {
  final rawEntries =
      (data['timeEntries']! as List).cast<Map<String, Object?>>();
  final rawActivities =
      (data['activities']! as List).cast<Map<String, Object?>>();
  final rawCategories =
      (data['categories']! as List).cast<Map<String, Object?>>();
  final activityById = <String, Map<String, Object?>>{
    for (final row in rawActivities) row['id']! as String: row,
  };
  final categoryById = <String, Map<String, Object?>>{
    for (final row in rawCategories) row['id']! as String: row,
  };
  final buffer = StringBuffer('\uFEFF')
    ..writeln(
      'id,activity_id,activity_name,category_name,start_time,end_time,'
      'duration_seconds,note',
    );
  for (final row in rawEntries) {
    final activity = activityById[row['activity_id']];
    final category = activity == null
        ? null
        : categoryById[activity['category_id']];
    final start =
        DateTime.fromMillisecondsSinceEpoch(row['start_time']! as int);
    final end = row['end_time'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['end_time']! as int);
    final duration = (end ?? now).difference(start);
    buffer.writeln(<String>[
      csvEscape(row['id']! as String),
      csvEscape(row['activity_id']! as String),
      csvEscape((activity?['name'] as String?) ?? ''),
      csvEscape((category?['name'] as String?) ?? ''),
      csvEscape(start.toIso8601String()),
      csvEscape(end?.toIso8601String() ?? ''),
      (duration.isNegative ? Duration.zero : duration).inSeconds.toString(),
      csvEscape((row['note'] as String?) ?? ''),
    ].join(','));
  }
  return buffer.toString();
}

class TimiqScope extends InheritedNotifier<TimiqController> {
  const TimiqScope({
    required TimiqController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static TimiqController of(BuildContext context, {bool listen = true}) {
    if (!listen) {
      final element =
          context.getElementForInheritedWidgetOfExactType<TimiqScope>();
      final scope = element?.widget as TimiqScope?;
      assert(scope != null, 'TimiqScope nebyl nalezen.');
      return scope!.notifier!;
    }
    final scope = context.dependOnInheritedWidgetOfExactType<TimiqScope>();
    assert(scope != null, 'TimiqScope nebyl nalezen.');
    return scope!.notifier!;
  }
}
