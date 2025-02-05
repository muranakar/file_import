import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'diary_database.dart';
import 'import_page.dart';
import 'diary.dart';
import 'home_tab.dart';
import 'diary_tab.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToImport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _navigateToImport,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'ホーム'),
            Tab(icon: Icon(Icons.book), text: '日記'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HomeTab(),
          DiaryTab(),
        ],
      ),
    );
  }
}
