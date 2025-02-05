import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'diary_database.dart';
import 'diary.dart';

final diariesProvider = FutureProvider<List<Diary>>((ref) async {
  final database = ref.watch(diaryDatabaseProvider);
  return await database.getDiaries();
});

class DiaryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diariesAsyncValue = ref.watch(diariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日記'),
      ),
      body: diariesAsyncValue.when(
        data: (diaries) => ListView.builder(
          itemCount: diaries.length,
          itemBuilder: (context, index) {
            final diary = diaries[index];
            return _buildDiaryItem(diary);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDiaryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDiaryItem(Diary diary) {
    return ListTile(
      title: Text(diary.title),
      subtitle: Text(diary.content),
    );
  }

  void _showAddDiaryDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新しい日記を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: '内容'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text;
                final content = contentController.text;

                if (title.isNotEmpty && content.isNotEmpty) {
                  final database = ref.read(diaryDatabaseProvider);
                  await database.insertDiary(title, content);
                  ref.refresh(diariesProvider);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }
}
