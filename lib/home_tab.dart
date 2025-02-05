import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'diary_database.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _backupPath = '';
  String _txtPath = '';
  String _csvPath = '';

  Future<void> _backupDatabase() async {
    final path = await DiaryDatabase.instance.exportDatabase();
    setState(() {
      _backupPath = path;
    });
  }

  Future<void> _exportToTxt() async {
    final path = await DiaryDatabase.instance.exportToTxt();
    setState(() {
      _txtPath = path;
    });
  }

  Future<void> _exportToCsv() async {
    final path = await DiaryDatabase.instance.exportToCsv();
    setState(() {
      _csvPath = path;
    });
  }

  void _shareFile(String path) {
    Share.shareFiles([path], text: '共有するファイル: $path');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton(
            onPressed: _backupDatabase,
            child: const Text('データベースをバックアップ'),
          ),
          if (_backupPath.isNotEmpty) ...[
            ElevatedButton(
              onPressed: () => _shareFile(_backupPath),
              child: const Text('データベースファイルを共有'),
            ),
            const SizedBox(height: 20),
            Text('バックアップファイルのパス:'),
            Text(_backupPath, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _exportToTxt,
            child: const Text('テキストファイルをエクスポート'),
          ),
          if (_txtPath.isNotEmpty) ...[
            ElevatedButton(
              onPressed: () => _shareFile(_txtPath),
              child: const Text('テキストファイルを共有'),
            ),
            const SizedBox(height: 20),
            Text('テキストファイルのパス:'),
            Text(_txtPath, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _exportToCsv,
            child: const Text('CSVファイルをエクスポート'),
          ),
          if (_csvPath.isNotEmpty) ...[
            ElevatedButton(
              onPressed: () => _shareFile(_csvPath),
              child: const Text('CSVファイルを共有'),
            ),
            const SizedBox(height: 20),
            Text('CSVファイルのパス:'),
            Text(_csvPath, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
