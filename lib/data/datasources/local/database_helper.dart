import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants/app_constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  // In-memory database fallback for Web
  final List<Map<String, dynamic>> _webDatabase = [];
  int _webIdCounter = 1;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('sqflite database is not supported on web.');
    }
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableHistory} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        original_name TEXT NOT NULL,
        original_path TEXT NOT NULL,
        optimized_path TEXT NOT NULL,
        original_size INTEGER NOT NULL,
        optimized_size INTEGER NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        format TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    if (kIsWeb) {
      final map = Map<String, dynamic>.from(values);
      if (!map.containsKey('id') || map['id'] == null) {
        map['id'] = _webIdCounter++;
      }
      _webDatabase.add(map);
      return map['id'] as int;
    }
    final db = await database;
    return db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    if (kIsWeb) {
      final list = List<Map<String, dynamic>>.from(_webDatabase);
      list.sort((a, b) {
        final aTime = a['created_at'] as String? ?? '';
        final bTime = b['created_at'] as String? ?? '';
        return bTime.compareTo(aTime);
      });
      return list;
    }
    final db = await database;
    return db.query(table, orderBy: 'created_at DESC');
  }

  Future<int> delete(String table, int id) async {
    if (kIsWeb) {
      final initialLength = _webDatabase.length;
      _webDatabase.removeWhere((row) => row['id'] == id);
      return initialLength - _webDatabase.length;
    }
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAll(String table) async {
    if (kIsWeb) {
      final count = _webDatabase.length;
      _webDatabase.clear();
      return count;
    }
    final db = await database;
    return db.delete(table);
  }

  Future<int> update(String table, Map<String, dynamic> values, int id) async {
    if (kIsWeb) {
      final index = _webDatabase.indexWhere((row) => row['id'] == id);
      if (index != -1) {
        _webDatabase[index] = Map<String, dynamic>.from(_webDatabase[index])..addAll(values);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    await db.close();
    _database = null;
  }
}
