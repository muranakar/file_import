// main.dart
import 'package:file_import/diary.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 追加
import 'diary_database.dart';
import 'import_page.dart'; // インポート画面を追加
import 'home_page.dart'; // 追加

// アプリケーションのエントリーポイント
void main() {
  runApp(const ProviderScope(child: MyApp())); // 変更
  _runExampleOnce(); // 変更
  // サンプルデータの作成
}

// アプリケーションのルートウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Diary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Diary Home Page'),
    );
  }
}

void _runExampleOnce() async {
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('isFirstRun') ?? true;

  if (isFirstRun) {
    example();
    await prefs.setBool('isFirstRun', false);
  }
}

void example() async {
  await DiaryDatabase.instance.insertDiary('日記を書く', '今日はいい日だった');
  await DiaryDatabase.instance.insertDiary(
    '本を読む',
    'Flutterのチュートリアルを読んでいる',
  );

  final txtPath = await DiaryDatabase.instance.exportToTxt();
  print('テキストファイルを作成: $txtPath');

  final csvPath = await DiaryDatabase.instance.exportToCsv();
  print('CSVファイルを作成: $csvPath');

  final dbPath = await DiaryDatabase.instance.exportDatabase();
  print('データベースをバックアップ: $dbPath');
}
