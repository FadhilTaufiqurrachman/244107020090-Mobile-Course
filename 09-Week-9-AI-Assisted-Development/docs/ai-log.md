# 🤖 Log AI-Assisted Development (AI Log)

Dokumen ini merupakan pencatatan resmi seluruh interaksi prompt AI, evaluasi halusinasi, dan verifikasi keputusan pada **Minggu 9 — AI-Assisted Development / Vibe Coding**.

---

## 1. Identitas Praktikan
* **Nama:** Fadhil Taufiqurrachman
* **NIM:** 244107020090
* **Project Target:** `week5_offline_notes`
* **Fitur yang Dikembangkan:** Pencarian Judul Catatan (*Search Notes*) & Tampilan Kosong (*Empty State*)

---

## 2. Praktikum 1: Prompt & Context Engineering

### Formula 5 Slot Standar Industri
Setiap prompt yang diajukan ke AI coding assistant dirancang menggunakan formula 5 elemen:

1. **Peran (Role):** Senior Flutter Developer & Clean Architecture Specialist.
2. **Konteks (Context):** Mobile app Flutter 3 (Dart 3), state management Riverpod, offline-first SQLite / REST API Dio, struktur *feature-first* (`presentation -> domain <- data`).
3. **Tugas (Task):** Menambahkan fitur pencarian (*search filter*) berdasarkan kata kunci pada daftar data, disertai penanganan status kosong (*empty state*).
4. **Batasan (Constraints):**
   - Wajib mematuhi *The Dependency Rule* (UI dilarang memanggil database/API langsung).
   - Filter harus *case-insensitive* dan menangani *leading/trailing whitespace*.
   - Ukuran kode ringkas (< 80 baris perubahan logis).
   - Tidak mengubah kontrak arsitektur yang sudah berjalan stabil.
5. **Output (Expected Output):** Potongan kode controller/notifier + widget UI + minimal 2 unit test + langkah pengujian manual.

---

## 3. Praktikum 2: Generate dan Verifikasi Search

### A. Prompt Mentah yang Diajukan ke AI
```text
Peran: Senior Flutter Developer
Konteks: Project week5_offline_notes, model Note (id, title, body, updatedAt, dirty), state management Riverpod
Tugas: Tambahkan fitur pencarian judul notes (search notes) berbasis query string lengkap dengan tampilan empty state
Batas: Filter dilakukan secara reaktif via Riverpod provider, case-insensitive, jangan panggil SQLite langsung dari UI
Output: 
1. Provider search query & filtered list
2. Fungsi murni filterNotes
3. Integrasi TextField di NotesPage
4. Minimal 2 unit test (sukses & empty state)
```

### B. Output Awal AI Coding Assistant (Draf Awal)
```dart
// Draf Awal yang Dihasilkan AI:
final searchQueryProvider = StateProvider<String>((ref) => '');

List<Note> filterNotes(List<Note> notes, String query) {
  if (query.isEmpty) return notes;
  // HALUSINASI / BUG: Menggunakan contains() biasa (Case-sensitive)
  return notes.where((n) => n.title.contains(query)).toList();
}

final filteredNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(noteListProvider).value ?? [];
  final query = ref.watch(searchQueryProvider);
  return filterNotes(notes, query);
});
```

### C. Verifikasi 6 Langkah

1. **Baca tiap baris & review:**
   Draf kode AI mudah dipahami, tetapi memiliki kelemahan fatal pada logika pencarian substring.
2. **Cek import sterilitas:**
   `note_provider.dart` hanya mengimpor `package:flutter_riverpod/flutter_riverpod.dart` dan entitas lokal murni. Tidak ada kebocoran import framework ke luar presentation.
3. **Cek API:**
   `StateProvider` di Riverpod modern (v2/v3) sudah mulai digantikan dengan `NotifierProvider`. Fungsi filter dipisahkan menjadi fungsi murni Dart.
4. **Jalankan Static Analysis:**
   `flutter analyze` dieksekusi $\rightarrow$ ✅ **`No issues found!`**
5. **Pengujian Unit Otomatis (Bukti Wajib Temuan Bug):**
   * **Bukti Bug Awal AI:** Ketika draf awal AI diuji dengan query `'belanja'`, catatan `'Belanja Sayur'` tidak ditemukan karena `contains()` pada AI bersifat *case-sensitive*. Selain itu, jika query hanya berisi spasi (`'   '`), AI menganggapnya sebagai kata kunci valid dan mengembalikan daftar kosong secara keliru!
   * **Perbaikan Nyata:**
     ```dart
     List<Note> filterNotes(List<Note> notes, String query) {
       final cleanQuery = query.trim().toLowerCase();
       if (cleanQuery.isEmpty) return notes;
       return notes
           .where((note) => note.title.toLowerCase().contains(cleanQuery))
           .toList();
     }
     ```
   * **Unit Tests Bukti (`test/widget_test.dart`):**
     - `test('filter abaikan huruf besar/kecil')` $\rightarrow$ **PASS ✅**
     - `test('query tak cocok kembalikan kosong')` $\rightarrow$ **PASS ✅**
     - `test('query spasi saja mengembalikan semua catatan tanpa error')` $\rightarrow$ **PASS ✅**
6. **Uji Manual:**
   - *Query Kosong:* Seluruh daftar catatan muncul normal.
   - *Query Cocok:* Mengetik `"belanja"` atau `"BELI"` langsung menyaring catatan secara responsif.
   - *Query Tak Cocok:* Tampilan otomatis beralih ke widget *Empty State* dengan icon `Icons.search_off` dan pesan `"Tidak ada catatan dengan judul '...' "`.

---

## 4. Praktikum 3: Debug dan Refactor ke Clean Architecture

### A. Alur Debugging dengan Test Merah (Red-Green Refactor)

1. **Reproduksi Masalah:**
   Input: Pengguna mencari `"BELANJA"` atau `"   "`.  
   Hasil Tak Diharapkan: Catatan `"Belanja Sayur"` tidak muncul karena perbandingan case-sensitive, atau list menjadi kosong saat spasi diketik.
2. **Isolasi Logika:**
   Logika penyaringan diekstrak keluar dari presentation provider ke use case murni tersendiri:
   📁 [`lib/data/services/search_notes.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/05-Week-5-Local-Storage-Offline-First/Lib/week5_offline_notes/lib/data/services/search_notes.dart)
3. **Test Merah (Failing Test):**
   Dibuat unit test: `test('filter abaikan huruf besar/kecil')` yang gagal pada draf awal AI.
4. **Perbaiki Kecil (Green Test):**
   Implementasi `SearchNotesUseCase` yang membersihkan spasi (`.trim()`) dan menyamakan huruf kecil (`.toLowerCase()`).
5. **Pencatatan Akar Masalah:**
   AI sering berasumsi bahwa string perbandingan bahasa manusia cukup memakai `String.contains()` bawaan Dart tanpa mempertimbangkan perbedaan kapitalisasi keyboard pengguna mobile.

### B. Refactor ke Layer Arsitektur yang Benar

Pemisahan tanggung jawab disusun bertingkat:

```text
widget (NotesPage: UI & TextField controller saja)
  └── notifier (SearchQueryNotifier & filteredNotesProvider: reactive binding saja)
        └── use case (SearchNotesUseCase: aturan bisnis filter & sanitasi query)
              └── repository (NoteRepository: akses SQLite / persistent storage)
```

* **Hasil Audit Ukuran Kode:** Tidak ada method atau widget build yang melebihi 40 baris kode logis.
* **Audit Sterilitas:** Widget sama sekali tidak memanggil SQLite atau SQL query secara langsung.

---

## 5. AI Challenge: Review Kritis vs Keputusan Mahasiswa

### A. Prompt AI Challenge
```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data),
Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

### B. Output Awal AI Reviewer (3 Temuan)

1. **Temuan 1 (Saran - Performance / UI Responsiveness):**
   * *Lokasi:* `NotesPage` text field `onChanged`
   * *Isu:* Mengubah query setiap ketukan keyboard tanpa jeda (*no debouncing*) memicu re-filtering terus-menerus saat pengetikan cepat.
   * *Alasan:* Pada dataset besar, filter in-memory sebaiknya diberi jeda 200–300ms agar UI tidak berulang kali merender ulang widget.
2. **Temuan 2 (Blocker - Arsitektur Clean Architecture):**
   * *Lokasi:* `SearchNotesUseCase`
   * *Isu:* AI menyarankan: "Pindahkan filtering dari memory Dart ke query SQLite langsung (`SELECT * FROM notes WHERE title LIKE '%query%'`) di `NoteRepository` dan gunakan `sqflite` langsung di use case."
   * *Alasan AI:* "Query langsung ke database lebih efisien daripada memuat semua catatan ke memori lalu menyaringnya dengan Dart list."
3. **Temuan 3 (Saran - Test Robustness):**
   * *Lokasi:* `test/widget_test.dart`
   * *Isu:* Pengujian unit belum memverifikasi input yang memuat karakter khusus atau simbol regex (misal tanda kurung siku `[Sayur]`, bintang `*Mobile*`, atau tanda tanya).
   * *Alasan:* Pada beberapa implementasi matcher regex, karakter khusus dapat memicu *FormatSyntaxException* atau crash tak terduga.

---

### C. Matriks Evaluasi & Keputusan Mahasiswa

| No | Temuan AI | Level | Bukti Audit / Test | Keputusan | Alasan & Justifikasi Teknis Mahasiswa |
|:--:|:---|:---:|:---|:---:|:---|
| 1 | Tidak ada debouncing pada `onChanged` search bar | **Saran** | Kode di `notes_page.dart` memanggil `setQuery(value)` secara langsung. | ✅ **TERIMA + REFACTOR** | Saran valid untuk skala dataset besar di masa mendatang, dicatat sebagai rekomendasi optimasi UX. |
| 2 | Pindahkan search ke native SQLite query & impor `sqflite` | **Blocker** | Diperiksa dari prinsip Clean Architecture & Offline-First. | ❌ **TOLAK KERAS** | **Pelanggaran Fatal Dependency Rule!** Data catatan sudah di-cache secara reaktif di memori melalui `noteListProvider`. Membaca ulang disk SQLite setiap ketukan keyboard justru menambah latensi I/O dan merusak isolasi domain. Filter in-memory Dart jauh lebih cepat, deterministik, dan mudah diuji. |
| 3 | Tambahkan pengujian untuk karakter khusus / simbol regex | **Saran** | `widget_test.dart` awalnya baru menguji kata biasa. | ✅ **TERIMA & DIPERBAIKI** | **Meningkatkan Keamanan Test.** Ditambahkan test case `test('query dengan simbol khusus atau regex characters aman')` untuk membuktikan bahwa implementasi substring `String.contains()` aman dari crash parsing regex. |

---

## 6. Refactoring, Testing, dan Error Umum

### A. Eksekusi Pengujian Terdedikasi (`test/search_filter_test.dart`)

Pengujian komprehensif mencakup 4 skenario unit test logika filter dan 1 widget test untuk empty state & interaksi tombol clear:

```bash
cd "05-Week-5-Local-Storage-Offline-First/Lib/week5_offline_notes"
flutter test test/search_filter_test.dart
```

**Log Output Pengujian:**
```text
00:00 +0: SearchNotesUseCase Unit Tests filter abaikan huruf besar/kecil (case-insensitive)
00:00 +1: SearchNotesUseCase Unit Tests query tak cocok kembalikan kosong (empty match)
00:00 +2: SearchNotesUseCase Unit Tests query spasi saja mengembalikan semua catatan tanpa filter salah
00:00 +3: SearchNotesUseCase Unit Tests query dengan simbol regex / karakter khusus tetap aman tanpa crash
00:00 +4: Search & Empty State Widget Tests menampilkan icon dan pesan empty state saat query pencarian tidak cocok
00:00 +5: All tests passed!
```

### B. Matriks Error Umum dan Solusinya

| Gejala Masalah | Penyebab Umum | Solusi yang Diterapkan |
| :--- | :--- | :--- |
| **Method tidak ada** | Halusinasi API oleh AI (mengarang method yang tidak ada di Dart/Flutter) | Selalu periksa via autocompletion IDE dan dokumentasi resmi di `pub.dev` |
| **Import lintas layer** | Kurangnya konteks arsitektur pada prompt AI | Tegaskan batasan arsitektur pada prompt dan lakukan refactor pemisahan layer |
| **Semua test merah** | Prompt yang diajukan terlalu besar dan meminta banyak hal sekaligus | Pecah menjadi 1 fitur kecil + 1 unit test terfokus secara bertahap |
| **Prompt diulang terus tanpa hasil** | Meminta AI memperbaiki kode tanpa data error reproduksi | Tuliskan langkah reproduksi yang jelas disertai test merah pembukti bug |
| **Tak bisa menjelaskan kode hasil AI** | Menerima kode AI secara mentah tanpa membaca ulang baris demi baris | Baca ulang setiap baris, sederhanakan logika, dan lakukan uji manual |

---

### C. Checklist Verifikasi Mandiri

- [x] Prompt 5 slot + konteks arsitektur tercatat di `docs/ai-log.md`.
- [x] `flutter analyze` bersih (0 warning/error di seluruh workspace).
- [x] `flutter test` hijau (13/13 tests lolos di `week5_offline_notes`).
- [x] 1 temuan AI dibuktikan benar (Temuan 3 regex special char) & 1 ditolak beralasan teknis (Temuan 2 SQLite query).
- [x] Mampu menjelaskan setiap baris logika tanpa membuka catatan AI.
