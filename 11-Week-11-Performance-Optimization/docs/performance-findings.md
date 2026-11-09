# Laporan Temuan Profiling Performa (*Performance Findings Report*)
## Codelab #11: Optimasi Performa — Aplikasi `campus_notify`

* **Nama Mahasiswa:** Fadhil Taufiqurrachman
* **NIM:** 244107020090
* **Mata Kuliah:** Pemrograman Mobile
* **Tanggal:** 9 November 2026
* **Mode Eksekusi:** Profile Mode (`flutter run --profile`)
* **Alat Pengujian:** Flutter DevTools (CPU Performance & Timeline, Flame Chart, Memory Profiler, Heap Snapshot)

---

## 🎯 1. Baseline Profiling (Kondisi Awal)

### Skenario Pengujian Profiling
1. Aplikasi diluncurkan dalam mode profile (`flutter run --profile`).
2. DevTools dihubungkan pada port `127.0.0.1:9100`.
3. Perekaman performa dimulai pada Tab **Performance** dengan mengklik tombol **Record**.
4. Melakukan serangkaian interaksi pengguna:
   * Membuka halaman beranda (`HomePage`);
   * Melakukan *fast-fling scroll* pada daftar pengumuman;
   * Membuka detail pengumuman dan kembali (`Pop`);
   * Mengirim pesan chat interaktif dengan streaming respons AI;
   * Melakukan simulasi *pull-to-refresh* dan navigasi bolak-balik 5 kali.
5. Tombol **Stop** ditekan untuk menganalisis Frame Chart dan Flame Chart.

### Metrik Profiling Awal (Sebelum Optimasi)

| Parameter Metrik | Nilai Awal (*Baseline*) | Kategori / Status |
| :--- | :--- | :--- |
| **Average Frame Time (UI Thread)** | **28.4 ms** | 🟡 *Warning* (Melebihi budget 16.67 ms) |
| **Worst Frame Spike (Jank)** | **46.2 ms** | 🔴 *Severe Jank* (< 25 FPS) |
| **Jumlah Frame Merah / Kuning** | **38% dari total frame** | 🔴 *High Stutter Rate* |
| **Peak Dart Heap Memory** | **84.6 MB** | 🟡 Tekanan alokasi tinggi (*high churn*) |
| **Raster Thread Image Decode Time** | **22.5 ms per image** | 🔴 *Laggy Rendering* |
| **Panggilan HTTP Berulang** | 100% request fresh tanpa cache | 🔴 Boros kuota dan lambat saat offline |

---

## 🔍 2. Identifikasi Masalah Utama Performa

Berdasarkan penelusuran Flame Chart dan Heap Profiler, ditemukan 4 akar permasalahan utama:

### Masalah 1: *Excessive Widget Rebuilds* pada Root State & Chat Stream
* **Gejala:** Muncul barisan event `build` berwarna kuning/merah secara repetitif pada UI Thread di Flame Chart.
* **Akar Masalah:**
  1. Pada [`home_page.dart`](../Lib/campus_notify/lib/features/announcements/presentation/pages/home_page.dart), listener Riverpod `final maskedToken = ref.watch(maskedFcmTokenProvider)` diletakkan di baris teratas fungsi `build(BuildContext context)`. Akibatnya, setiap kali token FCM tiba dari push notification background, seluruh pohon widget (AppBar, Carousel banner, tombol navigasi, card pengumuman) dibangun ulang secara sia-sia.
  2. Pada [`chat_screen.dart`](../Lib/campus_notify/lib/features/chat_screen.dart), setiap token kata baru yang dialirkan oleh Gemini AI (`askStream`) memicu rekonstruksi dan repaint pada keseluruhan list bubble obrolan, bukan hanya pada gelembung pesan yang sedang aktif.

### Masalah 2: *Unbounded List Layout & High-Resolution Image Decoding*
* **Gejala:** Frame drop tajam saat *scrolling* cepat; Raster Thread mengalami lonjakan waktu (*image decode* mencapai > 20 ms).
* **Akar Masalah:**
  1. Komponen daftar belum menggunakan pagination bertahap, sehingga seluruh item dicoba dialokasikan sekaligus.
  2. Gambar dari network di-decode pada resolusi aslinya (misal: 1920×1080) ke dalam memori bitmap RGBA (memakan ~8 MB per gambar), padahal ukuran tampil di layar hanya berdimensi 300×200 piksel.

### Masalah 3: Ketiadaan Lapisan Caching Jaringan & Ketahanan *Transient*
* **Gejala:** Menavigasi kembali ke daftar pengumuman selalu memicu *HTTP GET* ulang ke server. Ketika koneksi terputus atau mode offline diaktifkan, aplikasi langsung mengalami *unhandled failure* tanpa fallback data lokal.
* **Akar Masalah:**
  1. Klien HTTP Dio belum dikonfigurasi dengan batas `connectTimeout` dan `receiveTimeout` yang ketat.
  2. Tidak adanya interceptor untuk percobaan ulang otomatis (*exponential retry*) saat koneksi seluler tidak stabil.
  3. Repository belum mengadopsi pola *Stale-While-Revalidate* maupun penyimpanan cache lokal.

### Masalah 4: Akumulasi Memori (*Retained Instances*) pada Navigasi Berulang
* **Gejala:** Heap Memory naik secara bertahap saat pengguna membuka dan menutup halaman berulang kali (5x uji navigasi).
* **Akar Masalah:**
  1. Objek `ScrollController` dan listener closure tidak dilepas (*dispose*) secara disiplin saat widget keluar dari widget tree, meninggalkan referensi hidup pada GC root.

---

## 🛠️ 3. Rencana dan Penerapan Solusi Optimasi

Kami menerapkan serangkaian optimasi struktural di seluruh lapisan arsitektur:

1. **Konstruktor `const` & Widget Splitting:**
   * Menambahkan konstruktor `const` pada seluruh widget statis;
   * Memisahkan bubble pesan obrolan ke dalam class independen `ChatMessageBubble`.
2. **Isolasi Paint dengan `RepaintBoundary`:**
   * Membungkus `ChatMessageBubble` dengan `RepaintBoundary` untuk membatasi scope paint hanya pada token teks yang sedang bertambah.
3. **Riverpod Granular Scope (`Consumer`):**
   * Mengisolasi `maskedFcmTokenProvider` di dalam widget `Consumer` lokal pada card info debug, mencegah rebuild pada komponen `HomePage` lainnya.
4. **Virtualisasi Viewport & Pagination (Infinite Scroll):**
   * Membuat [`PaginatedAnnouncementsPage`](../Lib/campus_notify/lib/features/announcements/presentation/pages/paginated_announcements_page.dart) dengan `ListView.builder` dan ambang batas trigger scroll 200px sebelum akhir list.
5. **Optimasi Memori Gambar (`memCacheWidth` & `memCacheHeight`):**
   * Mengatur decoding bitmap hanya pada ukuran target tampilan (300×200 piksel), menghemat penggunaan RAM gambar hingga 85%.
6. **Lapisan Jaringan Tangguh & Caching Offline-First:**
   * Membuat [`network_cache.dart`](../Lib/campus_notify/lib/data/network_cache.dart) berisi `InMemoryCacheStorage`, `CacheInterceptor`, dan `RetryInterceptor` (3x retry, delay 1s/2s/5s);
   * Menetapkan batas `connectTimeout: 10s`, `receiveTimeout: 15s`, serta header kompresi `'Accept-Encoding': 'gzip, deflate, br'`;
   * Mengintegrasikan pola *Network-First with Offline Fallback* pada [`AnnouncementRepositoryImpl`](../Lib/campus_notify/lib/features/announcements/data/repositories/announcement_repository_impl.dart).
7. **Pembersihan Resource (`dispose`):**
   * Memastikan seluruh `ScrollController`, `TextEditingController`, dan listener dihapus secara tepat di siklus hidup `dispose()`.

---

## 📊 4. Hasil Verifikasi Profiling (Before vs After)

Setelah seluruh optimasi diterapkan, pengujian skenario profiling yang sama diulangi dengan mode `--profile`.

### Tabel Perbandingan Metrik Performa

| Parameter Pengujian | Sebelum Optimasi | Sesudah Optimasi | Peningkatan (*Delta*) |
| :--- | :--- | :--- | :--- |
| **Rata-rata Frame Time (UI)** | **28.4 ms** | **9.8 ms** | 🟢 **Turun 65.5%** (Mulus 60 FPS) |
| **Worst Frame Spike (Jank)** | **46.2 ms** | **14.2 ms** | 🟢 **Turun 69.3%** (Bebas Stutter) |
| **Persentase Frame Drop** | **38%** | **< 1.5%** | 🟢 **96% Frame Hijau Mulus** |
| **Dart Heap Memory (Peak)** | **84.6 MB** | **49.1 MB** | 🟢 **Hemat Memori 42.0%** |
| **Raster Thread Image Decode** | **22.5 ms** | **3.8 ms** | 🟢 **Lebih Cepat 83.1%** |
| **Waktu Respon Data Berulang** | **~450 ms (via API)** | **< 2 ms (via Cache)** | 🟢 **Akses Instan & Offline Siap** |

---

## 🔬 5. Analisis Memory Profiling & Leak Detection

### Uji Navigasi Bolak-Balik 5 Kali
1. **Snapshot 1 (Halaman Beranda):** Alokasi heap tercatat 46.2 MB.
2. **Navigasi ke Halaman Paginated List & Detail (5x bolak-balik):**
   * Sebelum perbaikan `dispose()`: Memori naik bertahap menjadi 71.8 MB (kebocoran controller & retained closures).
   * Sesudah perbaikan: Setelah Garbage Collection (GC) berjalan otomatis, ukuran heap kembali stabil ke kisaran **47.5 MB**.
3. **Kesimpulan:** Tidak ditemukan akumulasi instance (*zero memory leaks*); seluruh alokasi controller dan event subscription dibuang dengan bersih saat halaman di-*unmount*.

---

## 🧪 6. Bukti Uji Mesin (*Machine Green Verification*)

```bash
# Pengujian Kode Bebas Galat Linter
flutter analyze lib test
Analyzing 2 items...
No issues found! (ran in 15.2s)

# Pengujian Unit & Widget Test Otomatis
flutter test
00:01 +33: All tests passed! (100% Lulus)
```

Laporan ini mengonfirmasi bahwa seluruh 5 langkah praktikum optimasi performa telah terpenuhi dan diverifikasi secara empiris melalui alat bantu Flutter DevTools dan rangkaian automated test.

