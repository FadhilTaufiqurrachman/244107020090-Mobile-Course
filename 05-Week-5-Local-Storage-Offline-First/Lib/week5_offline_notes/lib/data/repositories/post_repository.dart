import 'dart:convert'; 
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart'; 
import '../models/post.dart';

class PostRepository {
  PostRepository(this._dio, {required this.openDb});
  
  final Dio _dio;
  final Future<Database> Function() openDb;

  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List>('/posts');
    final data = response.data ?? [];
    return data.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }

  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    final response = await _dio.get<List>(
      '/posts',
      queryParameters: {'_page': page, '_limit': limit},
    );
    final data = response.data ?? [];
    return data.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }

  Future<List<Post>> loadPostsCacheFirst() async {
    final cached = await readCachedPosts();
    refreshPostsInBackground(); 
    
    return cached;
  }

  Future<List<Post>> readCachedPosts() async {
    final db = await openDb();
    final rows = await db.query('cached_posts');
  
    return rows.map((row) {
      final payloadString = row['payload'] as String;
      final jsonMap = jsonDecode(payloadString);
      return Post.fromJson(jsonMap);
    }).toList();
  }

  Future<void> refreshPostsInBackground() async {
    try {
      final response = await _dio.get<List>('/posts');
      final data = response.data ?? [];
      final posts = data.whereType<Map<String, dynamic>>().toList();
      
      final db = await openDb();
      
      for (var item in posts) {
        await db.insert(
          'cached_posts', 
          {
            'id': item['id'],
            'payload': jsonEncode(item), 
            'cached_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace, 
        );
      }
    } catch (e) {
      // Tangkap error secara diam-diam. 
      // Jika error terjadi karena sedang offline (mode pesawat), aplikasi tidak akan crash.
    }
  }
}