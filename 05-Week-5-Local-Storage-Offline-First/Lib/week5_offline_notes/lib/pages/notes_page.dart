import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 
import '../data/providers/note_provider.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(noteListProvider);
    final isOffline = ref.watch(forceOfflineProvider);
    final dirtyCountAsync = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          Row(
            children: [
              const Text('Offline', style: TextStyle(fontSize: 12)),
              Switch(
                value: isOffline,
                activeThumbColor: Colors.red,
                onChanged: (val) {
                  ref
                      .read(forceOfflineProvider.notifier)
                      .toggle(val); 
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val
                            ? 'Simulasi Offline AKTIF'
                            : 'Simulasi Offline NONAKTIF',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: isOffline
                    ? null
                    : () async {
                        try {
                          await ref.read(noteListProvider.notifier).syncData();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sinkronisasi Berhasil'),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
              ),
              dirtyCountAsync.when(
                data: (count) => count > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            // Mengubah Navigator.push menjadi GoRouter context.push
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('Belum ada catatan.'));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteTile(
                note: note,
                onTap: () {
                  // Navigasi ke halaman detail berdasarkan ID
                  context.push('/note/${note.id}');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref
              .read(noteListProvider.notifier)
              .addNote(
                'Catatan Uji Coba',
                'Dibuat pada: ${DateTime.now().toString().split('.')[0]}',
              );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}