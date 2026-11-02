import '../local/note.dart';

/// Use case murni untuk menyaring catatan berdasarkan query pencarian.
/// Menerapkan aturan bisnis: case-insensitive, sanitasi leading/trailing whitespace,
/// dan tidak mengubah list asli.
class SearchNotesUseCase {
  const SearchNotesUseCase();

  List<Note> call(List<Note> notes, String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return notes;
    return notes
        .where((note) => note.title.toLowerCase().contains(cleanQuery))
        .toList();
  }
}
