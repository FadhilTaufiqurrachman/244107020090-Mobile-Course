import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/providers/note_provider.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/services/search_notes.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items = const []})
    : super(openDb: () => throw UnimplementedError());

  final List<Note> items;

  @override
  Future<List<Note>> fetchNotes() async => items;

  @override
  Future<int> countDirty() => Future.value(items.where((n) => n.dirty).length);
}

void main() {
  group('SearchNotesUseCase Unit Tests', () {
    const useCase = SearchNotesUseCase();

    final sampleNotes = [
      Note(id: 1, title: 'Belanja Sayur', updatedAt: DateTime(2026, 10, 1)),
      Note(id: 2, title: 'beli susu segar', updatedAt: DateTime(2026, 10, 2)),
      Note(
        id: 3,
        title: 'Kuliah Pemrograman Mobile',
        updatedAt: DateTime(2026, 10, 3),
      ),
      Note(id: 4, title: 'Catatan [Penting]', updatedAt: DateTime(2026, 10, 4)),
    ];

    test('filter abaikan huruf besar/kecil (case-insensitive)', () {
      final resultsUpper = useCase(sampleNotes, 'BELANJA');
      final resultsLower = useCase(sampleNotes, 'belanja');

      expect(resultsUpper, hasLength(1));
      expect(resultsLower, hasLength(1));
      expect(resultsUpper.first.title, 'Belanja Sayur');
    });

    test('query tak cocok kembalikan kosong (empty match)', () {
      final results = useCase(sampleNotes, 'zzz-tak-ada-disini');
      expect(results, isEmpty);
    });

    test('query spasi saja mengembalikan semua catatan tanpa filter salah', () {
      final results = useCase(sampleNotes, '    ');
      expect(results, hasLength(4));
    });

    test(
      'query dengan simbol regex / karakter khusus tetap aman tanpa crash',
      () {
        final results = useCase(sampleNotes, '[Penting]');
        expect(results, hasLength(1));
        expect(results.first.title, 'Catatan [Penting]');
      },
    );
  });

  group('Search & Empty State Widget Tests', () {
    testWidgets(
      'menampilkan icon dan pesan empty state saat query pencarian tidak cocok',
      (tester) async {
        final repository = FakeNoteRepository(
          items: [
            Note(
              id: 1,
              title: 'Belanja Sayur',
              updatedAt: DateTime(2026, 10, 1),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [noteRepositoryProvider.overrideWithValue(repository)],
            child: const MaterialApp(home: NotesPage()),
          ),
        );

        // Tunggu hingga data notes selesai dimuat
        await tester.pumpAndSettle();

        // 1. Verifikasi catatan awal tampil
        expect(find.text('Belanja Sayur'), findsOneWidget);
        expect(find.byIcon(Icons.search_off), findsNothing);

        // 2. Ketik kata kunci yang tidak cocok di TextField search
        await tester.enterText(find.byType(TextField), 'zzz-tak-ada');
        await tester.pumpAndSettle();

        // 3. Verifikasi catatan lama hilang dan tampilan Empty State muncul
        expect(find.text('Belanja Sayur'), findsNothing);
        expect(find.byIcon(Icons.search_off), findsOneWidget);
        expect(
          find.text('Tidak ada catatan dengan judul "zzz-tak-ada"'),
          findsOneWidget,
        );

        // 4. Bersihkan pencarian via tombol clear (Icons.clear)
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        // 5. Verifikasi daftar catatan kembali tampil utuh
        expect(find.text('Belanja Sayur'), findsOneWidget);
        expect(find.byIcon(Icons.search_off), findsNothing);
      },
    );
  });
}
