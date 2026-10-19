import '../../domain/entities/announcement.dart';

class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.content,
    required super.author,
    required super.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'author': author,
        'created_at': createdAt.toIso8601String(),
      };

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      author: json['author'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Announcement toEntity() => Announcement(
        id: id,
        title: title,
        content: content,
        author: author,
        createdAt: createdAt,
      );
}
