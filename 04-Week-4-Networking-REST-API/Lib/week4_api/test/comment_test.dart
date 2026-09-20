import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  group('Comment Model fromJson', () {
    test('Berhasil parse JSON normal (Happy Path)', () {
      final json = {
        "postId": 1,
        "id": 1,
        "name": "Fadhil",
        "email": "fadhil@test.com",
        "body": "Ini komentar"
      };
      final comment = Comment.fromJson(json);
      
      expect(comment.id, 1);
      expect(comment.name, "Fadhil");
    });

    test('Tidak crash dan menggunakan nilai default saat field hilang (Edge Case)', () {
      // JSON tanpa field 'name' dan 'body' null
      final incompleteJson = {
        "postId": 1,
        "id": 2,
        "email": "test@test.com",
        "body": null
      };
      
      final comment = Comment.fromJson(incompleteJson);
      
      expect(comment.id, 2);
      expect(comment.name, "Unknown Name"); // Default value bekerja
      expect(comment.body, ""); // Default value bekerja
    });
  });
}