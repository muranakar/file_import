import 'dart:io';
import 'package:file_import/diary_tab.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'diary_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportPage extends ConsumerWidget {
  const ImportPage({super.key});

  Future<void> _importDatabase(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await DiaryDatabase.instance.importDatabase(file);
      ref.invalidate(diariesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データベースをインポートしました')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _importFromTxt(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await DiaryDatabase.instance.deleteAllDiaries();
      await DiaryDatabase.instance.importFromTxt(file);
      ref.invalidate(diariesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テキストファイルからインポートしました')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _importFromCsv(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await DiaryDatabase.instance.deleteAllDiaries();
      await DiaryDatabase.instance.importFromCsv(file);
      ref.invalidate(diariesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSVファイルからインポートしました')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('インポートページ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => _importDatabase(context, ref),
              child: const Text('データベースファイルをインポート'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _importFromTxt(context, ref),
              child: const Text('テキストファイルからインポート'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _importFromCsv(context, ref),
              child: const Text('CSVファイルからインポート'),
            ),
          ],
        ),
      ),
    );
  }
}
