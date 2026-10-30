# 📋 Review Checklist & Audit Riwayat Commit

Dokumen ini merupakan bagian dari praktikum **Minggu 8 — Mid Project Review & Code Review**.

---

## 1. Hasil Audit Riwayat Commit & Branch

### Temuan Masalah:
1. **Semua commit langsung ke `main`:**
   Branch `main` digunakan secara langsung tanpa melewati branch perantara (`develop`) atau branch fitur (`feature/*`).
2. **Belum adanya branch `develop`:**
   Saat menjalankan `git branch -a`, hanya branch `main` yang terdaftar.
3. **Pesan commit masih berorientasi tugas (*course-centric*):**
   Banyak commit yang menggunakan frasa `complete week X ...` alih-alih menjelaskan fitur perangkat lunak yang diubah.
4. **Adanya commit ambigu dan kesalahan sintaks:**
   Ditemukan commit dengan deskripsi generik seperti `fix: minor git bug` dan kesalahan penulisan delimiter `fix; minor git bug`.

---

## 2. Tabel Refaktor Pesan Commit (Sebelum / Sesudah)

Berikut adalah simulasi penulisan ulang 3 pesan commit lama menjadi format standar **Conventional Commits**:

| Hash | Pesan Lama (Sebelum) | Pesan Baru (Sesudah) | Alasan & Justifikasi Perbaikan |
| :--- | :--- | :--- | :--- |
| `c498e55` | `fix: minor git bug` | `fix(notes): resolve git tracking issue for untracked database files` | **Jelas Apa, Di Mana, dan Buktinya.** Pesan lama sangat ambigu. Pesan baru menambahkan scope `(notes)`, mendeskripsikan masalah tracking Git pada file SQLite lokal, serta menggunakan format standar tanpa frasa generik. |
| `67a2120` | `fix; minor git bug` | `fix(git): correct commit delimiter typo and update ignore rules` | **Memperbaiki format sintaks.** Pesan lama salah menggunakan delimiter titik koma (`;`) bukan (`:`) dan pesannya tidak informatif. Format baru menetapkan scope `(git)` dan menjelaskan perbaikan secara jelas. |
| `0296b83` | `feat : complete week 7 domain and data feature` | `feat(auth,announcements): define domain entities, use cases, and repository interfaces` | **Product-centric vs Course-centric.** Menghilangkan spasi sebelum tanda titik dua (`feat :`), menghapus referensi nomor minggu kuliah (`week 7`), dan merinci artefak Clean Architecture konkret yang ditambahkan pada domain/data layer. |
| *(Bonus)* `508b69f` | `fix: gradle build for android` | `fix(android): resolve gradle build compatibility and kotlin version mismatch` | Menambahkan scope `(android)` dan menjelaskan akar penyebab perbaikan build gradle Android. |

---

## 3. Checklist Kesiapan PR (Pull Request Checklist)

Sebelum PR diajukan ke `develop`:
- [x] Branch dibuat dari `develop` dengan format `feature/*` atau `fix/*`
- [x] Commit pesan mengikuti aturan Conventional Commits: `tipe(scope): deskripsi`
- [x] Ukuran PR kecil (< 300 baris perubahan)
- [x] `flutter analyze` bersih (0 issues / no warnings)
- [x] `flutter test` hijau (semua unit & widget test lolos)
- [x] Screenshot bukti tampilan / hasil pengujian disertakan di deskripsi PR

---

## 4. Template Pull Request Standar Industri

```markdown
### Judul: feat(notes): validasi judul kosong + test

#### Masalah:
Pengguna dapat menyimpan catatan tanpa judul atau hanya berisi spasi kosong, menyebabkan tampilan daftar catatan menampilkan entri kosong yang membingungkan.

#### Solusi:
1. Menambahkan validasi `title.trim().isNotEmpty` pada level use case / repository.
2. Mengembalikan error pesan ramah pengguna jika judul kosong.
3. Menampilkan indikator error pada `TextFormField` di UI.

#### Cara Uji:
1. Buka halaman catatan -> Tambah catatan baru tanpa judul -> Klik simpan -> Pesan validasi "Judul tidak boleh kosong" muncul.
2. Jalankan unit test validasi:
   `flutter test test/validate_note_test.dart`

Closes #12
```

---

## 5. Lembar Peer Code Review (Simulasi 15 Menit)

**Target PR:** `feat/notes-validation` $\rightarrow$ `develop`  
**Reviewer:** Peer Reviewer  
**Author:** Fadhil Taufiqurrachman

### A. Temuan Kebenaran (Correctness & Edge Cases)
1. **Temuan 1 (Null / Empty String Handling):**
   * **Observasi:** Fungsi simpan hanya memeriksa `if (title.isEmpty)`, belum menggunakan `title.trim().isEmpty`.
   * **Dampak:** Pengguna masih bisa menginput spasi berulang kali (`"   "`) dan catatan kosong tetap tersimpan ke SQLite.
   * **Usulan konkret:** Ubah pemeriksaan menjadi `if (title.trim().isEmpty) return Left(EmptyTitleFailure());`.
2. **Temuan 2 (Async State Race Condition):**
   * **Observasi:** Tombol simpan tidak di-disable saat status `AsyncLoading`.
   * **Dampak:** Pengguna bisa menekan tombol simpan berkali-kali dengan cepat (*double tap*), memicu duplikasi data ke database lokal.
   * **Usulan konkret:** Tambahkan kondisi `onPressed: state.isLoading ? null : () => submit()`.

### B. Temuan Arsitektur (Separation of Concerns & Clean Arch)
1. **Temuan 1 (Leak Data Model ke UI Presentation):**
   * **Observasi:** Halaman UI `note_detail_page.dart` memanggil `sqflite.Database` secara langsung untuk mengecek status sync.
   * **Dampak:** Melanggar *Dependency Rule* Clean Architecture. UI menjadi bergantung langsung pada detail implementasi database lokal.
   * **Usulan konkret:** Bungkus operasi pengecekan status sync melalui `NoteRepository` dan expose nilainya via Riverpod Provider.

### C. Temuan Testing & Keterbacaan (Test & Readability)
1. **Temuan Test:**
   * **Observasi:** File test hanya menguji skenario input valid (*happy path*).
   * **Dampak:** Kasus kegagalan validasi (judul kosong, judul > 100 karakter, whitespace) tidak terverifikasi secara otomatis.
   * **Usulan konkret:** Tambahkan minimal 2 test case: `test('should return validation error when title is empty whitespace')` dan `test('should trim leading and trailing spaces')`.
2. **Saran Keterbacaan (Clean Code):**
   * **Observasi:** Terdapat fungsi pembantu validasi sepanjang 45 baris di dalam widget file.
   * **Usulan konkret:** Ekstrak logika validasi ke `core/validation/note_validator.dart` agar reusable dan mudah diuji secara terisolasi tanpa framework UI.

### D. Keputusan Akhir Reviewer:
> **Status:** ⚠️ **Request Changes**  
> *Catatan:* Perubahan konsep sudah sangat baik. Mohon perbaiki penanganan whitespace trim dan disable tombol saat loading sebelum digabungkan ke `develop`.*
