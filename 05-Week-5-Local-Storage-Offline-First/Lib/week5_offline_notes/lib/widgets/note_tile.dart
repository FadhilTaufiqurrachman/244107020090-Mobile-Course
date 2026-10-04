import 'package:flutter/material.dart';
import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(
        note.body,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Menampilkan badge/ikon jika data masih 'dirty'
      trailing: note.dirty
          ? const Tooltip(
              message: 'Belum tersinkron',
              child: Icon(Icons.cloud_off, color: Colors.orange, size: 20),
            )
          : null,
      onTap: onTap,
    );
  }
}