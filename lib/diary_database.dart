import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'diary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 追加

final diaryDatabaseProvider = Provider<DiaryDatabase>((ref) {
  return DiaryDatabase.instance;
});

class DiaryDatabase {
  static final DiaryDatabase instance = DiaryDatabase._init();
  static Database? _database;

  DiaryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('diary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE diaries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      content TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
    ''');
  }

  Future<List<Diary>> getDiaries() async {
    return await getDiariesByLatest();
  }

  Future<List<Diary>> getDiariesByLatest() async {
    final db = await instance.database;
    final maps = await db.query(
      'diaries',
      orderBy: 'datetime(created_at) DESC',
    );

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return Diary.fromMap(maps[i]);
    });
  }

  Future<void> deleteAllDiaries() async {
    final db = await instance.database;
    await db.delete('diaries');
  }

  String _formattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd-HH:mm');
    return formatter.format(now);
  }

  Future<String> exportToTxt() async {
    final db = await database;
    final diaries = await db.query('diaries');

    final docDir = await getApplicationDocumentsDirectory();
    final txtFile =
        File(join(docDir.path, 'txt_diaries_${_formattedDate()}.txt'));

    final buffer = StringBuffer();
    buffer.writeln('===== 日記リスト =====');

    for (var diary in diaries) {
      buffer.writeln('ID: ${diary['id']}');
      buffer.writeln('タイトル: ${diary['title']}');
      buffer.writeln('内容: ${diary['content']}');
      buffer.writeln('作成日時: ${diary['created_at']}');
      buffer.writeln('-------------------');
    }

    await txtFile.writeAsString(buffer.toString());
    return txtFile.path;
  }

  Future<String> exportToCsv() async {
    final db = await database;
    final diaries = await db.query('diaries');

    final docDir = await getApplicationDocumentsDirectory();
    final csvFile =
        File(join(docDir.path, 'csv_diaries_${_formattedDate()}.csv'));

    final buffer = StringBuffer();
    buffer.writeln('id,title,content,created_at');

    for (var diary in diaries) {
      final values = [
        diary['id'],
        '"${diary['title']}"',
        '"${diary['content']}"',
        diary['created_at']
      ];
      buffer.writeln(values.join(','));
    }

    await csvFile.writeAsString(buffer.toString());
    return csvFile.path;
  }

  Future<String> exportDatabase() async {
    try {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }

      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, 'diary.db'));

      final docDir = await getApplicationDocumentsDirectory();
      final backupPath = join(docDir.path, 'db_backup_${_formattedDate()}.db');

      await dbFile.copy(backupPath);
      return backupPath;
    } catch (e) {
      print('バックアップエラー: $e');
      rethrow;
    }
  }

  Future<void> insertDiary(String title, String content) async {
    final db = await instance.database;
    final createdAt = DateTime.now().toIso8601String();
    await db.insert(
      'diaries',
      {
        'title': title,
        'content': content,
        'created_at': createdAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // データベースファイルのインポート処理を行う関数
  Future<void> importDatabase(File file) async {
    final dbPath = await getDatabasesPath();
    final dbFile = File(join(dbPath, 'diary.db'));

    await file.copy(dbFile.path);
    _database = await _initDB('diary.db');
  }

  // テキストファイルからのインポート処理を行う関数
  Future<void> importFromTxt(File file) async {
    final content = await file.readAsString();
    final lines = content.split('\n');
    final db = await instance.database;

    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('タイトル: ')) {
        final title = lines[i].substring(6);
        final content = lines[i + 1].substring(3);
        await db.insert(
          'diaries',
          {'title': title, 'content': content},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  // CSVファイルからのインポート処理を行う関数
  Future<void> importFromCsv(File file) async {
    final content = await file.readAsString();
    final lines = content.split('\n');
    final db = await instance.database;

    for (var i = 1; i < lines.length; i++) {
      final values = lines[i].split(',');
      if (values.length >= 4) {
        final id = int.parse(values[0]);
        final title = values[1].replaceAll('"', '');
        final content = values[2].replaceAll('"', '');
        final createdAt = values[3];
        print(
            'id: $id, title: $title, content: $content, created_at: $createdAt');
        await db.insert(
          'diaries',
          {
            'id': id,
            'title': title,
            'content': content,
            'created_at': createdAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }
}
