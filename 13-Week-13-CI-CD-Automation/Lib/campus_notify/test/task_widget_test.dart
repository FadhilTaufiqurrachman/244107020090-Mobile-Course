import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/task_page.dart';

void main() {
  group('TaskPage Widget Tests (Pengujian Widget & Interaksi Pengguna)', () {
    testWidgets('menampilkan judul halaman tugas', (tester) async {
      // 1. Bangun widget dan periksa hasilnya
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Daftar tugas'))),
      );

      expect(find.text('Daftar tugas'), findsOneWidget);
    });

    testWidgets(
      'menampilkan antarmuka TaskPage lengkap dengan judul dan state awal',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: TaskPage()));

        // Pastikan AppBar, TextField, dan Tombol Simpan terender
        expect(find.text('Daftar tugas'), findsOneWidget);
        expect(find.byKey(const Key('task-title-field')), findsOneWidget);
        expect(find.byKey(const Key('save-task-button')), findsOneWidget);
        expect(find.text('Belum ada tugas tersimpan'), findsOneWidget);
      },
    );

    testWidgets('menguji interaksi pengguna menambah tugas ke daftar', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TaskPage()));

      // Masukkan teks ke form menggunakan enterText
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Baca materi',
      );

      // Tekan tombol simpan menggunakan tap
      await tester.tap(find.byKey(const Key('save-task-button')));

      // Pompa frame sampai animasi selesai menggunakan pumpAndSettle
      await tester.pumpAndSettle();

      // Periksa bahwa item baru muncul di daftar tugas
      expect(find.text('Baca materi'), findsOneWidget);

      // Verifikasi bahwa input field dikosongkan setelah penyimpanan
      expect(find.widgetWithText(TextField, 'Baca materi'), findsNothing);
    });

    testWidgets(
      'menampilkan pesan validasi saat judul tugas kosong atau hanya spasi',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: TaskPage()));

        // Masukkan spasi saja
        await tester.enterText(
          find.byKey(const Key('task-title-field')),
          '    ',
        );
        await tester.tap(find.byKey(const Key('save-task-button')));
        await tester.pumpAndSettle();

        // Verifikasi pesan error muncul di UI
        expect(find.text('Judul tugas tidak boleh kosong'), findsOneWidget);
        expect(find.text('Belum ada tugas tersimpan'), findsOneWidget);
      },
    );

    testWidgets(
      'mengelola pemompaan frame tanpa jeda waktu tetap Future.delayed',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: TaskPage()));

        // Tambahkan tugas pertama
        await tester.enterText(
          find.byKey(const Key('task-title-field')),
          'Tugas A',
        );
        await tester.tap(find.byKey(const Key('save-task-button')));
        await tester.pump(); // Pompa 1 frame perubahan state

        // Tambahkan tugas kedua
        await tester.enterText(
          find.byKey(const Key('task-title-field')),
          'Tugas B',
        );
        await tester.tap(find.byKey(const Key('save-task-button')));
        await tester.pump(
          const Duration(milliseconds: 100),
        ); // Memajukan jam virtual test
        await tester.pumpAndSettle(); // Tunggu hingga semua settled

        expect(find.text('Tugas A'), findsOneWidget);
        expect(find.text('Tugas B'), findsOneWidget);
      },
    );
  });
}
