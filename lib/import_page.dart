import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'diary_database.dart';

class ImportPage extends StatelessWidget {
  const ImportPage({super.key});

  Future<void> _importDatabase(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await DiaryDatabase.instance.importDatabase(file);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データベースをインポートしました')),
      );
    }
  }

  Future<void> _importFromTxt(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await DiaryDatabase.instance.deleteAllDiaries();
      await DiaryDatabase.instance.importFromTxt(file);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テキストファイルからインポートしました')),
      );
    }
  }

  Future<void> _importFromCsv(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await DiaryDatabase.instance.deleteAllDiaries();
      await DiaryDatabase.instance.importFromCsv(file);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSVファイルからインポートしました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('インポートページ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => _importDatabase(context),
              child: const Text('データベースファイルをインポート'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _importFromTxt(context),
              child: const Text('テキストファイルからインポート'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _importFromCsv(context),
              child: const Text('CSVファイルからインポート'),
            ),
          ],
        ),
      ),
    );
  }
}
