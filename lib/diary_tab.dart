import 'package:flutter/material.dart';
import 'diary_database.dart';
import 'diary.dart';

class DiaryTab extends StatefulWidget {
  @override
  _DiaryTabState createState() => _DiaryTabState();
}

class _DiaryTabState extends State<DiaryTab> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Diary> _diaries = [];

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    final diaries = await DiaryDatabase.instance.getDiaries();
    print(diaries);
    setState(() {
      _diaries = diaries.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日記'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _diaries.length,
        itemBuilder: (context, index) {
          final diary = _diaries[index];
          return _buildDiaryItem(diary);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDiaryDialog(context),
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

  void _showAddDiaryDialog(BuildContext context) {
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
                  await DiaryDatabase.instance.insertDiary(title, content);
                  final diaries =
                      await DiaryDatabase.instance.getDiariesByLatest();
                  final newDiary = diaries[0];
                  setState(() {
                    _diaries.insert(0, newDiary);
                  });
                  Navigator.of(context).pop();
                  _scrollToBottom();
                }
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
