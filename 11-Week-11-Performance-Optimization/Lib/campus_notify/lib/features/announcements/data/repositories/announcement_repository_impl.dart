import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl();

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
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
      return (announcement: model.toEntity(), failure: null);
    } catch (e) {
      return (
        announcement: null,
        failure: LocalFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }
}
