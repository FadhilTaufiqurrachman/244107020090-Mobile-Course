import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  );

  /// Mengambil daftar pengumuman per halaman untuk infinite scroll (Optimasi Minggu 11)
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncementsPage(int page, {int limit = 5});
}
