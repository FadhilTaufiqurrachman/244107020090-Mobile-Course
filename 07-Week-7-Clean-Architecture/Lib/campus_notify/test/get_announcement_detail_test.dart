import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcement_detail.dart';

// Fake Repository murni untuk domain testing tanpa koneksi jaringan / database
class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.announcement, this.fail = false});

  final Announcement? announcement;
  final bool fail;

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    if (fail) {
      return (
        announcement: null,
        failure: const LocalFailure('Simulasi error: Pengumuman tidak ditemukan'),
      );
    }
    return (announcement: announcement, failure: null);
  }
}

void main() {
  group('GetAnnouncementDetail Use Case Tests', () {
    test('Mengembalikan detail pengumuman dari repository palsu saat sukses',
        () async {
      final sample = Announcement(
        id: '99',
        title: 'Seminar Nasional AI',
        content: 'Seminar diadakan di Gedung Serbaguna jam 09.00.',
        author: 'BEM Kampus',
        createdAt: DateTime(2026, 10, 19),
      );

      final repo = FakeAnnouncementRepository(announcement: sample);
      final useCase = GetAnnouncementDetail(repo);

      final result = await useCase.call('99');

      expect(result.failure, isNull);
      expect(result.announcement, isNotNull);
      expect(result.announcement!.id, '99');
      expect(result.announcement!.title, 'Seminar Nasional AI');
      expect(result.announcement!.author, 'BEM Kampus');
    });

    test('Meneruskan Failure dengan aman tanpa melempar exception saat gagal',
        () async {
      final repo = FakeAnnouncementRepository(fail: true);
      final useCase = GetAnnouncementDetail(repo);

      final result = await useCase.call('non_existing_id');

      expect(result.announcement, isNull);
      expect(result.failure, isA<LocalFailure>());
      expect(result.failure!.message, contains('Pengumuman tidak ditemukan'));
    });
  });
}
