import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/task_service.dart';

/// Implementasi Fake Repository untuk mengendalikan perilaku pengujian asinkron
class FakeTaskRepository implements TaskRepository {
  final List<String> tasks;
  final Exception? error;
  final Duration? delay;

  FakeTaskRepository({
    this.tasks = const [],
    this.error,
    this.delay,
  });

  @override
  Future<List<String>> getTasks() async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
    if (error != null) {
      throw error!;
    }
    return tasks;
  }
}

void main() {
  group('TaskService & FakeTaskRepository (Pengujian Asinkron & Dependensi)', () {
    test('meneruskan data dari repository (kasus sukses)', () async {
      // Arrange: siapkan fake repository dengan data terkendali
      final fakeRepo = FakeTaskRepository(tasks: ['Baca materi', 'Kerjakan kuis']);
      final service = TaskService(fakeRepo);

      // Act: panggil metode asinkron loadTasks
      final result = await service.loadTasks();

      // Assert: verifikasi data yang diteruskan sama persis
      expect(result, ['Baca materi', 'Kerjakan kuis']);
      expect(result.length, 2);
    });

    test('melemparkan exception ketika repository mengalami error (tidak diam-diam jadi list kosong)', () async {
      // Arrange: siapkan fake repository yang disimulasikan gagal
      final expectedError = Exception('Koneksi database/jaringan terputus');
      final fakeRepo = FakeTaskRepository(error: expectedError);
      final service = TaskService(fakeRepo);

      // Act & Assert: pastikan error tidak disembunyikan dan dilemparkan ke pemanggil
      expect(
        () async => await service.loadTasks(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'pesan error',
          contains('Koneksi database/jaringan terputus'),
        )),
      );
    });

    test('mengembalikan daftar kosong ketika repository tidak memiliki tugas', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository(tasks: const []);
      final service = TaskService(fakeRepo);

      // Act
      final result = await service.loadTasks();

      // Assert
      expect(result, isEmpty);
      expect(result, isA<List<String>>());
    });

    test('menyaring tugas berdasarkan kata kunci pencarian (logika asinkron lanjutan)', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository(tasks: [
        'Belajar Flutter Testing',
        'Kuliah Pemrograman Mobile',
        'Review Clean Architecture',
      ]);
      final service = TaskService(fakeRepo);

      // Act
      final filteredFlutter = await service.loadTasksFiltered('flutter');
      final filteredAll = await service.loadTasksFiltered('   ');

      // Assert
      expect(filteredFlutter, ['Belajar Flutter Testing']);
      expect(filteredAll.length, 3);
    });

    test('menangani operasi asinkron dengan simulasi penundaan waktu (simulated latency)', () async {
      // Arrange: simulasi delay jaringan 50 ms
      final fakeRepo = FakeTaskRepository(
        tasks: ['Tugas dengan Latensi'],
        delay: const Duration(milliseconds: 50),
      );
      final service = TaskService(fakeRepo);

      // Act
      final stopwatch = Stopwatch()..start();
      final result = await service.loadTasks();
      stopwatch.stop();

      // Assert
      expect(result, ['Tugas dengan Latensi']);
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(45));
    });
  });
}
