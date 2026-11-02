# Minggu 8 — Mid Project Review & Code Review

> Dokumentasi Praktikum Mata Kuliah **Pemrograman Mobile**.

[![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Git Flow](https://img.shields.io/badge/Git-Git%20Flow-F05032?logo=git&logoColor=white)](https://git-scm.com/)
[![Conventional Commits](https://img.shields.io/badge/Commits-Conventional%20Commits-FE5196?logo=conventionalcommits&logoColor=white)](https://www.conventionalcommits.org/)
[![CI Workflow](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![AI Review](https://img.shields.io/badge/AI-Critical%20Verification-orange)](#)
[![Code Review](https://img.shields.io/badge/Review-Approved-brightgreen)](#)

---

## 🧭 Ringkasan

Minggu kedelapan difokuskan pada **Mid Project Review & Code Review**. Pada tahap tengah semester ini, fokus beralih ke kolaborasi profesional, disiplin Git (*Git Flow* dan *branch hygiene*), penulisan Pull Request yang terstruktur, *peer code review*, static analysis (`flutter analyze` & `dart format`), otomasi CI via GitHub Actions, verifikasi kritis review AI (*AI Challenge*), refactoring tindak lanjut review, serta pengujian ketat (*automated testing*) untuk memastikan fondasi aplikasi paruh pertama semester (Minggu 1 hingga 7: `week5_offline_notes` dan `campus_notify` Clean Architecture) siap untuk paruh kedua.

---

## 🎯 Tujuan Pembelajaran

Setelah menyelesaikan praktikum ini, mahasiswa mampu:

1. Menjelaskan **Git Flow** dan strategi branching (`main`, `develop`, `feature/*`, `fix/*`);
2. Menulis commit dan Pull Request yang berkualitas dan mudah direview;
3. Melakukan *peer code review* yang konstruktif dengan checklist terstruktur;
4. Menjalankan *static analysis* dan *formatter* (`flutter analyze`, `dart format`) hingga bersih;
5. Menilai kesiapan project tengah semester dan menindaklanjuti hasil review;
6. Memverifikasi saran review dari AI sebelum diterapkan.

---

## 🛠️ Praktikum 1: Hygiene Branch dan Commit

### 1. Audit Riwayat Repository
Hasil eksekusi audit Git (`git log --oneline -15`, `git branch -a`, `git status`):
* **Branching saat ini:** Branch `develop` telah dibuat dan didorong ke remote GitHub. Branch fitur `feat/mid-review-checklist` aktif digunakan.
* **Format Commit:** Sebagian besar commit sudah menggunakan prefix tipe (`feat:`, `docs:`, `chore:`, `fix:`), dan mulai Week 8 diadopsi format lengkap Conventional Commits `tipe(scope): deskripsi`.
* **Temuan Khusus:** Ditemukan commit lama dengan deskripsi ambigu (`fix: minor git bug`) serta typo penulisan delimiter (`fix; minor git bug`).

### 2. Refaktor Pesan Commit (Simulasi di `docs/review-checklist.md`)

| Hash | Pesan Lama (Sebelum) | Pesan Baru (Sesudah) | Alasan & Justifikasi Perbaikan |
| :--- | :--- | :--- | :--- |
| `c498e55` | `fix: minor git bug` | `fix(notes): resolve git tracking issue for untracked database files` | Memperjelas scope `(notes)`, mendeskripsikan masalah secara spesifik, dan menghapus pesan generik. |
| `67a2120` | `fix; minor git bug` | `fix(git): correct commit delimiter typo and update ignore rules` | Memperbaiki kesalahan tanda baca titik koma (`;`) menjadi titik dua (`:`) sesuai aturan Conventional Commits. |
| `0296b83` | `feat : complete week 7 domain and data feature` | `feat(auth,announcements): define domain entities, use cases, and repository interfaces` | Menghapus spasi berlebih pada prefix, mengubah orientasi dari tugas kuliah menjadi fitur teknis sistem (*product-centric*). |

---

## 👥 Praktikum 2: Pull Request dan Peer Code Review

### 1. Anatomi Template PR
Penerapan template deskripsi Pull Request yang terstruktur mencakup identifikasi masalah, solusi implementasi, petunjuk pengujian, dan penautan issue (`Closes #issue`).

### 2. Simulasi Peer Code Review (15 Menit)
Simulasi review sejawat dilakukan terhadap PR fitur dengan kriteria evaluasi ketat:
* **2 Temuan Kebenaran (Correctness):**
  1. *Whitespace Validation:* Validasi input belum menggunakan `.trim()`, berpotensi menyimpan spasi kosong.
  2. *Double Submit Prevention:* Tombol submit tidak di-disable saat `isLoading`, memicu race condition.
* **1 Temuan Arsitektur (Clean Arch):**
  1. *Presentation Leaking Data Layer:* Halaman UI mengakses database lokal secara langsung tanpa melewati kontrak repository domain.
* **1 Temuan Testing & 1 Saran Keterbacaan:**
  1. *Negative Test Case:* Menambahkan pengujian untuk input kosong dan whitespace.
  2. *Clean Code:* Mengekstrak fungsi validasi 45 baris dari file widget ke utility kelas murni di `core/`.
* **Pola Komentar:** Menggunakan format profesional: **Observasi $\rightarrow$ Dampak $\rightarrow$ Usulan Konkret**.
* **Keputusan Review:** *Request changes* sebelum di-merge ke branch `develop`.

---

## 🔍 Praktikum 3: Static Analysis, CI & Penilaian Tengah Semester

### 1. Tiga Pemeriksaan Mesin (Clean Code Assurance)
* **`flutter analyze`:** Lulus 100% tanpa error/warning (`No issues found!`) di seluruh root project dan sub-project `campus_notify`.
* **`dart format --set-exit-if-changed lib test`:** Berhasil memformat 33 file Dart di `campus_notify` sesuai konvensi resmi Dart.
* **`flutter test`:** 11/11 unit test dan widget test pada `campus_notify` berjalan hijau tanpa kegagalan (kemudian bertambah menjadi 12 test setelah refactoring).

### 2. Penolakan Otomatis via CI (`.github/workflows/ci.yml`)
Workflow GitHub Actions telah dikonfigurasi untuk menjalankan static analysis dan automated test secara otomatis pada setiap Pull Request.

### 3. Bukti Tiga Grep Sterilitas Clean Architecture
Aturan ketergantungan (*The Dependency Rule*) diverifikasi:
1. `features/*/domain` bebas dari import `package:flutter/` $\rightarrow$ **0 Match (Steril)**.
2. `features/*/domain` bebas dari import `package:dio|firebase|sqflite` $\rightarrow$ **0 Match (Steril)**.
3. `features/*/presentation/pages` bebas dari import data layer (`data/`) $\rightarrow$ **0 Match (Steril)**.

---

## 🤖 AI Challenge: Review Kritis vs Keputusan Mahasiswa

Hasil audit mandiri terhadap saran AI didokumentasikan di [**`docs/ai-review-vs-keputusan.md`**](docs/ai-review-vs-keputusan.md):
* **3 Temuan Diterima:** Kebocoran persistensi token di Presentation, throw raw Exception yang merusak sealed Failure, dan celah pengujian domain edge case.
* **2 Temuan Ditolak:** Usulan mengimpor `Dio` ke Domain layer (pelanggaran fatal arsitektur) dan usulan formatting/style minor (sudah ditangani CI otomatis).

---

## 🔄 Refactoring, Testing, dan Error Umum

### 1. Tindak Lanjut Refactoring Nyata
* **Domain Input Sanitization:** Menambahkan validasi `id.trim().isEmpty` pada `GetAnnouncementDetail` use case.
* **Penambahan Negative Test:** Menambahkan test case pengujian input whitespace pada `test/get_announcement_detail_test.dart`.
* **Hasil Uji:** 12/12 unit test berjalan hijau (`All tests passed!`).

### 2. Matriks Error Umum dan Solusinya

| Gejala | Penyebab Umum | Solusi yang Diterapkan |
| :--- | :--- | :--- |
| PR 800 baris tak kunjung direview | Banyak fitur digabung satu PR | Pecah per fitur; satu PR < 300 baris diff |
| Konflik merge berulang | Branch berumur panjang, jarang sinkron | Rebase/pull `develop` harian; umur branch < 3 hari |
| Review hanya debat spasi | Tidak ada formatter/CI | Wajibkan `dart format` + CI `flutter analyze` otomatis |
| Approve tapi bug lolos | Review tanpa pull + test | Reviewer wajib checkout, jalankan test, dan uji manual |
| Saran AI merusak arsitektur | Saran AI diterima mentah tanpa verifikasi | Verifikasi kritis dengan uji sterilitas grep dan tolak jika melanggar Dependency Rule |

---

## 📁 Struktur Dokumen Praktikum

```text
244107020090-Mobile-Course/
├── .github/
│   └── workflows/
│       └── ci.yml                     # CI automation workflow
└── 08-Week-8-Mid-Project-Review/
    ├── README.md                      # Laporan utama praktikum Minggu 8
    ├── docs/
    │   ├── review-checklist.md        # Checklist audit, review PR, dan hasil static analysis
    │   └── ai-review-vs-keputusan.md  # Analisis kritis temuan AI vs keputusan teknis
    └── Screenshots/                   # Bukti tangkapan layar praktikum
```
