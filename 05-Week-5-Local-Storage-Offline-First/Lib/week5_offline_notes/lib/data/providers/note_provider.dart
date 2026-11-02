import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/db.dart';
import '../local/note.dart';
import '../repositories/note_repository.dart';
import '../services/sync_service.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(openDb: openNotesDb);
});

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle(bool value) {
    state = value;
  }
}

final dirtyCountProvider = FutureProvider<int>((ref) async {
  ref.watch(noteListProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return await repo.countDirty();
});

final noteListProvider = AsyncNotifierProvider<NoteListNotifier, List<Note>>(
  NoteListNotifier.new,
);

class NoteListNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final repo = ref.watch(noteRepositoryProvider);
    return await repo.fetchNotes();
  }

  Future<void> addNote(String title, String body) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.addNote(title: title, body: body);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.fetchNotes());
  }

  Future<void> syncData() async {
    final isOffline = ref.read(forceOfflineProvider);
    if (isOffline) {
      throw Exception("Sinkronisasi ditolak: Sedang dalam mode Force Offline.");
    }

    final repo = ref.read(noteRepositoryProvider);
    await SyncService.syncNotes(repo);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.fetchNotes());
  }
}

// --- FITUR SEARCH (WEEK 9 AI-ASSISTED DEVELOPMENT) ---

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Fungsi murni penyaring catatan: case-insensitive & sanitasi whitespace
List<Note> filterNotes(List<Note> notes, String query) {
  final cleanQuery = query.trim().toLowerCase();
  if (cleanQuery.isEmpty) return notes;
  return notes
      .where((note) => note.title.toLowerCase().contains(cleanQuery))
      .toList();
}

/// Provider daftar catatan yang telah terfilter berdasarkan query pencarian
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesAsync = ref.watch(noteListProvider);
  final query = ref.watch(searchQueryProvider);

  return notesAsync.whenData((notes) => filterNotes(notes, query));
});

final noteDetailProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final repo = NoteRepository();
  return await repo.getNoteById(id);
});
