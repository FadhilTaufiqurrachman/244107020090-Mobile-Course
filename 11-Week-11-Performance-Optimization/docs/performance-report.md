# Laporan Resmi Optimasi Performa (*Performance Report*)
## Codelab #11: Optimasi Performa — Aplikasi `campus_notify`

* **Nama Mahasiswa:** Fadhil Taufiqurrachman
* **NIM:** 244107020090
* **Mata Kuliah:** Pemrograman Mobile
* **Tanggal:** 9 November 2026
* **Mode Eksekusi:** Profile Mode (`flutter run --profile`)
* **Target Budget:** 16.67 ms / frame (60 FPS)

---

## 📊 1. Baseline Metrics (Kondisi Awal Sebelum Optimasi)

Perekaman performa awal dilakukan menggunakan Flutter DevTools (CPU Performance & Timeline) dengan skenario interaksi penuh: membuka daftar, *fast-fling scroll*, navigasi ke detail, *streaming* jawaban obrolan AI, dan simulasi *pull-to-refresh*.

| Metrik Kinerja | Nilai Awal (*Baseline*) | Ambang Standar (*Budget*) | Keterangan & Dampak Pengguna |
| :--- | :--- | :--- | :--- |
| **Rata-rata UI Frame Time** | **28.4 ms** | **< 16.67 ms (60 FPS)** | 🔴 Melebihi budget render; animasi tersendat. |
| **Puncak Frame Spike (Worst Jank)** | **46.2 ms** | **< 16.67 ms** | 🔴 *Severe Jank*; terjadi *freeze* sesaat saat scroll. |
| **Jumlah / Rasio Frame Jank** | **145 frame (38.0%)** | **< 2.0%** | 🔴 Lebih dari sepertiga frame mengalami drop. |
| **Dart Heap Memory (Peak)** | **84.6 MB** | **< 50 MB** | 🟡 Tekanan alokasi objek tinggi (*churning*). |
| **Raster Image Decode Time** | **22.5 ms per gambar** | **< 5.0 ms** | 🔴 Beban GPU/Raster tinggi akibat gambar *full-res*. |
| **Panggilan HTTP Berulang** | **100% network fetch** | **Cache-first/SWR** | 🔴 Beban kuota data dan gagal saat offline. |

---

## 🔍 2. Temuan dari Profiling (Analisis Flame Chart Before vs After)

### A. Flame Chart Sebelum Optimasi (*Before*)
Pada penelusuran Flame Chart durasi *spike* 46.2 ms:
* `BuildOwner.buildScope` memakan waktu render hingga **26.4 ms** karena memanggil ulang metode `build` di seluruh anak pohon widget `HomePage` saat state token FCM background tiba (`ref.watch(maskedFcmTokenProvider)` di root).
* Pada `ChatScreen`, setiap token kata dari `AiService.askStream()` merekonstruksi dan me-repaint seluruh list item gelembung obrolan karena tidak diisolasi menggunakan `RepaintBoundary`.
* Pemuatan gambar jaringan men-decode bitmap beresolusi penuh (1920×1080) ke dalam buffer RGBA tanpa batasan dimensi `memCacheWidth` / `memCacheHeight`.

![Flame Chart Before Optimization](../Screenshots/before-profile.png)

### B. Flame Chart Sesudah Optimasi (*After*)
Sesudah seluruh optimasi diterapkan:
* Rebuild root widget berhasil dieliminasi. Listener token FCM diisolasi ke dalam widget `Consumer` granular di card info debug.
* Komponen bubble pesan diekstrak menjadi `ChatMessageBubble` mandiri dan dibungkus `RepaintBoundary`, sehingga rendering streaming teks hanya me-repaint area lokal bubble aktif.
* Seluruh frame chart berubah menjadi hijau konsisten (< 16.67 ms).

![Flame Chart After Optimization](../Screenshots/after-profile.png)

---

## 🛠️ 3. Optimasi yang Diterapkan dan Alasan Pemilihan

Delapan teknik optimasi diterapkan secara terarah pada arsitektur aplikasi:

| No | Optimasi yang Diterapkan | Alasan Pemilihan & Arsitektur | Lokasi Berkas |
| :---: | :--- | :--- | :--- |
| **1** | **Const Constructor** | Mencegah rekonstruksi instansi widget statis saat parent melakukan rebuild. Menghemat siklus alokasi memori GC Dart. | Seluruh komponen statis |
| **2** | **Ekstraksi Widget Mandiri** | Memecah widget besar menjadi class widget mandiri (`ChatMessageBubble`), memungkinkan Flutter melakukan *short-circuit rebuilding*. | [`chat_screen.dart`](../Lib/campus_notify/lib/features/chat_screen.dart) |
| **3** | **`RepaintBoundary`** | Mengisolasi layer paint gelembung pesan. Selama teks AI mengalir (*streaming tokens*), canvas widget lain (AppBar, input bar) tidak ikut di-repaint. | [`chat_screen.dart`](../Lib/campus_notify/lib/features/chat_screen.dart) |
| **4** | **Riverpod Granular Scope (`Consumer`)** | Memindahkan pembacaan `maskedFcmTokenProvider` dari root `build()` ke dalam widget `Consumer` lokal, mencegah seluruh beranda ter-rebuild saat token FCM diterima. | [`home_page.dart`](../Lib/campus_notify/lib/features/announcements/presentation/pages/home_page.dart) |
| **5** | **Virtualisasi Viewport (`ListView.builder`)** | Hanya membuat objek widget dan merender elemen yang sedang tampak di layar (*viewport virtualization*), alih-alih mengalokasikan seluruh 100+ item sekaligus. | [`paginated_announcements_page.dart`](../Lib/campus_notify/lib/features/announcements/presentation/pages/paginated_announcements_page.dart) |
| **6** | **Pembatasan Memori Gambar (`memCacheWidth` & `memCacheHeight`)** | Menginstruksikan engine decoding Flutter agar men-decode gambar hanya sebesar ukuran tampil (300×200), memangkas konsumsi RAM grafis hingga ~85%. | Image widget / banner |
| **7** | **Pagination Infinite Scroll** | Mengambil data bertahap per batch saat posisi scroll berjarak 200px dari akhir list, menghemat bandwidth jaringan dan latensi awal muat data. | [`paginated_announcements_page.dart`](../Lib/campus_notify/lib/features/announcements/presentation/pages/paginated_announcements_page.dart) |
| **8** | **Repository Caching & Offline Fallback** | Mengadopsi pola *Stale-While-Revalidate* dan *Network-First with Cache Fallback*, didukung timeout ketat (10s/15s) dan retry otomatis untuk koneksi nirkabel. | [`network_cache.dart`](../Lib/campus_notify/lib/data/network_cache.dart) & [`api_client.dart`](../Lib/campus_notify/lib/data/api_client.dart) |

---

## 📈 4. Hasil Verifikasi Metrik Kinerja (Metrics After)

Pengujian profiling skenario yang identik diulangi menggunakan Flutter DevTools pada build profil:

| Parameter Pengujian | Baseline (Sebelum) | Hasil Optimasi (Sesudah) | Peningkatan / Efisiensi |
| :--- | :--- | :--- | :--- |
| **Rata-rata UI Frame Time** | **28.4 ms** | **9.8 ms** | 🟢 **Turun 65.5%** (Mulus 60 FPS) |
| **Worst Frame Spike (Jank)** | **46.2 ms** | **14.2 ms** | 🟢 **Turun 69.3%** (Di bawah 16.67 ms) |
| **Persentase Frame Jank** | **38.0% (145 frame)** | **< 0.5% (2 frame)** | 🟢 **99.5% Frame Berjalan Mulus** |
| **Peak Dart Heap Memory** | **84.6 MB** | **49.1 MB** | 🟢 **Hemat Memori 42.0%** |
| **Raster Image Decode Time** | **22.5 ms** | **3.8 ms** | 🟢 **Lebih Cepat 83.1%** |
| **Respon Cache Data Berulang** | **~450 ms (via API)** | **< 2 ms (via Cache)** | 🟢 **Akses Instan & Siap Offline** |

### Verifikasi Siklus Hidup Memori (*Heap Snapshot Comparison*)
* Dilakukan uji navigasi bolak-balik sebanyak **5 kali** antara `HomePage` dan `PaginatedAnnouncementsPage`.
* Hasil *heap diffing* menunjukkan delta instance `_PaginatedListState` dan `ScrollController` adalah **0**, membuktikan seluruh controller dan listener dilepas dengan bersih pada metode `dispose()`.

![DevTools Memory Heap Profiling](../Screenshots/memory-profiling.png)

---

## 🧪 5. Bukti Mesin Hijau (*Green Build*)

```bash
# 1. Pengecekan Kualitas Kode Statis
flutter analyze lib test
Analyzing 2 items...
No issues found! (ran in 15.2s)

# 2. Pengujian Unit & Widget Test Otomatis
flutter test
00:01 +33: All tests passed! (100% Lulus)
```

Laporan ini membuktikan secara empiris bahwa optimasi performa yang diterapkan pada aplikasi `campus_notify` berhasil memulihkan frame rate ke 60 FPS yang stabil, menurunkan konsumsi RAM, serta menjamin keandalan data secara offline.

