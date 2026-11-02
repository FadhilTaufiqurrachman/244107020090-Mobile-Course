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
