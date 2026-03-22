import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/entry.dart';

/// Local SQLite database service for storing journal entries.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  /// Open (or create) the database.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'daily_life_os.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id            TEXT PRIMARY KEY,
            date          TEXT NOT NULL UNIQUE,
            mood          INTEGER NOT NULL DEFAULT 5,
            focus         INTEGER NOT NULL DEFAULT 5,
            sleep_hours   REAL NOT NULL DEFAULT 7.0,
            tasks_planned TEXT DEFAULT '',
            tasks_completed TEXT DEFAULT '',
            obstacles     TEXT DEFAULT '',
            wins          TEXT DEFAULT '',
            diet          TEXT DEFAULT '',
            freeform      TEXT DEFAULT '',
            photos_base64 TEXT DEFAULT '[]',
            completion_percent INTEGER,
            daily_summary TEXT,
            insight       TEXT,
            suggestion    TEXT,
            new_categories TEXT,
            created_at    TEXT DEFAULT (datetime('now'))
          )
        ''');
      },
    );
  }

  // ── CRUD ──────────────────────────────────────────────────────────────

  /// Insert or replace an entry (upsert by date).
  Future<void> upsertEntry(Entry entry) async {
    final db = await database;
    await db.insert(
      'entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch a single entry by date string (yyyy-MM-dd).
  Future<Entry?> getEntryByDate(String date) async {
    final db = await database;
    final rows = await db.query('entries', where: 'date = ?', whereArgs: [date]);
    if (rows.isEmpty) return null;
    return Entry.fromMap(rows.first);
  }

  /// Fetch all entries ordered by date descending.
  Future<List<Entry>> getAllEntries() async {
    final db = await database;
    final rows = await db.query('entries', orderBy: 'date DESC');
    return rows.map((r) => Entry.fromMap(r)).toList();
  }

  /// Fetch entries within a date range (inclusive).
  Future<List<Entry>> getEntriesInRange(String startDate, String endDate) async {
    final db = await database;
    final rows = await db.query(
      'entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return rows.map((r) => Entry.fromMap(r)).toList();
  }

  /// Delete an entry by id.
  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  /// Get total entry count.
  Future<int> getEntryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM entries');
    return result.first['c'] as int;
  }

  /// Get average mood for a date range.
  Future<double?> getAverageMood(String startDate, String endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(mood) as avg_mood FROM entries WHERE date >= ? AND date <= ?',
      [startDate, endDate],
    );
    return result.first['avg_mood'] as double?;
  }

  /// Get average completion % for a date range.
  Future<double?> getAverageCompletion(String startDate, String endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(completion_percent) as avg FROM entries WHERE date >= ? AND date <= ? AND completion_percent IS NOT NULL',
      [startDate, endDate],
    );
    return result.first['avg'] as double?;
  }
}
