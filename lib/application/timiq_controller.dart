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
    required TimiqRepository repository,
    PlatformBridge platformBridge = const PlatformBridge(),
    DateTime Function()? clock,
  })  : _repository = repository,
        _platformBridge = platformBridge,
        _clock = clock ?? DateTime.now;

  final TimiqRepository _repository;
  final PlatformBridge _platformBridge;
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
  List<TimiqTag> tags = const <TimiqTag>[];
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

  TimiqTag? tagById(String id) {
    for (final tag in tags) {
      if (tag.id == id) return tag;
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
      tags: entry.tagIds
          .map(tagById)
          .whereType<TimiqTag>()
          .toList(growable: false),
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
    final byCategory = <String, List<ActivityTotal>>{};
    for (final item in activityDeck) {
      if (item.trackedToday == Duration.zero) continue;
      byCategory.putIfAbsent(item.category.id, () => <ActivityTotal>[]).add(
            ActivityTotal(
              activity: item.activity,
              category: item.category,
              duration: item.trackedToday,
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
      await _repository.initialize();
      settings = await _repository.loadSettings();
      await refresh(notify: false);
      isInitialized = true;
      await _syncPlatform();
    } catch (error) {
      fatalError =
          'TimIQ se nepodařilo bezpečně otevřít. Vaše data nebyla smazána.';
      debugPrint('TimIQ initialization failed: $error');
    }
    notifyListeners();
  }

  Future<void> refresh({bool notify = true}) async {
    categories = await _repository.loadCategories();
    activities = await _repository.loadActivities();
    tags = await _repository.loadTags();
    activeEntry = await _repository.loadActiveEntry();
    recentEntries = await _repository.loadRecentEntries();
    final nowValue = now;
    todayEntries = await _repository.loadEntries(
      DateRange(startOfDay(nowValue), endOfDay(nowValue)),
    );
    revision++;
    if (notify) notifyListeners();
  }

  Future<void> refreshAfterResume() async {
    try {
      await refresh();
      await _syncPlatform();
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
      await _repository.saveSettings(settings);
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
      await _repository.saveCategory(
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
        await _repository.saveActivity(
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

  Future<void> saveCategory(TimiqCategory category) =>
      _runMutation(() => _repository.saveCategory(category));

  Future<void> archiveCategory(TimiqCategory category, bool archived) {
    return _runMutation(() async {
      if (archived) {
        final children = activities
            .where((activity) => activity.categoryId == category.id)
            .toList(growable: false);
        if (children.any((item) => item.id == activeEntry?.activityId)) {
          await _repository.stopActivity(now);
        }
      }
      await _repository.saveCategory(
        category.copyWith(isArchived: archived, updatedAt: now),
      );
    });
  }

  Future<void> reorderCategoryIds(List<String> ids) =>
      _runMutation(() => _repository.reorderCategories(ids));

  Future<void> saveActivity(TimiqActivity activity) =>
      _runMutation(() => _repository.saveActivity(activity));

  Future<void> archiveActivity(TimiqActivity activity, bool archived) {
    return _runMutation(() async {
      if (archived && activeEntry?.activityId == activity.id) {
        await _repository.stopActivity(now);
      }
      await _repository.saveActivity(
        activity.copyWith(isArchived: archived, updatedAt: now),
      );
    });
  }

  Future<void> toggleFavorite(TimiqActivity activity) => _runMutation(
        () => _repository.saveActivity(
          activity.copyWith(
            isFavorite: !activity.isFavorite,
            updatedAt: now,
          ),
        ),
      );

  Future<void> reorderActivityIds(List<String> ids) =>
      _runMutation(() => _repository.reorderActivities(ids));

  Future<void> saveTag(TimiqTag tag) async {
    final trimmed = tag.name.trim();
    if (trimmed.isEmpty) {
      throw const TimiqValidationException('Název štítku nesmí být prázdný.');
    }
    final duplicate = tags.any(
      (item) =>
          item.id != tag.id &&
          item.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      throw const TimiqValidationException(
        'Štítek s tímto názvem už existuje.',
      );
    }
    await _runMutation(
      () => _repository.saveTag(
        TimiqTag(id: tag.id, name: trimmed, createdAt: tag.createdAt),
      ),
    );
  }

  Future<void> deleteTag(String id) =>
      _runMutation(() => _repository.deleteTag(id));

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
        await _repository.startActivity(activityId, now);
      } else {
        await _repository.switchActivity(activityId, now);
      }
      await _platformBridge.requestNotificationPermission();
    });
  }

  Future<void> stop() => _runMutation(() async {
        await _repository.stopActivity(now);
      });

  Future<List<OverlapConflict>> findConflicts(
    DateTime start,
    DateTime end, {
    String? excludingId,
  }) =>
      _repository.findConflicts(start, end, excludingId: excludingId);

  Future<void> saveEntry(TimeEntry entry) =>
      _runMutation(() => _repository.saveEntry(entry));

  Future<void> deleteEntry(String id) =>
      _runMutation(() => _repository.deleteEntry(id));

  Future<List<EntryDetails>> entriesForDay(DateTime day) async {
    final entries = await _repository.loadEntries(
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
    final currentEntries = await _repository.loadEntries(range);
    final previousEntries = await _repository.loadEntries(previous);
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
    await _repository.saveSettings(updated);
    settings = updated;
    revision++;
    notifyListeners();
  }

  Future<void> exportCsv() async {
    final data = await _repository.exportAll();
    final rawEntries =
        (data['timeEntries']! as List).cast<Map<String, Object?>>();
    final buffer = StringBuffer()
      ..writeln(
        'id,activity_id,start_time,end_time,duration_seconds,note',
      );
    for (final row in rawEntries) {
      final start =
          DateTime.fromMillisecondsSinceEpoch(row['start_time']! as int);
      final end = row['end_time'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['end_time']! as int);
      final duration = (end ?? now).difference(start).inSeconds;
      buffer.writeln(<String>[
        csvEscape(row['id']! as String),
        csvEscape(row['activity_id']! as String),
        csvEscape(start.toIso8601String()),
        csvEscape(end?.toIso8601String() ?? ''),
        duration.toString(),
        csvEscape((row['note'] as String?) ?? ''),
      ].join(','));
    }
    await _shareFile('timiq-time-entries.csv', buffer.toString(), 'text/csv');
  }

  Future<void> exportJsonBackup() async {
    final data = await _repository.exportAll();
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
      await _syncPlatform();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _syncPlatform() => _platformBridge.sync(
        active: activeDetails,
        favorites: favoriteActivities,
      );
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
