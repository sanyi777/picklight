import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'database_schema.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// Reset the singleton database instance. For testing only.
  /// If [testPath] is provided, the next database open will use that path.
  static String? _testPath;
  static void resetInstance({String? testPath}) {
    _database = null;
    _testPath = testPath;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = _testPath ?? join(
      (await getApplicationDocumentsDirectory()).path,
      'personal_assistant.db',
    );
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final sql in allCreateTables) {
      await db.execute(sql);
    }
    // Insert default tags
    await _insertDefaultTags(db);
    // Create performance indexes
    await _createPerformanceIndexes(db);
  }

  Future<void> _insertDefaultTags(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (final tag in defaultTags) {
      await db.insert('tags', {
        ...tag,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _createPerformanceIndexes(Database db) async {
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_capture_created_at ON capture_items(created_at)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_capture_category ON capture_items(category)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_schedule_date ON schedule_items(date)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_focus_created_at ON focus_sessions(created_at)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_intentions_created_at ON intentions(created_at)',
      );
    } catch (_) {
      // Index may already exist
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS project_progress');
      await db.execute(createProjectProgressTable);
    }
    if (oldVersion < 3) {
      // Create tags table
      await db.execute(createTagsTable);
      // Insert default tags
      await _insertDefaultTags(db);
      // Create performance indexes
      await _createPerformanceIndexes(db);
    }
  }

  Future<void> initDatabase() async {
    await database;
  }

  // ============== Tag CRUD ==============

  Future<List<Map<String, dynamic>>> getAllTags() async {
    final db = await database;
    return await db.query('tags', orderBy: 'created_at ASC');
  }

  /// Returns the tag row for a given tag name, or null.
  Future<Map<String, dynamic>?> getTagByName(String name) async {
    final db = await database;
    final results = await db.query(
      'tags',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insertTag(Map<String, dynamic> tag) async {
    final db = await database;
    await db.insert('tags', tag, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteTag(String tagId) async {
    final db = await database;
    await db.delete('tags', where: 'tag_id = ?', whereArgs: [tagId]);
  }

  Future<int> getTagCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM tags');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ============== VACUUM ==============

  Future<void> vacuumDatabase() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  // ============== Paginated queries ==============

  Future<List<Map<String, dynamic>>> queryCaptureItemsPaged({
    int offset = 0,
    int limit = 50,
  }) async {
    final db = await database;
    return await db.query(
      'capture_items',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  // ============== Data export/import ==============

  Future<Map<String, List<Map<String, dynamic>>>> exportAllData() async {
    final db = await database;
    return {
      'tags': await db.query('tags'),
      'intentions': await db.query('intentions'),
      'capture_items': await db.query('capture_items'),
      'focus_sessions': await db.query('focus_sessions'),
      'schedule_items': await db.query('schedule_items'),
      'daily_logs': await db.query('daily_logs'),
      'project_progress': await db.query('project_progress'),
    };
  }

  Future<void> importAllData(
    Map<String, List<Map<String, dynamic>>> data,
  ) async {
    final db = await database;

    await db.delete('daily_logs');
    await db.delete('schedule_items');
    await db.delete('focus_sessions');
    await db.delete('capture_items');
    await db.delete('intentions');
    await db.delete('project_progress');
    await db.delete('tags');

    final tables = [
      'tags',
      'intentions',
      'capture_items',
      'focus_sessions',
      'schedule_items',
      'daily_logs',
      'project_progress',
    ];

    for (final table in tables) {
      final rows = data[table] as List?;
      if (rows == null || rows.isEmpty) continue;
      for (final row in rows) {
        await db.insert(
          table,
          row as Map<String, Object?>,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('daily_logs');
    await db.delete('schedule_items');
    await db.delete('focus_sessions');
    await db.delete('capture_items');
    await db.delete('intentions');
    await db.delete('project_progress');
    await db.delete('tags');
    // Re-insert default tags
    await _insertDefaultTags(db);
  }

  Future<int> getDatabaseFileSize() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'personal_assistant.db');
    return await File(dbPath).length();
  }

  Future<Map<String, List<Map<String, dynamic>>>> globalSearch(
    String query,
  ) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return {
        'captures': [],
        'schedules': [],
        'intentions': [],
        'projects': [],
      };
    }

    final db = await database;
    final like = '%$trimmed%';

    List<Map<String, dynamic>> captures;
    try {
      final containsChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(trimmed);
      final searchTerm = containsChinese ? '"$trimmed"' : trimmed;
      captures = await db.rawQuery(
        '''
        SELECT ci.* FROM capture_items ci
        INNER JOIN capture_items_fts fts ON ci.rowid = fts.rowid
        WHERE capture_items_fts MATCH ?
        ORDER BY rank
        LIMIT 50
      ''',
        [searchTerm],
      );
    } catch (_) {
      captures = await db.query(
        'capture_items',
        where: 'content LIKE ?',
        whereArgs: [like],
        limit: 50,
      );
    }

    final schedules = await db.query(
      'schedule_items',
      where: 'title LIKE ?',
      whereArgs: [like],
      limit: 50,
    );

    final intentions = await db.query(
      'intentions',
      where: 'intention_text LIKE ? OR highlight LIKE ?',
      whereArgs: [like, like],
      limit: 50,
    );

    final projects = await db.query(
      'project_progress',
      where: 'title LIKE ?',
      whereArgs: [like],
      limit: 50,
    );

    return {
      'captures': captures,
      'schedules': schedules,
      'intentions': intentions,
      'projects': projects,
    };
  }

  Future<List<Map<String, dynamic>>> searchCapturesFts(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await database;

    final containsChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(query);
    final searchTerm = containsChinese ? '"$query"' : query;

    try {
      return await db.rawQuery(
        '''
        SELECT ci.* FROM capture_items ci
        INNER JOIN capture_items_fts fts ON ci.rowid = fts.rowid
        WHERE capture_items_fts MATCH ?
        ORDER BY rank
        LIMIT 200
      ''',
        [searchTerm],
      );
    } catch (_) {
      return [];
    }
  }
}
