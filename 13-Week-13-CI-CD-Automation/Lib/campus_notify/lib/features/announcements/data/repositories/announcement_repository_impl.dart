import '../../../../core/failures.dart';
import '../../../../data/network_cache.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final InMemoryCacheStorage? cacheStorage;

  const AnnouncementRepositoryImpl({this.cacheStorage});

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    final cacheKey = 'announcement_detail_$id';
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final mockData = {
        'id': id,
        'title': 'Pengumuman Kampus #$id',
        'content':
            'Ini adalah konten detail resmi untuk pengumuman BEM nomor $id.',
        'author': 'BEM Kemahasiswaan',
        'created_at': DateTime.now().toIso8601String(),
      };

      final model = AnnouncementModel.fromJson(mockData);
      final entity = model.toEntity();

      // Simpan ke cache lokal untuk akses offline
      cacheStorage?.write(cacheKey, entity);

      return (announcement: entity, failure: null);
    } catch (e) {
      // Fallback ke cache lokal jika terjadi kegagalan jaringan
      final cached = cacheStorage?.read<Announcement>(cacheKey);
      if (cached != null) {
        return (announcement: cached, failure: null);
      }
      return (
        announcement: null,
        failure: LocalFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncementsPage(int page, {int limit = 5}) async {
    final cacheKey = 'announcements_page_$page';
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      // Simulasi batas total 3 halaman (15 pengumuman)
      if (page > 3) {
        return (announcements: <Announcement>[], failure: null);
      }
      final items = List.generate(limit, (index) {
        final id = ((page - 1) * limit + index + 1).toString();
        return Announcement(
          id: id,
          title: 'Pengumuman Kampus #$id',
          content: 'Konten resmi pengumuman nomor $id untuk mahasiswa.',
          author: 'Bagian Kemahasiswaan',
          createdAt: DateTime.now().subtract(Duration(days: int.parse(id))),
        );
      });

      // Update cache lokal
      cacheStorage?.write(cacheKey, items);

      return (announcements: items, failure: null);
    } catch (e) {
      // Fallback ke cache jika offline/error
      final cached = cacheStorage?.read<List<Announcement>>(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return (announcements: cached, failure: null);
      }
      return (
        announcements: <Announcement>[],
        failure: LocalFailure('Gagal memuat daftar pengumuman: $e'),
      );
    }
  }
}
