import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers/note_provider.dart';

class NoteDetailPage extends ConsumerWidget {
  final int noteId;

  const NoteDetailPage({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca data spesifik dari SQLite menggunakan noteId
    final noteAsync = ref.watch(noteDetailProvider(noteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
      ),
      body: noteAsync.when(
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Catatan tidak ditemukan.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Terakhir diubah: ${note.updatedAt.toLocal().toString().split('.')[0]}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  note.body,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}