import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../core/utils/time_utils.dart';
import '../domain/models.dart';
import 'app_database.dart';

abstract interface class TimiqRepository {
  Future<void> initialize();
  Future<List<TimiqCategory>> loadCategories({bool includeArchived = true});
  Future<List<TimiqActivity>> loadActivities({bool includeArchived = true});
  Future<List<TimiqTag>> loadTags();
  Future<TimeEntry?> loadActiveEntry();
  Future<List<TimeEntry>> loadEntries(DateRange range);
  Future<List<TimeEntry>> loadRecentEntries({int limit = 30});
  Future<List<OverlapConflict>> findConflicts(
    DateTime start,
    DateTime end, {
    String? excludingId,
  });
  Future<void> saveCategory(TimiqCategory category);
  Future<void> saveActivity(TimiqActivity activity);
  Future<void> reorderCategories(List<String> ids);
  Future<void> reorderActivities(List<String> ids);
  Future<void> saveTag(TimiqTag tag);
  Future<void> deleteTag(String id);
  Future<TimeEntry> startActivity(String activityId, DateTime at);
  Future<TimeEntry?> stopActivity(DateTime at);
  Future<TimeEntry> switchActivity(String activityId, DateTime at);
  Future<void> saveEntry(TimeEntry entry);
  Future<void> deleteEntry(String id);
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<Map<String, Object?>> exportAll();
}

class SqliteTimiqRepository implements TimiqRepository {
  Database? _db;

  Database get _database {
    final db = _db;
    if (db == null) throw StateError('Databáze není inicializovaná.');
    return db;
  }

  @override
  Future<void> initialize() async {
    _db = await AppDatabase.open();
  }

  @override
  Future<List<TimiqCategory>> loadCategories({
    bool includeArchived = true,
  }) async {
    final rows = await _database.query(
      'categories',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(_categoryFromMap).toList(growable: false);
  }

  @override
  Future<List<TimiqActivity>> loadActivities({
    bool includeArchived = true,
  }) async {
    final rows = await _database.query(
      'activities',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(_activityFromMap).toList(growable: false);
  }

  @override
  Future<List<TimiqTag>> loadTags() async {
    final rows = await _database.query('tags', orderBy: 'name COLLATE NOCASE');
    return rows.map(_tagFromMap).toList(growable: false);
  }

  @override
  Future<TimeEntry?> loadActiveEntry() async {
    final rows = await _database.query(
      'time_entries',
      where: 'end_time IS NULL',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (await _entriesWithTags(rows)).single;
  }

  @override
  Future<List<TimeEntry>> loadEntries(DateRange range) async {
    final rows = await _database.query(
      'time_entries',
      where:
          'start_time < ? AND (end_time IS NULL OR end_time > ?)',
      whereArgs: <Object>[
        range.end.millisecondsSinceEpoch,
        range.start.millisecondsSinceEpoch,
      ],
      orderBy: 'start_time ASC',
    );
    return _entriesWithTags(rows);
  }

  @override
  Future<List<TimeEntry>> loadRecentEntries({int limit = 30}) async {
    final rows = await _database.query(
      'time_entries',
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return _entriesWithTags(rows);
  }

  @override
  Future<List<OverlapConflict>> findConflicts(
    DateTime start,
    DateTime end, {
    String? excludingId,
  }) async {
    final rows = await _conflictRows(
      _database,
      start,
      end,
      excludingId: excludingId,
    );
    final entries = rows.map(_entryFromMap).toList(growable: false);
    return entries.map(OverlapConflict.new).toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _conflictRows(
    DatabaseExecutor executor,
    DateTime start,
    DateTime end, {
    String? excludingId,
  }) {
    final clauses = <String>[
      'start_time < ?',
      '(end_time IS NULL OR end_time > ?)',
    ];
    final args = <Object>[
      end.millisecondsSinceEpoch,
      start.millisecondsSinceEpoch,
    ];
    if (excludingId != null) {
      clauses.add('id != ?');
      args.add(excludingId);
    }
    return executor.query(
      'time_entries',
      where: clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'start_time ASC',
    );
  }

  @override
  Future<void> saveCategory(TimiqCategory category) async {
    final values = _categoryToMap(category);
    final updated = await _database.update(
      'categories',
      values,
      where: 'id = ?',
      whereArgs: <Object>[category.id],
    );
    if (updated == 0) {
      await _database.insert('categories', values);
    }
  }

  @override
  Future<void> saveActivity(TimiqActivity activity) async {
    final values = _activityToMap(activity);
    final updated = await _database.update(
      'activities',
      values,
      where: 'id = ?',
      whereArgs: <Object>[activity.id],
    );
    if (updated == 0) {
      await _database.insert('activities', values);
    }
  }

  @override
  Future<void> reorderCategories(List<String> ids) async {
    await _database.transaction((txn) async {
      for (var index = 0; index < ids.length; index++) {
        await txn.update(
          'categories',
          <String, Object?>{
            'sort_order': index,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: <Object>[ids[index]],
        );
      }
    });
  }

  @override
  Future<void> reorderActivities(List<String> ids) async {
    await _database.transaction((txn) async {
      for (var index = 0; index < ids.length; index++) {
        await txn.update(
          'activities',
          <String, Object?>{
            'sort_order': index,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: <Object>[ids[index]],
        );
      }
    });
  }

  @override
  Future<void> saveTag(TimiqTag tag) async {
    final values = _tagToMap(tag);
    final updated = await _database.update(
      'tags',
      values,
      where: 'id = ?',
      whereArgs: <Object>[tag.id],
    );
    if (updated == 0) await _database.insert('tags', values);
  }

  @override
  Future<void> deleteTag(String id) async {
    await _database.delete(
      'tags',
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  @override
  Future<TimeEntry> startActivity(String activityId, DateTime at) async {
    return _database.transaction((txn) async {
      final active = await txn.query(
        'time_entries',
        where: 'end_time IS NULL',
        limit: 1,
      );
      if (active.isNotEmpty) {
        throw const TimiqValidationException(
          'Jiná aktivita už běží. Použijte přepnutí aktivity.',
        );
      }
      return _insertRunning(txn, activityId, at);
    });
  }

  @override
  Future<TimeEntry?> stopActivity(DateTime at) async {
    return _database.transaction((txn) async {
      final rows = await txn.query(
        'time_entries',
        where: 'end_time IS NULL',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final running = _entryFromMap(rows.first);
      final safeEnd = at.isAfter(running.startTime)
          ? at
          : running.startTime.add(const Duration(milliseconds: 1));
      await txn.update(
        'time_entries',
        <String, Object?>{
          'end_time': safeEnd.millisecondsSinceEpoch,
          'updated_at': safeEnd.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: <Object>[running.id],
      );
      return running.copyWith(endTime: safeEnd, updatedAt: safeEnd);
    });
  }

  @override
  Future<TimeEntry> switchActivity(String activityId, DateTime at) async {
    return _database.transaction((txn) async {
      final rows = await txn.query(
        'time_entries',
        where: 'end_time IS NULL',
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final running = _entryFromMap(rows.first);
        if (running.activityId == activityId) return running;
        final switchAt = at.isAfter(running.startTime)
            ? at
            : running.startTime.add(const Duration(milliseconds: 1));
        await txn.update(
          'time_entries',
          <String, Object?>{
            'end_time': switchAt.millisecondsSinceEpoch,
            'updated_at': switchAt.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: <Object>[running.id],
        );
        return _insertRunning(txn, activityId, switchAt);
      }
      return _insertRunning(txn, activityId, at);
    });
  }

  Future<TimeEntry> _insertRunning(
    DatabaseExecutor executor,
    String activityId,
    DateTime at,
  ) async {
    final entry = TimeEntry(
      id: newId('entry'),
      activityId: activityId,
      startTime: at,
      createdAt: at,
      updatedAt: at,
    );
    await executor.insert('time_entries', _entryToMap(entry));
    return entry;
  }

  @override
  Future<void> saveEntry(TimeEntry entry) async {
    final end = entry.endTime;
    if (end == null || !end.isAfter(entry.startTime)) {
      throw const TimiqValidationException(
        'Konec záznamu musí být později než začátek.',
      );
    }
    await _database.transaction((txn) async {
      final activity = await txn.query(
        'activities',
        columns: const <String>['id'],
        where: 'id = ?',
        whereArgs: <Object>[entry.activityId],
        limit: 1,
      );
      if (activity.isEmpty) {
        throw const TimiqValidationException(
          'Vybraná aktivita neexistuje.',
        );
      }
      final conflicts = await _conflictRows(
        txn,
        entry.startTime,
        end,
        excludingId: entry.id,
      );
      if (conflicts.isNotEmpty) {
        throw const TimiqValidationException(
          'Zadaný čas se překrývá s jiným záznamem.',
        );
      }
      final uniqueTagIds = entry.tagIds.toSet();
      if (uniqueTagIds.isNotEmpty) {
        final placeholders =
            List<String>.filled(uniqueTagIds.length, '?').join(',');
        final existingTags = await txn.rawQuery(
          'SELECT id FROM tags WHERE id IN ($placeholders)',
          uniqueTagIds.toList(growable: false),
        );
        if (existingTags.length != uniqueTagIds.length) {
          throw const TimiqValidationException(
            'Některý z vybraných štítků už neexistuje.',
          );
        }
      }
      final values = _entryToMap(entry);
      final updated = await txn.update(
        'time_entries',
        values,
        where: 'id = ?',
        whereArgs: <Object>[entry.id],
      );
      if (updated == 0) await txn.insert('time_entries', values);
      await txn.delete(
        'time_entry_tags',
        where: 'time_entry_id = ?',
        whereArgs: <Object>[entry.id],
      );
      for (final tagId in uniqueTagIds) {
        await txn.insert(
          'time_entry_tags',
          <String, Object?>{
            'time_entry_id': entry.id,
            'tag_id': tagId,
          },
        );
      }
    });
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _database.delete(
        'time_entries',
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
  }

  @override
  Future<AppSettings> loadSettings() async {
    final rows = await _database.query('app_settings');
    final values = <String, String>{
      for (final row in rows) row['key']! as String: row['value']! as String,
    };
    return AppSettings(
      firstDayOfWeek: _enumValue(
        FirstDayOfWeek.values,
        values['first_day_of_week'],
        FirstDayOfWeek.monday,
      ),
      timeFormat: _enumValue(
        TimiqTimeFormat.values,
        values['time_format'],
        TimiqTimeFormat.twentyFourHour,
      ),
      themeMode: _enumValue(
        TimiqThemeMode.values,
        values['theme_mode'],
        TimiqThemeMode.dark,
      ),
      onboardingCompleted: values['onboarding_completed'] == 'true',
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final values = <String, String>{
      'first_day_of_week': settings.firstDayOfWeek.name,
      'time_format': settings.timeFormat.name,
      'theme_mode': settings.themeMode.name,
      'onboarding_completed': settings.onboardingCompleted.toString(),
    };
    await _database.transaction((txn) async {
      for (final entry in values.entries) {
        await txn.insert(
          'app_settings',
          <String, Object?>{'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<Map<String, Object?>> exportAll() async {
    final categories = await _database.query('categories');
    final activities = await _database.query('activities');
    final entries = await _database.query('time_entries');
    final tags = await _database.query('tags');
    final joins = await _database.query('time_entry_tags');
    final settings = await _database.query('app_settings');
    return buildBackupPayload(
      categories: categories,
      activities: activities,
      timeEntries: entries,
      tags: tags,
      timeEntryTags: joins,
      settings: settings,
      exportedAt: DateTime.now(),
    );
  }

  Future<List<TimeEntry>> _entriesWithTags(
    List<Map<String, Object?>> rows,
  ) async {
    if (rows.isEmpty) return const <TimeEntry>[];
    final tagsByEntry = <String, List<String>>{};
    final ids = rows.map((row) => row['id']! as String).toList(growable: false);
    for (var offset = 0; offset < ids.length; offset += 900) {
      final end = (offset + 900).clamp(0, ids.length).toInt();
      final chunk = ids.sublist(offset, end);
      final placeholders = List<String>.filled(chunk.length, '?').join(',');
      final joins = await _database.rawQuery(
        'SELECT time_entry_id, tag_id FROM time_entry_tags '
        'WHERE time_entry_id IN ($placeholders)',
        chunk,
      );
      for (final join in joins) {
        tagsByEntry
            .putIfAbsent(
              join['time_entry_id']! as String,
              () => <String>[],
            )
            .add(join['tag_id']! as String);
      }
    }
    return rows.map((row) {
      final entry = _entryFromMap(row);
      return entry.copyWith(
        tagIds: tagsByEntry[entry.id] ?? const <String>[],
      );
    }).toList(growable: false);
  }

  T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}

TimiqCategory _categoryFromMap(Map<String, Object?> map) => TimiqCategory(
      id: map['id']! as String,
      name: map['name']! as String,
      colorValue: map['color_value']! as int,
      iconCodePoint: map['icon_code_point']! as int,
      sortOrder: map['sort_order']! as int,
      isArchived: map['is_archived'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );

Map<String, Object?> _categoryToMap(TimiqCategory value) => <String, Object?>{
      'id': value.id,
      'name': value.name,
      'color_value': value.colorValue,
      'icon_code_point': value.iconCodePoint,
      'sort_order': value.sortOrder,
      'is_archived': value.isArchived ? 1 : 0,
      'created_at': value.createdAt.millisecondsSinceEpoch,
      'updated_at': value.updatedAt.millisecondsSinceEpoch,
    };

TimiqActivity _activityFromMap(Map<String, Object?> map) => TimiqActivity(
      id: map['id']! as String,
      categoryId: map['category_id']! as String,
      name: map['name']! as String,
      iconCodePoint: map['icon_code_point']! as int,
      customColorValue: map['custom_color_value'] as int?,
      isFavorite: map['is_favorite'] == 1,
      sortOrder: map['sort_order']! as int,
      isArchived: map['is_archived'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );

Map<String, Object?> _activityToMap(TimiqActivity value) => <String, Object?>{
      'id': value.id,
      'category_id': value.categoryId,
      'name': value.name,
      'icon_code_point': value.iconCodePoint,
      'custom_color_value': value.customColorValue,
      'is_favorite': value.isFavorite ? 1 : 0,
      'sort_order': value.sortOrder,
      'is_archived': value.isArchived ? 1 : 0,
      'created_at': value.createdAt.millisecondsSinceEpoch,
      'updated_at': value.updatedAt.millisecondsSinceEpoch,
    };

TimeEntry _entryFromMap(Map<String, Object?> map) => TimeEntry(
      id: map['id']! as String,
      activityId: map['activity_id']! as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']! as int),
      endTime: map['end_time'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['end_time']! as int),
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );

Map<String, Object?> _entryToMap(TimeEntry value) => <String, Object?>{
      'id': value.id,
      'activity_id': value.activityId,
      'start_time': value.startTime.millisecondsSinceEpoch,
      'end_time': value.endTime?.millisecondsSinceEpoch,
      'note': value.note,
      'created_at': value.createdAt.millisecondsSinceEpoch,
      'updated_at': value.updatedAt.millisecondsSinceEpoch,
    };

TimiqTag _tagFromMap(Map<String, Object?> map) => TimiqTag(
      id: map['id']! as String,
      name: map['name']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    );

Map<String, Object?> _tagToMap(TimiqTag value) => <String, Object?>{
      'id': value.id,
      'name': value.name,
      'created_at': value.createdAt.millisecondsSinceEpoch,
    };

String prettyJson(Map<String, Object?> value) =>
    const JsonEncoder.withIndent('  ').convert(value);

Map<String, Object?> buildBackupPayload({
  required List<Map<String, Object?>> categories,
  required List<Map<String, Object?>> activities,
  required List<Map<String, Object?>> timeEntries,
  required List<Map<String, Object?>> tags,
  required List<Map<String, Object?>> timeEntryTags,
  required List<Map<String, Object?>> settings,
  required DateTime exportedAt,
}) =>
    <String, Object?>{
      'format': 'timiq-backup',
      'version': 1,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'categories': categories,
      'activities': activities,
      'timeEntries': timeEntries,
      'tags': tags,
      'timeEntryTags': timeEntryTags,
      'settings': settings,
    };
