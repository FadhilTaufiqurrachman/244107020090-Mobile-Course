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

// Fungsi pesan error ramah pengguna (Timeout, Connection, 404, 500)
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat (melebihi 10 detik). Silakan coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Komentar tidak ditemukan (404).';
        if (code == 500) return 'Server bermasalah (500). Coba lagi nanti.';
        return 'Terjadi kesalahan pada server ($code).';
      default:
        return 'Terjadi kesalahan jaringan.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}