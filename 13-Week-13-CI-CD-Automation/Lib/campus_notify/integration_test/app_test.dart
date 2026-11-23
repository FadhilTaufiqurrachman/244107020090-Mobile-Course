import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_notify/task_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Integration & Regression Tests', () {
    testWidgets('pengguna dapat menambahkan tugas dan memverifikasi di daftar', (
      tester,
    ) async {
      // 1. Inisialisasi tampilan halaman tugas
      await tester.pumpWidget(const MaterialApp(home: TaskPage()));
      await tester.pumpAndSettle();

      // 2. Pengguna memasukkan judul tugas baru
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Baca materi',
      );

      // 3. Pengguna menekan tombol simpan tugas
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // 4. Verifikasi bahwa tugas baru berhasil tersimpan dan muncul di daftar
      expect(find.text('Baca materi'), findsOneWidget);
    });

    testWidgets(
      'mencegah regresi: penolakan input kosong tidak menambahkan tugas baru',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: TaskPage()));
        await tester.pumpAndSettle();

        // Simulasikan regresi: mencoba menyimpan string spasi kosong
        await tester.enterText(
          find.byKey(const Key('task-title-field')),
          '   ',
        );
        await tester.tap(find.byKey(const Key('save-task-button')));
        await tester.pumpAndSettle();

        // Verifikasi pesan kesalahan muncul dan status tetap 'Belum ada tugas tersimpan'
        expect(find.text('Judul tugas tidak boleh kosong'), findsOneWidget);
        expect(find.text('Belum ada tugas tersimpan'), findsOneWidget);
      },
    );
  });
}
