import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/providers/note_provider.dart';

// 1. Membuat Repository Palsu (Fake)
class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items = const [], this.throwError = false})
    : super(
        openDb: () => throw UnimplementedError(),
      ); // Sengaja dibuat error jika mencoba buka SQLite

  final List<Note> items;
  final bool throwError;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulasi)');
    return items;
  }

  @override
  Future<int> countDirty() => Future.value(items.where((n) => n.dirty).length);
}

void main() {
  // 2. Test Model (Mapping aman dari field yang hilang)
  test('fromMap aman terhadap field yang hilang', () {
    final note = Note.fromMap({'title': 'Belanja'});
    expect(note.title, 'Belanja');
    expect(note.body, ''); // Otomatis terisi string kosong, tidak null
    expect(note.dirty, isFalse);
  });

  // 3. Test Model (Flag dirty bertahan pada serialisasi)
  test('flag dirty bertahan pada serialisasi', () {
    final note = Note(
      id: 1,
      title: 'a',
      body: '',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );
    final restored = Note.fromMap(note.toMap());
    expect(restored.dirty, isTrue); // Memastikan nilai true (1) tetap utuh
  });

  // 4. Test Provider Sukses
  test('provider sukses dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        // Mengganti repository asli dengan FakeNoteRepository
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(
            items: [
              Note(id: 1, title: 'Tes', body: '', updatedAt: DateTime.now()),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Ganti 'noteListProvider' sesuai nama provider Anda di file note_provider.dart
    final notes = await container.read(noteListProvider.future);
    expect(notes.length, 1);
    expect(notes.first.title, 'Tes');
  });

  // 5. Test Provider Error (Diperbarui agar kebal terhadap Timeout)
  test('provider error dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(throwError: true), // Simulasi database rusak
        ),
      ],
    );
    addTearDown(container.dispose);

    // 1. Panggil provider untuk memicu fungsi build() berjalan
    container.read(noteListProvider);

    // 2. Beri jeda waktu sejenak agar proses melempar error selesai dieksekusi
    await Future.delayed(const Duration(milliseconds: 100));

    // 3. Baca status (state) terakhir dari provider
    final state = container.read(noteListProvider);

    // 4. Pastikan statusnya berhasil berubah menjadi error
    expect(state.hasError, isTrue);
  });

  // --- UNIT TESTS FITUR SEARCH (WEEK 9 PRAKTIKUM 2 & AI CHALLENGE) ---

  // 6. Test Fitur Search: filter abaikan huruf besar/kecil (case-insensitive)
  test('filter abaikan huruf besar/kecil', () {
    final list = [
      Note(title: 'Belanja Sayur', updatedAt: DateTime(2026, 10, 1)),
      Note(title: 'beli susu', updatedAt: DateTime(2026, 10, 1)),
      Note(title: 'Kuliah Mobile', updatedAt: DateTime(2026, 10, 1)),
    ];

    expect(filterNotes(list, 'belanja'), hasLength(1));
    expect(filterNotes(list, 'beli'), hasLength(1));
  });

  // 7. Test Fitur Search: query tak cocok kembalikan kosong (empty state trigger)
  test('query tak cocok kembalikan kosong', () {
    final list = [
      Note(title: 'Belanja Sayur', updatedAt: DateTime(2026, 10, 1)),
      Note(title: 'beli susu', updatedAt: DateTime(2026, 10, 1)),
    ];

    expect(filterNotes(list, 'zzz-tak-ada'), isEmpty);
  });

  // 8. Test Fitur Search: whitespace query aman dan mengembalikan semua catatan
  test('query spasi saja mengembalikan semua catatan tanpa error', () {
    final list = [
      Note(title: 'Belanja Sayur', updatedAt: DateTime(2026, 10, 1)),
      Note(title: 'Kuliah Mobile', updatedAt: DateTime(2026, 10, 1)),
    ];

    expect(filterNotes(list, '   '), hasLength(2));
  });

  // 9. Test Fitur Search: query dengan simbol khusus / regex tidak menyebabkan crash
  test('query dengan simbol khusus atau regex characters aman', () {
    final list = [
      Note(title: 'Belanja [Sayur]', updatedAt: DateTime(2026, 10, 1)),
      Note(title: 'Tugas *Mobile*', updatedAt: DateTime(2026, 10, 1)),
    ];

    expect(filterNotes(list, '[Sayur]'), hasLength(1));
    expect(filterNotes(list, '*Mobile*'), hasLength(1));
  });
}
