import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

// 1. Mengubah StatelessWidget menjadi ConsumerWidget agar bisa membaca Provider
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  // 2. Menambahkan parameter WidgetRef ref sebagai alat baca Riverpod
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. Memantau (watch) state dari statsProvider secara reaktif
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Data Statistik')),
      // 4. Menggunakan metode .when() untuk memaksa penanganan 3 kondisi asinkron
      body: statsAsync.when(
        
        // Kondisi A: Menampilkan spinner saat data sedang diambil
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        
        // Kondisi B: Menampilkan pesan dan tombol Retry saat simulasi 30% gagal terjadi
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Terjadi Kesalahan:\n$err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                // Memanggil ref.invalidate membuang state lama dan memicu build() ulang
                onPressed: () => ref.invalidate(statsProvider),
                child: const Text('Coba Lagi (Retry)'),
              ),
            ],
          ),
        ),
        
        // Kondisi C: Menampilkan ListView 3 item jika pengambilan data berhasil
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.analytics)),
              title: Text(stats[index]),
            );
          },
        ),
        
      ),
    );
  }
}