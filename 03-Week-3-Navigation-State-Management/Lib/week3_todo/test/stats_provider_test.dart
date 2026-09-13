import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Sesuaikan path import dengan nama project Anda
import 'package:week3_todo/providers/stats_provider.dart'; 

void main() {
  test('statsProvider memulai dengan loading, lalu bertransisi ke data atau error', () async {
    // 1. Membuat wadah terisolasi (ProviderContainer) khusus untuk testing
    final container = ProviderContainer();
    
    // 2. Membersihkan container setelah test selesai agar tidak bocor ke test lain
    addTearDown(container.dispose);

    // 3. Memverifikasi state awal adalah AsyncLoading
    expect(
      container.read(statsProvider),
      const AsyncValue<List<String>>.loading(),
    );

    // 4. Menunggu fungsi build() selesai dieksekusi (selama 2 detik)
    // catchError digunakan agar test tidak crash jika masuk ke simulasi gagal 30%
    await container.read(statsProvider.future).catchError((_) => <String>[]);

    // 5. Membaca state akhir setelah proses asinkron selesai
    final finalState = container.read(statsProvider);

    // 6. Memverifikasi bahwa state akhir pastilah salah satu dari Data atau Error
    // (Karena ada faktor Random 30%, kita tidak bisa memastikan 100% akan selalu sukses)
    expect(
      finalState.hasValue || finalState.hasError,
      isTrue,
    );
  });
} 