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

  /// データベースファイルを直接インポートする関数
  /// @param file インポートするデータベースファイル
  /// @throws IOException ファイルの読み書きに失敗した場合
  /// @throws DatabaseException データベースの操作に失敗した場合
  Future<void> importDatabase(File file) async {
    // アプリケーションのデータベースディレクトリのパスを取得
    final dbPath = await getDatabasesPath();
    // インポート先のデータベースファイルパスを生成
    final dbFile = File(join(dbPath, 'diary.db'));

    // 既存のデータベースを新しいファイルで上書き
    // 注意: この操作は既存のデータをすべて削除します
    await file.copy(dbFile.path);
    // 新しいデータベース接続を初期化
    _database = await _initDB('diary.db');
  }

  /// テキストファイルから日記データをインポートする関数
  /// テキストファイルの形式:
  /// タイトル: [タイトル]
  /// 本文: [内容]
  /// の形式で記述されている必要があります
  /// @param file インポートするテキストファイル
  /// @throws IOException ファイルの読み取りに失敗した場合
  /// @throws DatabaseException データベースの挿入に失敗した場合
  Future<void> importFromTxt(File file) async {
    // ファイルの内容を文字列として読み込み
    final content = await file.readAsString();
    // 行単位で分割
    final lines = content.split('\n');
    // データベース接続を取得
    final db = await instance.database;

    // 各行を解析してデータベースに挿入
    for (var i = 0; i < lines.length; i++) {
      // タイトル行を検出
      if (lines[i].startsWith('タイトル: ')) {
        // タイトルと本文を抽出
        // 「タイトル: 」の6文字分をスキップしてタイトルを取得
        final title = lines[i].substring(6);
        // 次の行から「本文: 」の3文字分をスキップして本文を取得
        final content = lines[i + 1].substring(3);

        // データベースに挿入
        // 同じIDのデータが存在する場合は上書き
        await db.insert(
          'diaries',
          {'title': title, 'content': content},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  /// CSVファイルから日記データをインポートする関数
  /// CSVの形式:
  /// ID,タイトル,本文,作成日時
  /// の形式である必要があります（ヘッダー行が必要）
  /// @param file インポートするCSVファイル
  /// @throws IOException ファイルの読み取りに失敗した場合
  /// @throws FormatException CSVの形式が不正な場合
  /// @throws DatabaseException データベースの挿入に失敗した場合
  Future<void> importFromCsv(File file) async {
    // ファイルの内容を文字列として読み込み
    final content = await file.readAsString();
    // 行単位で分割
    final lines = content.split('\n');
    // データベース接続を取得
    final db = await instance.database;

    // 各行を処理（1行目はヘッダーなのでスキップ）
    for (var i = 1; i < lines.length; i++) {
      // カンマで分割してフィールドを取得
      final values = lines[i].split(',');
      // 必要なフィールドがすべて存在することを確認
      if (values.length >= 4) {
        // 各フィールドを適切な型に変換
        final id = int.parse(values[0]); // IDを数値に変換
        final title = values[1].replaceAll('"', ''); // ダブルクォートを除去
        final content = values[2].replaceAll('"', ''); // ダブルクォートを除去
        final createdAt = values[3];

        // デバッグ用のログ出力
        print(
            'id: $id, title: $title, content: $content, created_at: $createdAt');

        // データベースに挿入
        // 同じIDのデータが存在する場合は上書き
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
