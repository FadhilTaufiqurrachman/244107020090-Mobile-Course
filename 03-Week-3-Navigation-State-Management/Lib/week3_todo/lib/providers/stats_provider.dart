import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Mendefinisikan AsyncNotifier dengan tipe kembalian List<String>
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    // 2. Simulasi delay jaringan selama 2 detik menggunakan Future.delayed
    await Future.delayed(const Duration(seconds: 2));

    // 3. Simulasi kemungkinan gagal 30% menggunakan Random
    final randomChance = Random().nextDouble();
    if (randomChance < 0.3) {
      // Melempar exception jika nilai random di bawah 0.3 (30% peluang)
      throw Exception('Gagal mengambil data statistik dari server.');
    }

    // 4. Jika sukses (melewati blok if di atas), kembalikan List berisi 3 item
    return [
      'Total Pengguna Aktif: 1,540',
      'Pendapatan Bulan Ini: Rp 24.500.000',
      'Tingkat Konversi: 4.8%'
    ];
  }
}

// 5. Membuat provider global agar StatsNotifier bisa diakses oleh UI
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);