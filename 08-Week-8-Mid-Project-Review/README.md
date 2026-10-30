# Minggu 8 — Mid Project Review & Code Review

> Dokumentasi Praktikum Mata Kuliah **Pemrograman Mobile**.

[![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Git Flow](https://img.shields.io/badge/Git-Git%20Flow-F05032?logo=git&logoColor=white)](https://git-scm.com/)
[![Conventional Commits](https://img.shields.io/badge/Commits-Conventional%20Commits-FE5196?logo=conventionalcommits&logoColor=white)](https://www.conventionalcommits.org/)
[![Code Review](https://img.shields.io/badge/Review-Peer%20Review-green)](#)

---

## 🧭 Ringkasan

Minggu kedelapan difokuskan pada **Mid Project Review & Code Review**. Pada tahap tengah semester ini, fokus beralih ke kolaborasi profesional, disiplin Git (*Git Flow* dan *branch hygiene*), penulisan Pull Request yang terstruktur, *peer code review*, static analysis (`flutter analyze` & `dart format`), serta penilaian kesiapan project Flutter (khususnya project Minggu 3 hingga 7: `week5_offline_notes` dan `campus_notify` Clean Architecture).

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
* **Branching saat ini:** Seluruh riwayat commit (56 commit) berada langsung di branch `main`. Branch `develop` belum ada.
* **Format Commit:** Sebagian besar commit sudah menggunakan prefix tipe (`feat:`, `docs:`, `chore:`, `fix:`), namun belum menyertakan `(scope)` dan masih berorientasi pada nomor minggu tugas kuliah (*course-centric*).
* **Temuan Khusus:** Ditemukan commit dengan deskripsi ambigu (`fix: minor git bug`) serta typo penulisan delimiter (`fix; minor git bug`).

### 2. Refaktor Pesan Commit (Simulasi di `08-Week-8-Mid-Project-Review/docs/review-checklist.md`)

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

## 📁 Struktur Dokumen Praktikum

```text
244107020090-Mobile-Course/
└── 08-Week-8-Mid-Project-Review/
    ├── README.md                 # Laporan utama praktikum Minggu 8
    ├── docs/
    │   └── review-checklist.md   # Checklist audit commit, template PR, & lembar peer review
    └── Screenshots/              # Bukti tangkapan layar praktikum
```
