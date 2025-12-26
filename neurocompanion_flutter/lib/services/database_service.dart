import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'neurocompanion.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        dueDate INTEGER,
        reminderTime TEXT,
        completedAt INTEGER,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Journal entries table
    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        mood TEXT,
        emotions TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retryCount INTEGER DEFAULT 0,
        error TEXT
      )
    ''');

    // Cache table
    await db.execute('''
      CREATE TABLE cache (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        expiresAt INTEGER,
        createdAt INTEGER NOT NULL
      )
    ''');

    debugPrint('Database created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from $oldVersion to $newVersion');
    // Handle future schema migrations
  }

  // Task operations
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    task['synced'] = 0;
    task['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    task['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    return await db.insert('tasks', task, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return await db.query('tasks', orderBy: 'updatedAt DESC');
  }

  Future<int> updateTask(String id, Map<String, dynamic> task) async {
    final db = await database;
    task['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    task['synced'] = 0;
    return await db.update('tasks', task, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markTaskSynced(String id) async {
    final db = await database;
    await db.update('tasks', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTasks() async {
    final db = await database;
    return await db.query('tasks', where: 'synced = ?', whereArgs: [0]);
  }

  // Journal operations
  Future<int> insertJournalEntry(Map<String, dynamic> entry) async {
    final db = await database;
    entry['synced'] = 0;
    entry['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    entry['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    return await db.insert('journal_entries', entry, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getJournalEntries() async {
    final db = await database;
    return await db.query('journal_entries', orderBy: 'createdAt DESC');
  }

  Future<int> updateJournalEntry(String id, Map<String, dynamic> entry) async {
    final db = await database;
    entry['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    entry['synced'] = 0;
    return await db.update('journal_entries', entry, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteJournalEntry(String id) async {
    final db = await database;
    return await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markJournalEntrySynced(String id) async {
    final db = await database;
    await db.update('journal_entries', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedJournalEntries() async {
    final db = await database;
    return await db.query('journal_entries', where: 'synced = ?', whereArgs: [0]);
  }

  // Sync queue operations
  Future<int> addToSyncQueue({
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'operation': operation,
      'entityType': entityType,
      'entityId': entityId,
      'data': jsonEncode(data),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'timestamp ASC');
  }

  Future<int> removeSyncQueueItem(int id) async {
    final db = await database;
    return await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> incrementSyncRetryCount(int id, String error) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE sync_queue SET retryCount = retryCount + 1, error = ? WHERE id = ?',
      [error, id],
    );
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }

  // Cache operations
  Future<int> setCache(String key, String value, {Duration? expiresIn}) async {
    final db = await database;
    final expiresAt = expiresIn != null
        ? DateTime.now().add(expiresIn).millisecondsSinceEpoch
        : null;

    return await db.insert(
      'cache',
      {
        'key': key,
        'value': value,
        'expiresAt': expiresAt,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCache(String key) async {
    final db = await database;
    final results = await db.query('cache', where: 'key = ?', whereArgs: [key]);

    if (results.isEmpty) return null;

    final cache = results.first;
    final expiresAt = cache['expiresAt'] as int?;

    if (expiresAt != null && expiresAt < DateTime.now().millisecondsSinceEpoch) {
      await db.delete('cache', where: 'key = ?', whereArgs: [key]);
      return null;
    }

    return cache['value'] as String;
  }

  Future<int> deleteCache(String key) async {
    final db = await database;
    return await db.delete('cache', where: 'key = ?', whereArgs: [key]);
  }

  Future<void> clearExpiredCache() async {
    final db = await database;
    await db.delete(
      'cache',
      where: 'expiresAt IS NOT NULL AND expiresAt < ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );
  }

  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('cache');
  }

  // Utility methods
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('journal_entries');
    await db.delete('sync_queue');
    await db.delete('cache');
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final tasks = await db.query('tasks');
    final journals = await db.query('journal_entries');
    final syncQueue = await db.query('sync_queue');
    final cache = await db.query('cache');

    return {
      'tasks': tasks.length,
      'journals': journals.length,
      'syncQueue': syncQueue.length,
      'cache': cache.length,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
