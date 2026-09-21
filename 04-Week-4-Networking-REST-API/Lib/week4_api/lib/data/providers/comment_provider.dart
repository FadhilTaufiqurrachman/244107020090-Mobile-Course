import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment.dart';
import '../providers.dart';
import '../repositories/comment_repository.dart';

// Menyediakan instance repository
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.watch(dioProvider));
});

// Parameter postId bisa di-passing menggunakan family jika diperlukan, 
// untuk contoh ini kita gunakan AsyncNotifier biasa yang menerima parameter saat dipanggil.
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  @override
  Future<List<Comment>> build() async {
    // Default load postId 1 saat inisialisasi
    return fetchCommentsForPost(1);
  }

  Future<List<Comment>> fetchCommentsForPost(int postId) async {
    final repository = ref.read(commentRepositoryProvider);
    return repository.fetchComments(postId);
  }
}

final commentListProvider = AsyncNotifierProvider<CommentListNotifier, List<Comment>>(
  CommentListNotifier.new,
);