class Diary {
  final int id;
  final String title;
  final String content;

  Diary({required this.id, required this.title, required this.content});

  // データベースからDiaryオブジェクトを作成するためのファクトリメソッド
  factory Diary.fromMap(Map<String, dynamic> map) {
    return Diary(
      id: map['id'],
      title: map['title'],
      content: map['content'],
    );
  }

  // Diaryオブジェクトをデータベースに保存するためのMapに変換するメソッド
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
    };
  }
}
