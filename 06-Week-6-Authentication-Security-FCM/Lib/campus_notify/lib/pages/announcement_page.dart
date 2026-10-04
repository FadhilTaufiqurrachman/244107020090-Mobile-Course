import 'package:flutter/material.dart';

class AnnouncementPage extends StatelessWidget {
  final String id;
  
  const AnnouncementPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign, size: 100, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              'Membaca Pengumuman #$id',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Ini adalah simulasi halaman yang terbuka ketika pengguna mengklik notifikasi FCM yang berisi data payload route.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}