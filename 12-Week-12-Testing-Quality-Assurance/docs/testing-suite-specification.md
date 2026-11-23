# Spesifikasi Rangkaian Pengujian (*Test Suite Specification*)
## Codelab #12: Pengujian dan Jaminan Kualitas — Fitur Manajemen Tugas

* **Nama Mahasiswa:** Fadhil Taufiqurrachman
* **NIM:** 244107020090
* **Mata Kuliah:** Pemrograman Mobile
* **Tanggal:** 16 November 2026
* **Proyek:** `campus_notify`

---

## 📋 1. Pencatatan Perilaku (*Behavior Specifications*)

Berdasarkan rancangan fungsionalitas fitur manajemen tugas (*Task Feature*), didefinisikan 3 skenario perilaku utama:

| No | Kategori Skenario | Deskripsi Perilaku yang Diharapkan | Ekspektasi Luaran (*Expected Outcome*) |
| :-: | :--- | :--- | :--- |
| **1** | **Jalur Utama (*Happy Path*)** | Pengguna memasukkan judul tugas yang valid pada form (misal: `'Baca materi'`), lalu menekan tombol simpan tugas. | • Data tugas diteruskan ke repository asinkron.<br>• Item baru muncul di daftar `ListView`.<br>• Kolom teks input dikosongkan secara otomatis.<br>• Pesan error bernilai `null`. |
| **2** | **Kasus Tepi (*Edge Case*)** | Pengguna memasukkan teks yang dipenuhi spasi di awal/akhir (`'   Tugas Mobile   '`) atau karakter whitespace tak kasat mata (tab `\t`, newline `\n`). | • Jika ada teks, spasi dibersihkan via `.trim()` dan data diterima.<br>• Jika hanya whitespace tanpa karakter alfanumerik, input ditolak.<br>• Panjang karakter dibatasi secara ketat (min 3, maks 100). |
| **3** | **Jalur Kegagalan (*Failure Case*)** | Sumber data/jaringan mengalami kegagalan sistem (misalnya backend melempar exception `HTTP 500: Database failure`). | • Service tidak boleh menelan galat menjadi daftar kosong.<br>• Exception diteruskan secara transparan (`throwsA(isA<Exception>())`).<br>• UI menampilkan indikator kesalahan dan pesan validasi yang jelas bagi pengguna. |

---

## 🧪 2. Pengujian Logika Bisnis (*Unit Testing*)

* **Lokasi Berkas Pengujian:** [`test/is_valid_task_title_test.dart`](../Lib/campus_notify/test/is_valid_task_title_test.dart)
* **Pengelompokan (*Group*):**
  1. `group('isValidTaskTitle', ...)`: Memeriksa aturan bahwa judul harus berisi teks setelah spasi di awal dan akhir diabaikan.
  2. `group('isValidTaskTitleStrict', ...)`: Memeriksa analisis nilai batas (*Boundary Value Analysis*) untuk panjang minimum (3 karakter) dan maksimum (100 karakter).
* **Hasil:** 9 pengujian lulus (100%).

---

## ⚡ 3. Pengujian Dependensi Asinkron (*Fake Repository*)

* **Lokasi Berkas Pengujian:** [`test/task_service_test.dart`](../Lib/campus_notify/test/task_service_test.dart)
* **Pola Desain:** Menggunakan `FakeTaskRepository` yang mengimplementasikan `TaskRepository`.
* **Skenario:**
  1. Pengujian data sukses: Meneruskan array `['Baca materi', 'Kerjakan kuis']`.
  2. Pengujian kegagalan terkendali: Menguji pelemparan exception `Exception('Koneksi database/jaringan terputus')`.
  3. Pengujian daftar kosong: Memastikan koleksi kosong dikembalikan saat tidak ada data.
  4. Pengujian filter pencarian data asinkron.
  5. Pengujian latensi: Memvalidasi ketahanan asinkron dengan penundaan waktu terkontrol.
* **Hasil:** 5 pengujian lulus (100%).

---

## 🎨 4. Pengujian Antarmuka Pengguna (*Widget Testing*)

* **Lokasi Berkas Pengujian:** [`test/task_widget_test.dart`](../Lib/campus_notify/test/task_widget_test.dart)
* **Elemen Kunci Pengujian:**
  * `Key('task-title-field')` untuk input teks;
  * `Key('save-task-button')` untuk tombol simpan tugas;
  * `tester.enterText()` dan `tester.tap()`;
  * `tester.pumpAndSettle()` untuk sinkronisasi rendering frame.
* **Cakupan State UI:**
  1. Tampilan awal dan pesan status kosong (`'Belum ada tugas tersimpan'`);
  2. Masukan tidak valid memunculkan pesan kesalahan (`'Judul tugas tidak boleh kosong'`);
  3. Penambahan item berhasil dan muncul di `ListView`.
* **Hasil:** 5 pengujian lulus (100%).

---

## 🔄 5. Pengujian Alur Utama & Integrasi (*Integration Testing*)

* **Lokasi Berkas Pengujian:** [`integration_test/app_test.dart`](../Lib/campus_notify/integration_test/app_test.dart)
* **Binding Khusus:** `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`
* **Alur yang Diuji:** Menjalankan alur lengkap dari inisialisasi antarmuka, input form pengguna, interaksi tombol, pemutakhiran state global, hingga pembuktian data tampil di layar.
* **Pencegahan Regresi:** Melengkapi suite dengan [`test/regression_test.dart`](../Lib/campus_notify/test/regression_test.dart) untuk memastikan bug yang pernah diperbaiki tidak muncul kembali.

---

## 📊 6. Bukti Verifikasi Mesin Hijau (*Quality Gate Verification*)

```bash
# Analisis Bebas Isu / Lint
flutter analyze lib test integration_test
Analyzing 3 items...
No issues found! (ran in 21.4s)

# Eksekusi Rangkaian Test Komprehensif
flutter test
00:14 +56: All tests passed! (56 skenario pengujian lulus 100%)
```
