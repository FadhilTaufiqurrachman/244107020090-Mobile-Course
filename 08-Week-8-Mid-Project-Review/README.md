# Minggu 8 — Mid Project Review & Code Review

> Dokumentasi Praktikum Mata Kuliah **Pemrograman Mobile**.

[![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Git Flow](https://img.shields.io/badge/Git-Git%20Flow-F05032?logo=git&logoColor=white)](https://git-scm.com/)
[![Conventional Commits](https://img.shields.io/badge/Commits-Conventional%20Commits-FE5196?logo=conventionalcommits&logoColor=white)](https://www.conventionalcommits.org/)
[![CI Workflow](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![Code Review](https://img.shields.io/badge/Review-Approved-brightgreen)](#)

## 🧭 Ringkasan

Minggu kedelapan difokuskan pada **Mid Project Review & Code Review**. Pada tahap tengah semester ini, fokus beralih ke kolaborasi profesional, disiplin Git (*Git Flow* dan *branch hygiene*), penulisan Pull Request yang terstruktur, *peer code review*, static analysis (`flutter analyze` & `dart format`), otomasi CI via GitHub Actions, verifikasi kritis review AI (*AI Challenge*), refactoring tindak lanjut review, serta pengujian ketat (*automated testing*).

Seluruh kegiatan evaluasi ini diarahkan untuk mengaudit dan memastikan kesiapan fondasi arsitektur project mobile yang telah dibangun selama paruh pertama semester (Minggu 1 hingga 7), khususnya project **`week5_offline_notes`** dan **`campus_notify`** berbasis **Clean Architecture** feature-first.

## 🎯 Tujuan Pembelajaran

Setelah menyelesaikan praktikum ini, saya diharapkan mampu:

1. Menjelaskan **Git Flow** dan strategi branching (`main`, `develop`, `feature/*`, `fix/*`);
2. Menulis commit dan Pull Request yang berkualitas, deskriptif, dan mudah direview;
3. Melakukan *peer code review* yang konstruktif dengan checklist terstruktur;
4. Menjalankan *static analysis* dan *formatter* (`flutter analyze`, `dart format`) hingga bebas error/warning;
5. Mengonfigurasi integrasi berkelanjutan (*Continuous Integration*) via GitHub Actions;
6. Menilai kesiapan teknis project tengah semester dan menindaklanjuti hasil review secara konkret;
7. Memverifikasi saran review dari AI secara kritis sebelum diterapkan ke basis kode.

## 🧰 Teknologi dan Tools

| Komponen | Penggunaan |
| --- | --- |
| **Dart (3.13.2)** | Bahasa pemrograman aplikasi, static typing, dan automated testing |
| **Flutter** | Framework UI lintas platform berbasis Material 3 |
| **Git & Git Flow** | Version control system dengan strategi branching terstruktur (`main`, `develop`, `feature/*`) |
| **Conventional Commits** | Standarisasi format penulisan pesan commit terstruktur (`tipe(scope): deskripsi`) |
| **GitHub Actions** | Otomasi Continuous Integration (CI) untuk `flutter analyze` dan `flutter test` |
| **Clean Architecture** | Pola arsitektur 3-layer murni (Presentation, Domain, Data) berbasis Feature-First |
| **Flutter Riverpod** | Dependency Injection dan declarative state management |
| **GoRouter** | Declarative navigation, route guards, dan deep link routing |
| **Visual Studio Code** | Editor kode utama, git integration, dan terminal debugging |

## 📂 Struktur Folder

```text
244107020090-Mobile-Course/
├── .github/
│   └── workflows/
│       └── ci.yml                                     # Otomasi CI untuk static analysis & unit test
├── 07-Week-7-Clean-Architecture/                      # Project audit utama (Campus Notify)
│   └── Lib/
│       └── campus_notify/
│           ├── lib/                                   # Source code Clean Architecture 3-layer
│           └── test/                                  # 12 automated unit & widget tests
└── 08-Week-8-Mid-Project-Review/
    ├── README.md                                      # Laporan lengkap evaluasi & refleksi Minggu 8
    ├── docs/
    │   ├── review-checklist.md                        # Checklist audit commit, PR, & peer review
    │   └── ai-review-vs-keputusan.md                  # Verifikasi kritis AI challenge vs keputusan mahasiswa
    └── Screenshots/                                   # Bukti dokumentasi eksekusi terminal & testing
```

## 🚀 Cara Menjalankan

### Persyaratan

- Git terkonfigurasi (`git config user.name` dan `git config user.email`);
- Flutter SDK (>= 3.47.0) dan Dart SDK (>= 3.13.0);
- Visual Studio Code dengan ekstensi Flutter/Dart;
- Akses terminal PowerShell / Bash.

Verifikasi kesiapan environment:

```bash
flutter --version
git --version
git config user.name
git config user.email
```

### Menjalankan Analisis Statis dan Pengujian Unit

Dari direktori project `campus_notify`:

```bash
# 1. Pindah ke direktori project
cd "07-Week-7-Clean-Architecture/Lib/campus_notify"

# 2. Pasang dependencies
flutter pub get

# 3. Jalankan static analysis
flutter analyze

# 4. Verifikasi format kode
dart format --set-exit-if-changed lib test

# 5. Jalankan seluruh automated unit tests
flutter test
```

## 🏛️ Konsep Git Flow dan Kolaborasi

### 1. Branching Model (Satu Branch, Satu Tujuan)

| Branch | Peran | Aturan Utama |
| :--- | :--- | :--- |
| **`main`** | Versi produksi / rilis stabil, selalu terlindungi (*protected*). | ❌ **Tidak ada commit langsung**, hanya digabungkan via release PR. |
| **`develop`** | Tempat integrasi fitur harian/mingguan tim. | Target *default* untuk semua Pull Request fitur maupun bugfix. |
| **`feature/*`** | Pengerjaan satu fitur harian spesifik. | Berumur pendek (< 3 hari), dibuat dari `develop`, lalu di-PR ke `develop`. |
| **`fix/*`** | Perbaikan bug cepat disertai penambahan test. | Sertakan langkah reproduksi bug di issue terkait. |

### 2. Standar Commit Berkualitas (*Conventional Commits*)

Aturan emas: **Satu commit = satu perubahan logis** yang dapat direview dan di-*revert* secara aman.

* **Format Baku:** `tipe(scope): deskripsi singkat` (huruf kecil, tanpa tanda titik di akhir).
* **Pilihan Tipe:**
  * `feat`: Penambahan fitur fungsional baru (contoh: `feat(notes): validasi judul kosong + test`).
  * `fix`: Perbaikan bug atau celah kode (contoh: `fix(auth): refresh token sebelum retry 1x`).
  * `refactor`: Perubahan struktur kode tanpa mengubah fungsi bisnis aplikasi.
  * `test`: Penambahan atau penyesuaian unit/widget test.
  * `docs`: Pembaruan dokumentasi atau file README.
  * `chore`: Penyesuaian konfigurasi toolchain build atau file CI.

### 3. Anatomi Pull Request (PR) yang Sehat

PR kecil direview cepat; PR besar (> 300 baris diff) ditakuti reviewer dan rawan *blind approval*. Syarat PR siap review:
* Memiliki judul satu fitur dengan format Conventional Commits;
* Deskripsi terstruktur: Masalah $\rightarrow$ Solusi teknis $\rightarrow$ Cara uji $\rightarrow$ Bukti screenshot;
* `flutter analyze` bersih (0 issues) dan `flutter test` hijau sebelum meminta reviewer;
* Menautkan issue pelacak (`Closes #issue`).

### 4. Siklus Issue Tracking Terpadu

```text
Issue #12 (Bug Validasi) -> Branch fix/12-notes-validation
  -> Commit atomik terarah -> PR "Closes #12"
  -> Peer Review -> Green CI -> Merge -> Issue otomatis ditutup
```

## 🛠️ Praktikum 1: Hygiene Branch dan Commit

### 1. Audit Riwayat Repository

Perintah audit dieksekusi pada repository:

```bash
git log --oneline -15
git branch -a
git status
```

**Hasil Audit & Temuan:**
1. **Branching Model:** Seluruh 56 commit terdahulu berada langsung di `main`. Branch `develop` belum pernah dibuat.
2. **Pola Pesan Commit:** Mayoritas commit sudah menggunakan prefix tipe, namun belum menyertakan `(scope)` dan masih berorientasi pada nomor minggu tugas kuliah (*course-centric*).
3. **Pesan Ambigu / Typo:** Ditemukan commit dengan deskripsi tidak spesifik seperti `c498e55 fix: minor git bug`, typo tanda baca `67a2120 fix; minor git bug`, dan spasi berlebih `0296b83 feat : complete ...`.

### 2. Refaktor Pesan Commit (Simulasi di `docs/review-checklist.md`)

| Hash | Pesan Lama (Sebelum) | Pesan Baru (Sesudah) | Alasan & Justifikasi Perbaikan |
| :--- | :--- | :--- | :--- |
| `c498e55` | `fix: minor git bug` | `fix(notes): resolve git tracking issue for untracked database files` | **Jelas apa, di mana, dan buktinya.** Menghilangkan pesan ambigu, menambahkan scope `(notes)`, dan merinci masalah tracking SQLite. |
| `67a2120` | `fix; minor git bug` | `fix(git): correct commit delimiter typo and update ignore rules` | **Memperbaiki sintaks Conventional Commits.** Mengganti titik koma (`;`) menjadi titik dua (`:`) serta memperjelas perbaikan file ignore. |
| `0296b83` | `feat : complete week 7 domain and data feature` | `feat(auth,announcements): define domain entities, use cases, and repository interfaces` | **Product-centric vs Course-centric.** Menghapus orientasi tugas kuliah (`week 7`) dan merinci artefak Clean Architecture konkret yang ditambahkan. |
| `508b69f` | `fix: gradle build for android` | `fix(android): resolve gradle build compatibility and kotlin version mismatch` | Menambahkan scope `(android)` dan menjelaskan akar penyebab perbaikan build gradle Android. |

## 👥 Praktikum 2: Pull Request dan Peer Code Review

### 1. Template Pull Request Standar

Template PR diterapkan secara disiplin untuk setiap integrasi fitur ke `develop`:

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

### 2. Lembar Simulasi Peer Code Review (15 Menit)

Simulasi review sejawat dilakukan terhadap PR fitur dengan kriteria evaluasi ketat:

* **2 Temuan Kebenaran (Correctness & Edge Cases):**
  1. *Whitespace Validation:* Fungsi simpan hanya memeriksa `if (title.isEmpty)`. Pengguna masih bisa menginput spasi berulang (`"   "`). Solusi: gunakan `title.trim().isEmpty`.
  2. *Double Submit Prevention:* Tombol simpan tidak di-disable saat status `AsyncLoading`, memicu pengiriman data ganda (*race condition*). Solusi: tambahkan `state.isLoading ? null : () => submit()`.
* **1 Temuan Arsitektur (Clean Architecture):**
  1. *Presentation Leaking Data Layer:* Halaman UI memanggil fungsi database SQLite secara langsung. Solusi: bungkus operasi melalui kontrak `NoteRepository` dan expose nilainya via Riverpod Provider.
* **1 Temuan Testing & 1 Saran Keterbacaan:**
  1. *Negative Test Case:* Menambahkan pengujian untuk input kosong dan whitespace.
  2. *Clean Code:* Mengekstrak fungsi validasi sepanjang 45 baris dari file widget ke utility kelas murni di `core/validation/`.
* **Pola Komentar:** Menggunakan format profesional: **Observasi $\rightarrow$ Dampak $\rightarrow$ Usulan Konkret**.
* **Keputusan Review:** ⚠️ **Request Changes** (perbaikan wajib dilakukan sebelum branch di-merge ke `develop`).

## 🔍 Praktikum 3: Static Analysis, CI & Penilaian Tengah Semester

### 1. Tiga Pemeriksaan Mesin (Clean Code Assurance)

Pemeriksaan otomatis dijalankan untuk menjamin kualitas kode sebelum review:

1. **`flutter analyze` (Root & Project Level):**
   * Berhasil membersihkan 1 warning import mati (`package:dio/dio.dart` di Week 4).
   * Status akhir: ✅ **`No issues found!`** (Bersih 100% di seluruh workspace).
2. **`dart format --set-exit-if-changed lib test`:**
   * Sebanyak 33 file Dart di `campus_notify` berhasil dirapikan sesuai konvensi resmi Dart (`0 changed remaining`).
3. **`flutter test`:**
   * Seluruh unit test dan widget test pada `campus_notify` berjalan hijau tanpa kegagalan (12/12 passed).

### 2. Penolakan Otomatis via CI (`.github/workflows/ci.yml`)

Workflow GitHub Actions diaktifkan untuk menolak PR kotor secara otomatis sebelum dibaca manusia:

```yaml
name: ci
on: [pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true
      - name: Run Flutter Analyze
        run: flutter analyze
      - name: Run Flutter Test (Campus Notify)
        working-directory: 07-Week-7-Clean-Architecture/Lib/campus_notify
        run: |
          flutter pub get
          flutter test
```

### 3. Bukti Tiga Grep Sterilitas Clean Architecture

Verifikasi aturan ketergantungan (*The Dependency Rule*) pada `campus_notify`:

| No | Aturan Sterilitas | Perintah Verifikasi | Hasil | Status |
|:--:|:---|:---|:---:|:---:|
| 1 | `domain/` bebas 100% dari import Flutter UI | `Get-ChildItem lib/features/*/domain -Recurse \| Select-String "package:flutter/"` | **0 Match** | ✅ Steril Murni |
| 2 | `domain/` bebas 100% dari import Data/Infra (`dio`, `sqflite`, `firebase`) | `Get-ChildItem lib/features/*/domain -Recurse \| Select-String "package:dio\|package:firebase\|package:sqflite"` | **0 Match** | ✅ Steril Murni |
| 3 | `presentation/pages/` (UI) bebas dari import langsung data layer | `Get-ChildItem lib/features/*/presentation/pages -Recurse \| Select-String "data/"` | **0 Match** | ✅ Steril Murni |

## 🤖 AI Challenge: Review Kritis vs Keputusan Mahasiswa

### 1. Prompt AI yang Diajukan

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

### 2. Tabel Keputusan Mahasiswa vs Usulan AI

| No | Temuan AI | Level | Bukti Pemeriksaan | Keputusan | Alasan & Justifikasi Teknis |
|:--:|:---|:---:|:---|:---:|:---|
| 1 | `AuthNotifier` menyimpan token langsung ke data source | **Blocker** | Terbukti di `auth_providers.dart:55`: memanggil `ref.read(tokenStoreProvider).save(...)`. | ✅ **DITERIMA** | Menyimpan token adalah wewenang **Data Layer**. Presentation layer tidak boleh mengetahui detail implementasi `TokenStore`. |
| 2 | Throw generic `Exception` menghilangkan tipe `Failure` | **Saran** | Terbukti di `announcements_providers.dart:27`: `throw Exception(result.failure!.message);`. | ✅ **DITERIMA** | Merusak keunggulan *sealed class* `Failure`. UI membutuhkan tipe spesifik untuk menentukan retry policy atau navigasi error. |
| 3 | Satukan Model ke Domain & gunakan `dio.CancelToken` di Use Case | **Blocker** | Grep sterilitas membuktikan `domain/` saat ini 100% bebas dari Dio dan JSON parsing. | ❌ **DITOLAK KERAS** | **Pelanggaran Fatal The Dependency Rule!** Domain layer wajib steril dari Dio dan parser JSON. Pembatalan request cukup ditangani di Riverpod provider via `ref.onDispose()`. |
| 4 | Tambah test case validasi parameter kosong pada use case | **Saran** | File `get_announcement_detail_test.dart` hanya memiliki 2 test case dasar. | ✅ **DITERIMA** | Meningkatkan ketahanan use case terhadap input anomali dari UI atau rute deep link. |
| 5 | Ubah urutan import alfabetis & trailing comma widget | **Saran** | Diperiksa dari output formatter & CI. | ❌ **DITOLAK** | Modul menginstruksikan *"Abaikan style"*. Formatting kode sudah ditangani secara otomatis oleh `dart format` dan workflow CI. |

### 3. AI Verification Checklist

- [x] Interface repository tinggal di `domain` dan implementasi di `data`.
- [x] `domain` bebas 100% dari import Flutter/Dio/SQLite/Firebase (dibuktikan via grep sterilitas).
- [x] Minimal 2 saran AI terbukti benar dengan bukti konkret (Temuan 1, 2, dan 4).
- [x] Minimal 1 saran AI ditolak dengan alasan teknis tertulis (Temuan 3 dan 5).
- [x] Dokumen audit mandiri tersimpan lengkap di `docs/ai-review-vs-keputusan.md`.

## 🧪 Refactoring, Testing, dan Error Umum

### 1. Tindak Lanjut Refactoring Nyata

Sesuai umpan balik peer review dan temuan valid AI, perbaikan nyata diimplementasikan ke dalam kode:

1. **Sanitasi Input Domain Use Case:**  
   Menambahkan validasi pembersihan karakter spasi pada `GetAnnouncementDetail` (`lib/features/announcements/domain/usecases/get_announcement_detail.dart`):
   ```dart
   if (id.trim().isEmpty) {
     return Future.value((
       announcement: null,
       failure: const LocalFailure('ID pengumuman tidak boleh kosong'),
     ));
   }
   ```
2. **Penambahan Negative Unit Test:**  
   Menambahkan skenario uji penolakan ID kosong/spasi pada `test/get_announcement_detail_test.dart`:
   ```dart
   test('Mengembalikan LocalFailure saat ID pengumuman kosong atau hanya spasi', () async {
     final repo = FakeAnnouncementRepository();
     final useCase = GetAnnouncementDetail(repo);
     final result = await useCase.call('   ');

     expect(result.announcement, isNull);
     expect(result.failure, isA<LocalFailure>());
     expect(result.failure!.message, contains('tidak boleh kosong'));
   });
   ```

### 2. Hasil Eksekusi Pengujian Otomatis

```text
Formatted 33 files (0 changed) in 0.08 seconds.

00:00 +0: loading test/core_format_test.dart
00:00 +0: Core Pure Format & Route Parser Tests formatDateIndo memformat DateTime menjadi format teks bahasa Indonesia
00:00 +1: Core Pure Format & Route Parser Tests parseRouteFromMessage menangani route normal, route tanpa slash, dan route kosong
00:00 +2: GetAnnouncementDetail Use Case Tests Mengembalikan detail pengumuman dari repository palsu saat sukses
00:00 +3: GetAnnouncementDetail Use Case Tests Meneruskan Failure dengan aman tanpa melempar exception saat gagal
00:00 +4: GetAnnouncementDetail Use Case Tests Mengembalikan LocalFailure saat ID pengumuman kosong atau hanya spasi
00:00 +5: LoginUseCase Tests Berhasil login dan mengembalikan AuthSession tanpa failure
00:00 +6: LoginUseCase Tests Mengembalikan AuthFailure tanpa melempar exception saat kredensial salah
00:00 +7: routeFromMessage menangani route kosong dan tanpa slash
00:00 +8: data payload membawa id pengumuman
00:00 +9: provider auth membaca status login dari token
00:00 +10: refresh gagal -> sesi dibersihkan (paksa login ulang)
00:00 +11: mapDioExceptionToUserMessage memetakan 401, timeout, dan offline
00:00 +12: All tests passed!
```

Seluruh 12 pengujian unit test **lulus 100%**.

### 3. Error Umum dan Solusinya

| Gejala Masalah | Penyebab Umum | Solusi yang Diterapkan |
| :--- | :--- | :--- |
| **PR 800 baris tak kunjung direview** | Banyak fitur digabung dalam satu PR raksasa. | Pecah per fitur secara logis; batasi ukuran satu PR < 300 baris diff. |
| **Konflik merge berulang** | Branch berumur panjang dan jarang sinkron dengan branch utama. | Lakukan rebase/pull dari `develop` harian; batasi umur branch < 3 hari. |
| **Review hanya debat spasi & formatting** | Tidak adanya formatter otomatis dan pemeriksaan linter pada repositori. | Wajibkan `dart format` dan aktifkan `flutter analyze` pada pipeline CI GitHub Actions. |
| **PR di-approve tapi bug tetap lolos ke rilis** | Reviewer hanya melihat kode di web (*LGTM buta*) tanpa uji lokal. | Reviewer wajib checkout branch secara lokal, menjalankan aplikasi, dan mengecek skenario negatif. |
| **Saran AI merusak arsitektur aplikasi** | Saran kode dari AI diterima mentah tanpa validasi terhadap arsitektur. | Lakukan verifikasi kritis terhadap *The Dependency Rule* menggunakan grep dan tolak jika melanggar. |

## 📊 Status Paruh Semester & Peta Issue / PR

### 1. Status Kesiapan Aplikasi

Aplikasi utama **Campus Notify** berada dalam kondisi stabil dan siap masuk ke paruh kedua semester:
- **Clean Architecture 3-Layer:** Pemisahan Presentation, Domain, dan Data layer terbukti 100% steril via grep test;
- **State Management & DI:** Menggunakan Flutter Riverpod (`AsyncNotifier`, `FutureProvider.family`);
- **Keamanan & Autentikasi:** Enkripsi token via `FlutterSecureStorage`, auto-refresh interceptor via Dio, dan route guard deklaratif via `GoRouter`;
- **Push Notification:** Integrasi Firebase Cloud Messaging (FCM) dan local notifications mencakup 3 siklus hidup (foreground, background, terminated);
- **Kualitas Kode:** Bebas linting warning (`flutter analyze`), terformat rapi (`dart format`), dan 100% test hijau (12/12 unit test lolos).

### 2. Peta Issue dan Pull Request

```text
Issue #12 (Bug: ID Pengumuman Kosong Lolos ke Repository)
  └── Branch: feat/mid-review-checklist
        ├── Commit: docs(review): add git audit findings and commit checklist
        ├── Commit: docs(review): add PR template and peer review guidelines
        ├── Commit: chore(ci): setup github actions workflow and clean static analysis
        ├── Commit: docs(review): complete ai challenge review vs decisions verification
        └── Commit: refactor(announcements): add whitespace validation and edge case test
              └── PR: "feat(review): complete mid project review, branch hygiene, and domain hardening"
                    └── Review: Request changes -> Refactor & Test -> Approved -> Squash & Merge to develop (Closes #12)
```

## 📝 Refleksi

### 1. Apa beda LGTM buta dengan approve yang bertanggung jawab? Apa risikonya bagi tim?

* **LGTM (Looks Good To Me) Buta:** Reviewer hanya melihat kode sekilas atau langsung menekan tombol *Approve* tanpa mengunduh branch, tanpa menjalankan aplikasi secara lokal, dan tanpa memverifikasi edge cases (seperti null safety, error path, atau race condition).
* **Approve yang Bertanggung Jawab:** Reviewer secara aktif memeriksa logika bisnis, memastikan arsitektur tidak bocor (*The Dependency Rule* terjaga), menguji skenario negatif secara manual, dan memverifikasi bahwa tes otomatis berjalan hijau di CI.
* **Risiko bagi Tim:** LGTM buta meloloskan *regression bugs* dan *technical debt* ke branch integrasi (`develop`/`main`). Dampaknya, bug baru ditemukan saat rilis produksi atau saat fitur lain diintegrasikan, yang memicu *hotfix* darurat, *merge conflict* berulang, serta merusak kepercayaan tim terhadap stabilitas basis kode.

### 2. Kapan komentar wajib berstatus *request changes*, dan kapan cukup saran?

* **Wajib *Request Changes*:** Ketika ditemukan isu yang bersifat fatal atau berpotensi merusak integritas sistem, antara lain:
  1. *Pelanggaran Arsitektur:* Import terlarang yang melanggar Clean Architecture (misal domain mengimpor UI/Dio/SQLite).
  2. *Celah Kebenaran / Bug Nyata:* Adanya potensi crash aplikasi, *unhandled null*, kebocoran memori, *race condition*, atau kegagalan fungsionalitas utama.
  3. *Uji Otomatis Gagal:* Test merah atau tidak ada test untuk skenario bisnis baru yang krusial.
* **Cukup Berstatus *Saran* (*Comment / Nitpick*):** Ketika isu yang diangkat tidak menghambat jalannya program dan bersifat alternatif solusi, misalnya:
  1. Saran optimasi non-kritis (misal menyederhanakan ekspresi logika yang masih terbaca).
  2. Rekomendasi penamaan variabel lokal agar lebih ekspresif.
  3. Diskusi perbaikan di masa depan yang tidak perlu memblokir integrasi PR saat ini.

### 3. Bagian mana dari review AI yang Anda tolak atau sederhanakan, dan mengapa?

* **Yang Ditolak Keras:** Usulan AI yang menyarankan untuk menggabungkan model data ke entity domain dan mengimpor pustaka HTTP `Dio` (`CancelToken`) langsung ke dalam domain use case.
* **Alasan Penolakan:** Usulan tersebut adalah **halusinasi berbahaya yang melanggar aturan fundamental Clean Architecture (*The Dependency Rule*)**. Lapisan domain wajib murni tanpa dependensi eksternal. Menerima usulan AI tersebut akan merusak sterilitas domain yang telah susah payah dibangun di Minggu 7.
* **Yang Disederhanakan / Diabaikan:** Usulan AI mengenai pengaturan urutan baris import alfabetis dan penempatan *trailing comma*. Hal ini diabaikan untuk direview manual karena modul codelab menginstruksikan untuk mengabaikan style—seluruh masalah estetika kode sudah diotomatisasi oleh `dart format` dan pipeline CI.

### 4. Satu hal konkret yang Anda perbaiki setelah review sejawat — apa dampaknya?

* **Perbaikan Konkret:** Menambahkan validasi pembersihan karakter spasi (`id.trim().isEmpty`) pada `GetAnnouncementDetail` use case di domain layer, disertai penambahan unit test untuk skenario negatif input whitespace.
* **Dampaknya:**
  1. *Mencegah Request Sia-sia:* Aplikasi tidak akan mengirim query kosong ke repository atau API eksternal jika pengguna atau deep link membawa ID kosong;
  2. *Keamanan Error Boundary:* Error ditangkap secara elegan sebagai `LocalFailure` yang ramah pengguna, bukan sebagai crash *unhandled exception*;
  3. *Regresi Terlindungi:* Unit test otomatis kini bertambah menjadi 12 test, menjamin bahwa validasi input ini tidak akan rusak di masa mendatang jika ada perubahan logika pada modul pengumuman.

### 5. Apa pembelajaran utama dari praktikum ini?

Kolaborasi profesional dalam pengembangan perangkat lunak bukan semata-mata tentang kemampuan menulis baris kode, melainkan tentang **disiplin proses**. Menerapkan Git Flow, menulis Conventional Commits yang deskriptif, menyusun Pull Request yang ringkas, serta memverifikasi kode dengan static analysis dan CI adalah fondasi yang membedakan proyek mahasiswa dengan standar industri. Selain itu, kehadiran AI sebagai coding assistant harus diimbangi dengan literasi arsitektur yang kuat agar pengembang tidak mudah terjebak oleh rekomendasi kode yang tampak cepat namun merusak arsitektur sistem jangka panjang.

## 💡 Kesimpulan

Week 8 memberikan fondasi kolaborasi dan jaminan mutu yang kokoh untuk paruh kedua perkuliahan:
- **Disiplin Git Flow:** Penggunaan branch `develop` dan branch fitur `feature/*` mencegah kontaminasi langsung pada branch `main`;
- **Otomasi Kualitas:** GitHub Actions CI memastikan tidak ada kode kotor yang lolos ke repository;
- **Refactoring Berkelanjutan:** Seluruh temuan peer review dan audit AI telah ditindaklanjuti secara konkret dengan 12/12 unit test hijau;
- **Kesiapan Paruh Semester:** Arsitektur Clean Architecture pada project `campus_notify` terbukti steril dan siap dikembangkan lebih lanjut.

## 🔗 Referensi

- [Slide Week 8: Mid Project Review & Code Review](https://iti-polinema.github.io/flutter-codelab/08-minggu-8-mid-project-review-code-review/)
- [Atlassian: GitFlow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [GitHub: About Pull Request Reviews](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews)
- [Conventional Commits Specification](https://www.conventionalcommits.org/en/v1.0.0/)
- [Flutter: Static Analysis & Linter Rules](https://dart.dev/tools/linter-rules)
- [GitHub Actions Documentation for CI](https://docs.github.com/en/actions)

---

📌 **Repository:** [244107020090-Mobile-Course](https://github.com/FadhilTaufiqurrachman/244107020090-Mobile-Course)

👨‍💻 **Mahasiswa:** Fadhil Taufiqurrachman · **NIM:** 244107020090
