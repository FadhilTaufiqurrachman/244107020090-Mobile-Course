import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/db.dart';
import '../local/note.dart';
import '../repositories/note_repository.dart';
import '../services/sync_service.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(openDb: openNotesDb);
});

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

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