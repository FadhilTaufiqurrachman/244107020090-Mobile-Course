# 📋 Review Checklist & Audit Kesiapan Tengah Semester (Mid-Project Review)

Dokumen ini merupakan bagian dari praktikum **Minggu 8 — Mid Project Review & Code Review**.

---

## 1. Hasil Audit Riwayat Commit & Branch

### Temuan Masalah:
1. **Semua commit langsung ke `main`:**
   Branch `main` digunakan secara langsung tanpa melewati branch perantara (`develop`) atau branch fitur (`feature/*`).
2. **Belum adanya branch `develop`:**
   Saat menjalankan `git branch -a`, hanya branch `main` yang terdaftar (sekarang sudah dibuat dan dipush ke remote).
3. **Pesan commit masih berorientasi tugas (*course-centric*):**
   Banyak commit yang menggunakan frasa `complete week X ...` alih-alih menjelaskan fitur perangkat lunak yang diubah.
4. **Adanya commit ambigu dan kesalahan sintaks:**
   Ditemukan commit dengan deskripsi generik seperti `fix: minor git bug` dan kesalahan penulisan delimiter `fix; minor git bug`.

---

## 2. Tabel Refaktor Pesan Commit (Sebelum / Sesudah)

Berikut adalah simulasi penulisan ulang pesan commit lama menjadi format standar **Conventional Commits**:

| Hash | Pesan Lama (Sebelum) | Pesan Baru (Sesudah) | Alasan & Justifikasi Perbaikan |
| :--- | :--- | :--- | :--- |
| `c498e55` | `fix: minor git bug` | `fix(notes): resolve git tracking issue for untracked database files` | **Jelas Apa, Di Mana, dan Buktinya.** Pesan lama sangat ambigu. Pesan baru menambahkan scope `(notes)`, mendeskripsikan masalah tracking Git pada file SQLite lokal, serta menggunakan format standar tanpa frasa generik. |
| `67a2120` | `fix; minor git bug` | `fix(git): correct commit delimiter typo and update ignore rules` | **Memperbaiki format sintaks.** Pesan lama salah menggunakan delimiter titik koma (`;`) bukan (`:`) dan pesannya tidak informatif. Format baru menetapkan scope `(git)` dan menjelaskan perbaikan secara jelas. |
| `0296b83` | `feat : complete week 7 domain and data feature` | `feat(auth,announcements): define domain entities, use cases, and repository interfaces` | **Product-centric vs Course-centric.** Menghilangkan spasi sebelum tanda titik dua (`feat :`), menghapus referensi nomor minggu kuliah (`week 7`), dan merinci artefak Clean Architecture konkret yang ditambahkan pada domain/data layer. |
| `508b69f` | `fix: gradle build for android` | `fix(android): resolve gradle build compatibility and kotlin version mismatch` | Menambahkan scope `(android)` dan menjelaskan akar penyebab perbaikan build gradle Android. |

---

## 3. Checklist Kesiapan PR (Pull Request Checklist)

Sebelum PR diajukan ke `develop`:
- [x] Branch dibuat dari `develop` dengan format `feature/*` atau `fix/*`
- [x] Commit pesan mengikuti aturan Conventional Commits: `tipe(scope): deskripsi`
- [x] Ukuran PR kecil (< 300 baris perubahan)
- [x] `flutter analyze` bersih (0 issues / no warnings)
- [x] `dart format` rapi dan konsisten
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

---

## 6. Verifikasi Tiga Pemeriksaan Mesin (Static Analysis & Tests)

Pemeriksaan otomatis telah dijalankan dan diverifikasi:

1. **`flutter analyze` (Root & Project Level):**
   * Status: ✅ **LULUS (No issues found!)**
   * Catatan: Telah membersihkan 1 unused import (`package:dio/dio.dart` di Week 4) sehingga seluruh workspace bersih 100%.
2. **`dart format --set-exit-if-changed lib test`:**
   * Status: ✅ **LULUS (Formatted 33 files, 0 issues remaining)**
   * Seluruh kode Dart di `lib/` dan `test/` telah terformat sesuai konvensi resmi Dart.
3. **`flutter test` (Campus Notify Clean Architecture):**
   * Status: ✅ **LULUS (11 tests passed, 0 failures)**
   * Seluruh test usecase domain, sealed class failure, formatter, dan mock repository berjalan hijau.

---

## 7. Bukti Tiga Grep Sterilitas Clean Architecture (Minggu 7)

Verifikasi aturan ketergantungan (*Dependency Rule*) pada project `campus_notify`:

| No | Aturan Sterilitas | Perintah Verifikasi | Hasil | Status |
|:--:|:---|:---|:---:|:---:|
| 1 | `domain/` bebas 100% dari import Flutter UI | `Get-ChildItem lib/features/*/domain -Recurse \| Select-String "package:flutter/"` | **0 Match** | ✅ Steril Murni |
| 2 | `domain/` bebas 100% dari import Data/Infra (`dio`, `sqflite`, `firebase`) | `Get-ChildItem lib/features/*/domain -Recurse \| Select-String "package:dio\|package:firebase\|package:sqflite"` | **0 Match** | ✅ Steril Murni |
| 3 | `presentation/pages/` (UI) bebas dari import langsung data layer | `Get-ChildItem lib/features/*/presentation/pages -Recurse \| Select-String "data/"` | **0 Match** | ✅ Steril Murni |

---

## 8. Penilaian Kesiapan Tengah Semester (Mid-Semester Readiness Assessment)

* **Fondasi Arsitektur:** Clean Architecture 3-Layer (Presentation, Domain, Data) dengan struktur *feature-first* telah terbukti kokoh dan lulus uji sterilitas.
* **Kesiapan Otomasi (CI):** File alur kerja GitHub Actions telah diaktifkan di `.github/workflows/ci.yml` untuk memvalidasi `flutter analyze` dan `flutter test` pada setiap Pull Request secara otomatis.
* **Disiplin Kolaborasi:** Strategi Git Flow (`main`, `develop`, `feature/*`) dan format Conventional Commits telah diadopsi untuk seluruh pengembangan selanjutnya.
* **Status Akhir:** ✅ **LULUS REVIEW TENGAH SEMESTER (Siap untuk paruh kedua)**
