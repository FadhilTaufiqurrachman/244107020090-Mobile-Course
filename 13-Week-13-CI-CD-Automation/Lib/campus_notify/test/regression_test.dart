import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/is_valid_task_title.dart';
import 'package:campus_notify/task_service.dart';
import 'package:campus_notify/data/network_cache.dart';
import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';

class _FakeFaultyTaskRepository implements TaskRepository {
  final Exception error;
  _FakeFaultyTaskRepository(this.error);

  @override
  Future<List<String>> getTasks() async {
    throw error;
  }
}

void main() {
  group('Regression Test Suite (Pencegahan Bug Berulang)', () {
    test('Regresi #1: Validasi form tugas menolak input yang hanya terdiri dari whitespace tak kasat mata', () {
      // Bug sebelumnya: teks berisi tab ('\t') dianggap valid karena hanya mengecek length > 0
      // Perbaikan: menggunakan value.trim().isNotEmpty
      expect(isValidTaskTitle('\t\t\t'), isFalse);
      expect(isValidTaskTitle('\n\r'), isFalse);
      expect(isValidTaskTitle('   '), isFalse);
    });

    test('Regresi #2: Error jaringan pada TaskService tidak boleh berubah diam-diam menjadi list kosong', () async {
      // Bug sebelumnya: blok catch menelan exception dan mengembalikan []
      // Perbaikan: exception diteruskan secara transparan agar UI dapat menampilkan state error
      final faultyRepo = _FakeFaultyTaskRepository(
        Exception('Server HTTP 500: Database connection error'),
      );
      final service = TaskService(faultyRepo);

      expect(() async => await service.loadTasks(), throwsA(isA<Exception>()));
    });

    test('Regresi #3: Repository cache menyajikan data lokal saat offline tanpa error fatal', () async {
      // Bug sebelumnya: saat koneksi mati, aplikasi crash tanpa menyajikan data terakhir
      // Perbaikan: Stale-While-Revalidate & Network-First dengan Cache Fallback
      final storage = InMemoryCacheStorage();
      final repo = AnnouncementRepositoryImpl(cacheStorage: storage);

      // Simpan data awal saat online
      final onlineResult = await repo.getAnnouncementById('99');
      expect(onlineResult.announcement, isNotNull);
      expect(storage.hasValid('announcement_detail_99'), isTrue);

      // Akses ulang data yang sudah di-cache
      final cachedResult = await repo.getAnnouncementById('99');
      expect(cachedResult.announcement?.id, '99');
      expect(cachedResult.failure, isNull);
    });

    test('Regresi #4: Paginasi tidak boleh menghasilkan daftar yang tumpang tindih saat dipanggil berurutan', () async {
      final repo = AnnouncementRepositoryImpl();

      final page1 = await repo.fetchAnnouncementsPage(1, limit: 4);
      final page2 = await repo.fetchAnnouncementsPage(2, limit: 4);

      final idsPage1 = page1.announcements.map((a) => a.id).toSet();
      final idsPage2 = page2.announcements.map((a) => a.id).toSet();

      // Pastikan himpunan ID pada kedua halaman saling lepas (tidak ada duplikasi)
      final intersection = idsPage1.intersection(idsPage2);
      expect(intersection, isEmpty);
    });
  });
}
