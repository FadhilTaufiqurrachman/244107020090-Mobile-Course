# Minggu 11 — Optimasi Performa

> Dokumentasi Praktikum Mata Kuliah **Pemrograman Mobile**.

[![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Performance](https://img.shields.io/badge/Performance-60%2F120%20FPS-4CAF50?logo=speedtest&logoColor=white)](#)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-009688)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![DevTools](https://img.shields.io/badge/Profiling-Flutter%20DevTools-02569B?logo=googlechrome&logoColor=white)](#)
[![Riverpod](https://img.shields.io/badge/State%20Management-Riverpod-1976D2)](https://riverpod.dev/)

## 🧭 Ringkasan

Minggu kesebelas berfokus pada **Optimasi Performa Aplikasi Mobile Flutter (Performance Optimization)**. Melanjutkan proyek **Campus Notify** dari Minggu 7–10, praktikum ini membekali mahasiswa dengan keahlian teknis untuk menganalisis performa runtime menggunakan **Flutter DevTools (CPU & Memory Profiling)**, mengeliminasi rendering yang boros (*unnecessary widget rebuilds*), menerapkan **Lazy Loading, Pagination, & Image Optimization**, serta menyempurnakan efisiensi pertukaran data melalui **Network Caching & Offline-First Strategy**.

## 🎯 Tujuan Pembelajaran

Setelah menyelesaikan praktikum ini, saya diharapkan mampu:

1. Menggunakan **Flutter DevTools** untuk melakukan profiling CPU, timeline frames (60/120 FPS), dan alokasi memori (heap & memory leak);
2. Mengidentifikasi serta mengurangi **widget rebuild yang tidak diperlukan** menggunakan `const` constructor, widget splitting, dan selektor Riverpod (`select`);
3. Menerapkan **lazy loading, pagination (infinite scroll), dan optimasi gambar** (cache & ukuran terukur);
4. Mengoptimalkan komunikasi jaringan dengan menerapkan **caching HTTP** dan strategi **offline-first**;
5. Memperbaiki *bottleneck* performa nyata pada aplikasi yang sudah ada dan membuktikan perbaikannya secara terukur.

## 🧰 Teknologi dan Tools

| Komponen | Penggunaan |
| :--- | :--- |
| **Dart (3.13.2)** | Bahasa pemrograman utama aplikasi Flutter dan unit profiling |
| **Flutter SDK** | Framework UI mobile multiplatform berbasis Material 3 |
| **Flutter DevTools** | Suite profiling visual: CPU Profiler, Memory Allocations, Performance Timeline |
| **Flutter Riverpod** | Reactive state management dengan optimasi granular rebuild (`ref.watch(provider.select(...))`) |
| **Clean Architecture** | Pemisahan Presentation, Domain, dan Data layer untuk memudahkan optimasi terisolasi |
| **Visual Studio Code** | IDE utama dengan ekstensi Flutter/Dart & integrasi DevTools |

## 📂 Struktur Folder

```text
244107020090-Mobile-Course/
└── 11-Week-11-Performance-Optimization/
    ├── README.md                                      # Laporan lengkap praktikum Minggu 11
    ├── docs/                                          # Dokumen analisis profiling & log optimasi
    ├── Screenshots/                                   # Bukti tangkapan layar DevTools & pengujian
    └── Lib/
        └── campus_notify/                             # Proyek Flutter yang dioptimasi
            ├── lib/                                   # Source code teroptimasi
            └── test/                                  # Automated tests
```

## 🚀 Cara Menjalankan

### Persyaratan

- Flutter SDK (>= 3.47.0) dan Dart SDK (>= 3.13.0);
- Perangkat Android fisik atau Emulator Android dengan mode **profile / release** untuk pengukuran akurat;
- Flutter DevTools (`dart devtools` atau terintegrasi di VS Code).

Verifikasi kesiapan awal:

```bash
flutter --version
flutter doctor -v
```

Jalankan aplikasi dalam mode **profile** untuk profiling performa tanpa overhead debug banner:

```bash
flutter run --profile
```

---

## 📖 1. Selamat Datang & Persiapan

### Kebijakan Penggunaan AI
> 💡 **Kebijakan AI Minggu 11:**  
> Minggu 11 merupakan materi lanjutan yang memperbolehkan penggunaan AI secara bijak: AI boleh membantu menganalisis hasil profiling dan menyarankan optimasi, namun developer **wajib memverifikasi dengan profiling nyata pada Flutter DevTools**, menguji, me-refactor kode, serta menjelaskan keputusan teknis tanpa bergantung pada AI. Penilaian didasarkan pada kualitas verifikasi dan alasan keputusan teknis, bukan banyaknya kode yang dihasilkan AI.

---

## ⚡ 2. Konsep Optimasi Performa Flutter

### 1. Mengapa Optimasi Performa Sangat Penting?

Aplikasi mobile modern dituntut untuk selalu responsif, hemat daya baterai, dan berjalan stabil di berbagai spesifikasi gawai (low-end hingga flagship). Ketiadaan optimasi performa dapat menimbulkan dampak fatal:
* **Frame Drop (*Jank*):** Antarmuka visual patah-patah dan gagal mempertahankan target 60 FPS atau 120 FPS.
* **Konsumsi Memori Berlebih (*High Memory Footprint*):** Kebocoran memori (*memory leak*) memicu sistem operasi Android/iOS menghentikan aplikasi secara paksa (*Out of Memory / OOM Kill*).
* **Baterai Cepat Habis (*Battery Drain*):** CPU dan GPU bekerja terus-menerus akibat komputasi berat di UI thread dan render loop yang boros.
* **Pengalaman Pengguna Buruk (*Poor UX*):** Pengguna meninggalkan ulasan buruk (*rating drop*) dan mencopot aplikasi (*churn*).

### 2. Pipeline Rendering Flutter & Konsep Frame Budget

```text
       UI Thread (Dart VM)                          Raster Thread (GPU)
+-------------------------------+             +-------------------------------+
| 1. Build Widget (Widget Tree) |             |                               |
| 2. Layout (Render Tree)       | ----------> | 1. Composite (Scene)          |
| 3. Paint (Drawing Commands)   |             | 2. Rasterize (Pixels to Screen|
+-------------------------------+             +-------------------------------+
                |                                             |
                v                                             v
        [ Frame Budget: 16.67 ms (60 FPS)  |  8.33 ms (120 FPS Promotion) ]
```

* **UI Thread (Dart):** Mengeksekusi kode Dart aplikasi kita (`build()`, menghitung ukuran `layout()`, dan menyusun perintah `paint()`). Seluruh tahapan ini wajib selesai dalam waktu **< 16.67 ms** (untuk 60 FPS) atau **< 8.33 ms** (untuk 120 FPS).
* **Raster Thread (GPU):** Menerima instruksi grafis dari UI thread dan menggambar piksel aktual ke layar (*rasterization*). Operasi ini rentan menjadi *bottleneck* apabila memuat gambar beresolusi terlampau besar, efek blur berlebihan, atau *layer saveLayer* yang tidak efisien.
* **Jank (Frame Drop):** Terjadi manakala waktu komputasi salah satu thread melampaui alokasi *frame budget*, sehingga frame yang seharusnya ditampilkan terlewat (*skipped frame*).

### 3. Kategori Optimasi Utama pada Flutter

| Kategori | Area Fokus & Masalah Umum | Alat Analisis & Solusi |
| :--- | :--- | :--- |
| **CPU / Build** | *Unnecessary widget rebuilds*, layout pass berulang, perhitungan berat di dalam fungsi `build()`. | **DevTools Performance & Timeline**, penggunaan `const` constructor, widget splitting, dan Riverpod `.select()`. |
| **Memori** | Kebocoran objek (*memory leak*), controller/stream yang lupa di-`dispose()`, gambar tanpa batas memori cache. | **DevTools Memory & Heap Snapshot**, pelepasan referensi lifecycle, dan *image cache resizing*. |
| **Jaringan** | Permintaan HTTP berulang, payload JSON raksasa, tanpa caching lokal. | **DevTools Network Profiler & Dio Interceptors**, strategi *offline-first*, dan *in-memory/SQLite cache*. |
| **Gambar & Aset** | Resolusi gambar asli jauh melebihi ukuran widget tampilan, format grafis tidak efisien. | `cached_network_image`, konfigurasi `cacheWidth` / `cacheHeight`, dan pemuatan gambar secara *lazy*. |

---

## 🛠️ 3. Flutter DevTools: Profiling CPU dan Memori

Flutter DevTools adalah paket peralatan diagnostik dan profiling visual yang berjalan di browser untuk menganalisis performa runtime aplikasi Flutter.

### 1. Membuka DevTools dalam Mode Profile

> ⚠️ **Catatan Kritis Mode Eksekusi:**  
> Selalu jalankan profiling pada **`--profile` mode** (bukan `--debug` atau `--release`).  
> * *Debug mode:* Memiliki overhead kompilasi JIT, assert checks, dan debug banner yang menghasilkan data performa tidak akurat (*false positive jank*).  
> * *Release mode:* Kode di-compile AOT secara maksimal namun menonaktifkan service observatory/profiling extension.  
> * *Profile mode:* Menggunakan kompilasi AOT nyata seperti rilis produksi, tetapi tetap mengaktifkan port tracing untuk DevTools.

Perintah menjalankan aplikasi dalam mode profile:

```bash
# Menjalankan pada perangkat default
flutter run --profile

# Menjalankan pada perangkat/emulator spesifik
flutter run -d <device_id> --profile
```

DevTools dapat dibuka melalui URL yang dicetak di terminal (biasanya `http://127.0.0.1:9100`) atau melalui tombol **Open DevTools** pada status bar VS Code.

### 2. Tab Performance (CPU & Frame Profiling)

Tab Performance memvisualisasikan rendering tiap frame untuk mendeteksi *jank* (frame drop):

* **Frame Chart:** Menampilkan grafik batang horizontal untuk setiap frame yang dirender oleh aplikasi:
  * 🟢 **Hijau (< 16.67 ms):** Frame berjalan mulus dan memenuhi target 60 FPS (atau < 8.33 ms untuk 120 FPS).
  * 🟡 **Kuning (16 – 32 ms):** Frame lambat, berpotensi menimbulkan *micro-stutter*.
  * 🔴 **Merah (> 32 ms):** Frame sangat lambat (*severe jank*), menyebabkan animasi tersendat nyata.
* **Flame Chart (Call Stack):** Memvisualisasikan hirarki eksekusi fungsi secara bertingkat:
  * Sumbu horizontal menunjukkan durasi waktu eksekusi fungsi;
  * Sumbu vertikal menunjukkan kedalaman *call stack*;
  * Memudahkan pencarian fungsi paling atas yang memakan waktu eksekusi abnormal.
* **UI Thread Track:** Menelusuri fase `build`, `layout`, dan `paint` pada kode Dart.
* **Raster Thread Track:** Menelusuri fase komputasi GPU, pemrosesan shader, dan decoding gambar.

### 3. Tab Memory (Memory Profiling & Leak Detection)

Tab Memory memantau alokasi dan siklus hidup objek di dalam heap Dart VM:

* **Heap Size & Usage:** Memantau akumulasi total memori Dart (heap) dan alokasi memori native (grafis, texture, decoding gambar).
* **GC Events (Garbage Collection):** Frekuensi GC yang terlalu sering mengindikasikan adanya tekanan alokasi objek sementara (*churning*) yang tinggi pada fungsi `build()`.
* **Heap Snapshot & Class Filter:** Mengambil foto instan alokasi objek saat ini, mengurutkan berdasarkan ukuran memori atau jumlah instance, serta mencari referensi objek yang tertinggal (*retained size*).
* **Leak Detection:** Membandingkan snapshot sebelum dan sesudah navigasi (misal: buka halaman -> kembali ke beranda). Jika instance Controller, Notifier, atau State tidak berkurang, terjadi kebocoran memori (*memory leak*).

### 4. Alur Praktik Profiling (6 Langkah Terstandar)

```text
1. Jalankan Aplikasi      --> flutter run --profile
2. Buka DevTools          --> Pilih Tab "Performance" atau "Memory"
3. Mulai Perekaman        --> Klik tombol "Record" dan lakukan interaksi normal (scroll, tab, load)
4. Hentikan & Analisis    --> Klik "Stop", cari frame berwarna kuning atau merah
5. Telusuri Akar Masalah  --> Klik frame merah, periksa Flame Chart untuk mengidentifikasi fungsi terlama
6. Refactor & Verifikasi  --> Perbaiki kode, ulangi profiling, dan buktikan frame menjadi hijau (< 16 ms)
```



