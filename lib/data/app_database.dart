import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static const String fileName = 'timiq.db';
  static const int schemaVersion = 1;
  static Database? _database;
  static final Map<int, Future<void> Function(Database)> _migrations =
      <int, Future<void> Function(Database)>{};

  static Future<Database> open() async {
    final existing = _database;
    if (existing != null) return existing;
    final path = p.join(await getDatabasesPath(), fileName);
    final database = await openDatabase(
      path,
      version: schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.rawQuery('PRAGMA journal_mode = WAL');
      },
      onCreate: _createSchema,
      onUpgrade: _migrate,
    );
    _database = database;
    return database;
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          icon_code_point INTEGER NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE activities (
          id TEXT PRIMARY KEY,
          category_id TEXT NOT NULL,
          name TEXT NOT NULL,
          icon_code_point INTEGER NOT NULL,
          custom_color_value INTEGER,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories(id)
            ON UPDATE CASCADE ON DELETE RESTRICT
        )
      ''');
      await txn.execute('''
        CREATE TABLE time_entries (
          id TEXT PRIMARY KEY,
          activity_id TEXT NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          note TEXT NOT NULL DEFAULT '',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          CHECK (end_time IS NULL OR end_time > start_time),
          FOREIGN KEY (activity_id) REFERENCES activities(id)
            ON UPDATE CASCADE ON DELETE RESTRICT
        )
      ''');
      await txn.execute('''
        CREATE TABLE tags (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL COLLATE NOCASE UNIQUE,
          created_at INTEGER NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE time_entry_tags (
          time_entry_id TEXT NOT NULL,
          tag_id TEXT NOT NULL,
          PRIMARY KEY (time_entry_id, tag_id),
          FOREIGN KEY (time_entry_id) REFERENCES time_entries(id)
            ON UPDATE CASCADE ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES tags(id)
            ON UPDATE CASCADE ON DELETE CASCADE
        )
      ''');
      await txn.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await txn.execute(
        'CREATE UNIQUE INDEX only_one_running_entry '
        'ON time_entries ((1)) WHERE end_time IS NULL',
      );
      await txn.execute(
        'CREATE INDEX time_entries_range '
        'ON time_entries (start_time, end_time)',
      );
      await txn.execute(
        'CREATE INDEX time_entries_activity '
        'ON time_entries (activity_id, start_time)',
      );
      await txn.execute(
        'CREATE INDEX activities_category '
        'ON activities (category_id, sort_order)',
      );
    });
  }

  static Future<void> _migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Migrations are deliberately additive. Never use a destructive fallback:
    // user history must survive every ordinary application upgrade.
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      final migration = _migrations[version];
      if (migration == null) {
        throw StateError('Chybí migrace databáze na verzi $version.');
      }
      await migration(db);
    }
  }
}
