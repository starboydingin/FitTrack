import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

/// Implementasi SQLite — hanya dikompilasi untuk Android/iOS.
class LocalDatabaseImpl {
  static Database? _db;

  static Future<Database> get _database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, kDbName);
    return openDatabase(
      path,
      version: kDbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id        TEXT PRIMARY KEY,
        name      TEXT NOT NULL,
        email     TEXT NOT NULL,
        weight_kg REAL,
        height_cm REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities (
        local_id        TEXT PRIMARY KEY,
        activity_date   TEXT NOT NULL,
        started_at      TEXT NOT NULL,
        ended_at        TEXT NOT NULL,
        steps           INTEGER NOT NULL DEFAULT 0,
        distance_meters INTEGER NOT NULL DEFAULT 0,
        activity_type   TEXT NOT NULL,
        latitude        REAL,
        longitude       REAL,
        recorded_at     TEXT NOT NULL,
        sync_status     TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {}

  // ── User Profile ──────────────────────────────────────────────────────────

  static Future<void> saveUserProfile(Map<String, dynamic> record) async {
    final db = await _database;
    await db.insert('user_profile', record,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await _database;
    final maps = await db.query('user_profile', limit: 1);
    return maps.isEmpty ? null : maps.first;
  }

  static Future<void> clearUserProfile() async {
    final db = await _database;
    await db.delete('user_profile');
  }

  // ── Activities ─────────────────────────────────────────────────────────────

  static Future<void> insertActivity(Map<String, dynamic> activity) async {
    final db = await _database;
    await db.insert('activities', activity,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedActivities() async {
    final db = await _database;
    return db.query(
      'activities',
      where: 'sync_status = ? OR sync_status = ?',
      whereArgs: ['pending', 'failed'],
    );
  }

  static Future<void> updateSyncStatus(
      List<String> localIds, String status) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final id in localIds) {
        await txn.update(
          'activities',
          {'sync_status': status},
          where: 'local_id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getActivitiesForDate(
      String date) async {
    final db = await _database;
    return db.query(
      'activities',
      where: 'activity_date = ?',
      whereArgs: [date],
      orderBy: 'started_at ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getAllLocalActivities() async {
    final db = await _database;
    return db.query('activities', orderBy: 'recorded_at DESC');
  }

  static Future<void> clearAllActivities() async {
    final db = await _database;
    await db.delete('activities');
  }
}
