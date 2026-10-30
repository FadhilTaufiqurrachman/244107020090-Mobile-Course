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
- [ ] Branch dibuat dari `develop` dengan format `feature/*` atau `fix/*`
- [ ] Commit pesan mengikuti aturan Conventional Commits: `tipe(scope): deskripsi`
- [ ] Ukuran PR kecil (< 300 baris perubahan)
- [ ] `flutter analyze` bersih (0 issues / no warnings)
- [ ] `flutter test` hijau (semua unit & widget test lolos)
- [ ] Screenshot bukti tampilan / hasil pengujian disertakan di deskripsi PR

