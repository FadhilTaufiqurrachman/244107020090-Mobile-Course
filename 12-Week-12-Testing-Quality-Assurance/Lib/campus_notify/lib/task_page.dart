import 'package:flutter/material.dart';
import 'is_valid_task_title.dart';

/// Halaman antarmuka daftar dan penambahan tugas untuk pengujian widget
class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final _controller = TextEditingController();
  final List<String> _tasks = [];
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveTask() {
    final title = _controller.text;
    if (!isValidTaskTitle(title)) {
      setState(() {
        _errorMessage = 'Judul tugas tidak boleh kosong';
      });
      return;
    }

    setState(() {
      _tasks.add(title.trim());
      _controller.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar tugas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('task-title-field'),
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Judul Tugas Baru',
                hintText: 'Masukkan judul tugas...',
                errorText: _errorMessage,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('save-task-button'),
              onPressed: _saveTask,
              child: const Text('Simpan Tugas'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tugas Tersimpan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(
                      child: Text('Belum ada tugas tersimpan'),
                    )
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text(_tasks[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
