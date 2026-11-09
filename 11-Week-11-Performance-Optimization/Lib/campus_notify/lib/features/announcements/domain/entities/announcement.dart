class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
}
