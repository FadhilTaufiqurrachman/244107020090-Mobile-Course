# Minggu 9 — AI-Assisted Development / Vibe Coding

> Dokumentasi Praktikum Mata Kuliah **Pemrograman Mobile**.

[![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![AI-Assisted](https://img.shields.io/badge/AI-Assisted%20Development-8E44AD?logo=openai&logoColor=white)](#)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-009688)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![Riverpod](https://img.shields.io/badge/State%20Management-Riverpod-1976D2)](https://riverpod.dev/)

## 🧭 Ringkasan

Minggu kesembilan membahas penerapan alur kerja **AI-Assisted Development** (atau yang populer dengan istilah *Vibe Coding*) secara bijak, terkendali, dan profesional. Fokus utama adalah memanfaatkan AI coding assistant untuk mempercepat penulisan fitur Flutter baru (fitur pencarian / *search feature*) pada basis kode yang sudah ada (`week5_offline_notes`), sembari menerapkan verifikasi ketat terhadap halusinasi AI, kepatuhan arsitektur, pengujian otomatis, dan *refactoring* ke standar Clean Architecture.

## 🎯 Tujuan Pembelajaran

Setelah menyelesaikan praktikum ini, saya diharapkan mampu:

1. Menjelaskan workflow *AI-assisted development* (`prompt` $\rightarrow$ `generate` $\rightarrow$ `verify` $\rightarrow$ `test` $\rightarrow$ `refactor` $\rightarrow$ `explain`);
2. Menulis prompt dan konteks yang efektif untuk fitur Flutter modular dengan **Formula 5 Slot**;
3. Mengenali halusinasi, asumsi keliru, dan keterbatasan AI pada kode Flutter modern;
4. Melakukan *debugging* dan *refactoring* kode hasil AI agar patuh pada Clean Architecture;
5. Menguji kode hasil AI dengan `flutter analyze` dan automated `flutter test`;
6. Mendokumentasikan prompt, hasil AI, keputusan terima/tolak, dan bukti uji secara transparan di `docs/ai-log.md`.

## 🧰 Teknologi dan Tools

| Komponen | Penggunaan |
| --- | --- |
| **Dart (3.13.2)** | Bahasa pemrograman aplikasi, static typing, dan automated test runner |
| **Flutter** | Framework UI lintas platform berbasis Material 3 |
| **AI Coding Assistant** | Asisten cerdas untuk generasi rancangan kode dan ide perbaikan |
| **Clean Architecture** | Pola arsitektur 3-layer (Presentation, Domain, Data) berbasis Feature-First |
| **Flutter Riverpod** | Dependency Injection dan declarative reactive state management |
| **Git & Git Flow** | Version control untuk isolasi branch fitur AI (`feat/week-9-ai-assisted-dev`) |
| **Visual Studio Code** | IDE utama dengan ekstensi Flutter, Dart, dan AI integration |

## 📂 Struktur Folder

```text
244107020090-Mobile-Course/
├── 05-Week-5-Local-Storage-Offline-First/             # Target project peningkatan fitur pencarian
│   └── Lib/
│       └── week5_offline_notes/
│           ├── lib/
│           │   ├── data/
│           │   │   ├── services/search_notes.dart     # Ekstraksi Use Case murni hasil refactoring
│           │   │   └── providers/note_provider.dart   # Riverpod reactive state binding
│           │   └── pages/notes_page.dart              # UI search bar & dynamic empty state
│           └── test/widget_test.dart                  # Automated unit test search & validation
└── 09-Week-9-AI-Assisted-Development/
    ├── README.md                                      # Laporan lengkap praktikum Minggu 9
    ├── docs/
    │   └── ai-log.md                                  # Log prompt, hasil generasi AI, & verifikasi keputusan
    └── Screenshots/                                   # Bukti tangkapan layar eksekusi & pengujian
```

## 🚀 Cara Menjalankan

### Persyaratan

- Git terkonfigurasi pada branch pengembangan;
- Flutter SDK (>= 3.47.0) dan Dart SDK (>= 3.13.0);
- Project dasar `week5_offline_notes`;
- Terminal PowerShell / Bash.

Verifikasi kesiapan awal:

```bash
flutter --version
flutter analyze
```

### Menjalankan Pengujian Unit Fitur Search

Dari direktori project `week5_offline_notes`:

```bash
cd "05-Week-5-Local-Storage-Offline-First/Lib/week5_offline_notes"
flutter test
```

## 🏛️ Konsep Workflow AI dan Halusinasi

### 1. Siklus 6 Tahap (*Generate to Explain*)

AI mengusulkan rancangan kode, namun keputusan teknis dan tanggung jawab arsitektural sepenuhnya berada di tangan pengembang:

```text
1. Prompt   -> Instruksi terarah + konteks arsitektur proyek
2. Generate -> AI mengusulkan potongan kode
3. Verify   -> Developer membaca baris per baris, grep sterilitas, cek API nyata
4. Test     -> flutter analyze bersih + automated unit/widget test hijau
5. Refactor -> Penataan ulang ke Clean Architecture (The Dependency Rule)
6. Explain  -> Mampu mempertanggungjawabkan setiap baris kode secara mandiri
```

> ⚠️ *Kegagalan pada tahap 3–6 adalah esensi dari "vibe coding": terasa cepat dan memuaskan di awal, namun berbiaya sangat mahal di akhir akibat akumulasi bug tersembunyi dan technical debt.*

### 2. Matriks Kapabilitas AI

| Area | Contoh Kasus | Sikap Pengembang Profesional |
| :--- | :--- | :--- |
| **Kuat** | Boilerplate code, pola standar, draf pengujian unit, penyusunan dokumentasi | **Manfaatkan secara maksimal**, namun tetap verifikasi |
| **Lemah** | API package versi terbaru, breaking changes library, logika bisnis spesifik | **Verifikasi ekstra** ke dokumentasi resmi dan changelog |
| **Berbahaya** | Manajemen token autentikasi, query database mentah, aturan otorisasi/keamanan | **Jangan tempelkan secret**; tulis manual dan audit ketat |

### 3. Tiga Pola Halusinasi Khas Flutter

1. **Method / Properti Fiktif:** AI menciptakan nama method yang terdengar meyakinkan namun sebenarnya tidak tersedia di SDK (contoh: `controller.searchFuzzy()`).
2. **Package Kedaluwarsa (*Deprecated API*):** AI menggunakan sintaks versi lama padahal proyek menggunakan versi modern.
3. **Logika Semu (*Subtle Logic Bug*):** Implementasi filter pencarian yang bersifat *case-sensitive* atau tidak membersihkan *whitespace*.

---

## 🛠️ Praktikum 1: Prompt dan Context Engineering

### 1. Formula 5 Slot

Penyusunan prompt berkualitas tinggi wajib mengisi 5 slot esensial secara ringkas:

```text
Peran:   Senior Flutter Developer & Clean Architecture Specialist
Konteks: Mobile app Flutter (Dart 3), Riverpod state management, Clean Architecture
Tugas:   Tambah search filter pada daftar data + handling empty state
Batas:   Patuhi The Dependency Rule, jangan panggil database dari UI, maks 80 baris
Output:  Kode provider + widget UI + 2 unit test + instruksi pengujian
```

### 2. Perbandingan Kualitas Prompt

* **Prompt Buruk (*Vibe Coding*):**  
  `"buatkan search notes yang keren"`  
  *Dampak:* Menghasilkan kode monolitik, logika tercampur di dalam widget, melanggar pemisahan layer, dan tidak dapat diuji secara terisolasi.
* **Prompt Baik (*Context-Engineered*):**  
  `"Tambah fitur pencarian judul catatan. Arsitektur: presentation -> domain <- data. Jangan panggil SQLite dari widget. Filter case-insensitive via Riverpod provider. Sertakan tampilan empty state dan 2 unit test."`  
  *Dampak:* Menghasilkan komponen terpisah yang rapi, modular, aman dari halusinasi arsitektur, dan langsung teruji.

### 3. Privasi dan Masking Konteks

Sebelum melampirkan basis kode ke prompt AI:
* Seluruh kredensial sensitif disensor menggunakan placeholder (`TOKEN_PLACEHOLDER`);
* Hanya sertakan file yang relevan (kontrak repository, model entitas, atau cuplikan `pubspec.yaml`), bukan keseluruhan project.

---

## 🔍 Praktikum 2: Generate dan Verifikasi Search

### 1. Generasi Fitur Pencarian Judul Catatan

Fitur pencarian diimplementasikan pada `week5_offline_notes` dengan draf awal yang dihasilkan melalui AI prompt:
* Penambahan `searchQueryProvider` berbasis Riverpod `NotifierProvider`.
* Penambahan fungsi murni `filterNotes(List<Note> notes, String query)`.
* Penambahan `filteredNotesProvider` untuk reaktivitas UI secara instan.
* Integrasi `TextField` pencarian dan tampilan *Empty State* pada `NotesPage`.

### 2. Verifikasi 6 Langkah

1. **Baca baris demi baris:** Memahami struktur query state dan penyaringan list.
2. **Cek import sterilitas:** Tidak ada kebocoran import database SQLite ke dalam UI.
3. **Cek API:** Menggunakan `NotifierProvider` Riverpod terkini, bukan `StateProvider` usang.
4. **Static Analysis:** `flutter analyze` berjalan bersih tanpa warning (`No issues found!`).
5. **Testing Otomatis (Bukti Halusinasi & Bug Logika AI):**
   * *Temuan Bug AI:* Draf kode awal AI menggunakan `contains(query)` langsung yang bersifat *case-sensitive*, sehingga pencarian `"belanja"` gagal menemukan `"Belanja Sayur"`. Selain itu, input whitespace `"   "` meloloskan string kosong ke pencarian.
   * *Solusi Terverifikasi:* Menggunakan `.trim().toLowerCase()` pada query dan `.toLowerCase()` pada field judul note.
6. **Uji Manual:** Menghasilkan 3 status responsif: *Daftar Utuh (Query Kosong)* $\rightarrow$ *Daftar Tersaring (Query Cocok)* $\rightarrow$ *Empty State (Query Tak Cocok)*.

---

## ⚙️ Praktikum 3: Debug dan Refactor ke Clean Architecture

### 1. Debugging dengan Test Merah (Red-Green Refactor)

Alur penanganan bug logika AI dilakukan secara terukur:
1. **Reproduksi:** Memasukkan query huruf besar (`"BELANJA"`) atau spasi (`"   "`).
2. **Isolasi Logika:** Mengekstrak aturan filter dari presentation layer ke kelas Use Case terdedikasi: [`lib/data/services/search_notes.dart`](../05-Week-5-Local-Storage-Offline-First/Lib/week5_offline_notes/lib/data/services/search_notes.dart).
3. **Test Merah:** Menuliskan `test('filter abaikan huruf besar/kecil')` yang gagal pada draf awal AI.
4. **Perbaiki Kecil:** Memperbarui `SearchNotesUseCase` dengan sanitasi `.trim().toLowerCase()`.
5. **Pencatatan Log:** Menyimpan akar masalah di `docs/ai-log.md`.

### 2. Refactor ke Layer Arsitektur yang Benar

Struktur tanggung jawab dipisahkan secara hierarkis:

```text
widget (NotesPage: UI & TextField controller saja)
  └── notifier (SearchQueryNotifier & filteredNotesProvider: reactive binding saja)
        └── use case (SearchNotesUseCase: aturan bisnis filter & sanitasi query)
              └── repository (NoteRepository: akses SQLite / persistent storage)
```

* **Ukuran Fungsi:** Seluruh fungsi berada di bawah 40 baris kode logis.
* **Sterilitas UI:** Tidak ada pemanggilan SQLite langsung dari layer widget.

### 3. Hasil Tiga Verifikasi Mesin

* **`flutter analyze`:** ✅ **`No issues found!`** (0 warning, 0 error) di seluruh workspace.
* **`dart format --set-exit-if-changed lib test`:** ✅ Seluruh 15 file Dart terformat rapi sesuai panduan resmi Dart.
* **`flutter test`:** ✅ **7/7 unit tests passed!**
