# 🤖 AI Review vs Keputusan Final Mahasiswa

Dokumen ini merupakan bagian dari **Minggu 8 — AI Challenge & Code Review Kritis**.

---

## 1. Salinan Prompt AI Review

Prompt yang digunakan untuk meminta review dari Senior Flutter Developer:

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

---

## 2. Output Awal AI Reviewer (Simulasi Review Senior Dev)

Berikut adalah 5 temuan teratas yang diberikan oleh AI Coding Assistant:

### Temuan 1 (Blocker - Arsitektur)
* **Lokasi:** `lib/features/auth/presentation/providers/auth_providers.dart:54-59`
* **Isu:** `AuthNotifier` (Presentation Layer) memanggil `tokenStoreProvider.save(...)` secara langsung setelah login berhasil.
* **Alasan:** Menyimpan token ke secure storage adalah tanggung jawab Data Layer (pada `AuthRepositoryImpl` atau didorong dari Use Case). Membiarkan presentation berinteraksi langsung dengan data source membocorkan detail persistensi ke UI layer.
* **Usulan Kode AI:**
  ```dart
  // Pindahkan penyimpanan token ke dalam AuthRepositoryImpl.login()
  // Sehingga Presentation hanya menerima status sukses/gagal murni:
  final result = await loginUseCase.call(email: email, password: password);
  if (result.session != null) {
    state = const AsyncData(true);
  }
  ```

### Temuan 2 (Saran - Kebenaran / Type Safety)
* **Lokasi:** `lib/features/announcements/presentation/providers/announcements_providers.dart:26-28`
* **Isu:** `announcementDetailProvider` melempar `Exception(result.failure!.message)` bertipe string generik saat terjadi kegagalan.
* **Alasan:** Melempar `Exception` generik menghapus klasifikasi tipe `Failure` (misal `NetworkFailure`, `LocalFailure`), sehingga UI tidak bisa membedakan apakah error terjadi karena jaringan terputus atau data pengumuman tidak ditemukan di server.
* **Usulan Kode AI:**
  ```dart
  if (result.failure != null) {
    throw result.failure!; // Lempar tipe Failure murni agar ditangkap error boundary
  }
  ```

### Temuan 3 (Blocker - Arsitektur)
* **Lokasi:** `lib/features/announcements/domain/entities/announcement.dart` & use cases
* **Isu:** AI menyarankan: "Agar efisien dan tidak perlu membuat dua class terpisah antara Model dan Entity, satukan `AnnouncementModel` ke `Announcement` di Domain Layer lengkap dengan `fromJson`/`toJson`, dan tambahkan `CancelToken` dari `package:dio` ke dalam parameter Use Case agar request bisa dibatalkan saat pengguna keluar dari halaman."
* **Usulan Kode AI:**
  ```dart
  import 'package:dio/dio.dart'; // Usulan AI di domain layer

  class GetAnnouncementDetail {
    Future<({Announcement? announcement, Failure? failure})> call(
      String id, {
      CancelToken? cancelToken,
    });
  }
  ```

### Temuan 4 (Saran - Testing)
* **Lokasi:** `test/get_announcement_detail_test.dart`
* **Isu:** Unit test hanya mencakup 2 kasus uji dasar (sukses dan general failure). Belum ada pengujian untuk kasus input ID pengumuman tidak valid atau string kosong.
* **Alasan:** Edge cases penting untuk memastikan use case menolak ID kosong sebelum melakukan pemanggilan ke repository.
* **Usulan Kode AI:**
  ```dart
  test('Mengembalikan LocalFailure saat ID pengumuman kosong', () async {
    final result = await useCase.call('');
    expect(result.failure, isA<LocalFailure>());
    expect(result.announcement, isNull);
  });
  ```

### Temuan 5 (Saran - Style / Formatting)
* **Lokasi:** `lib/features/announcements/presentation/pages/home_page.dart`
* **Isu:** AI menyarankan merapikan trailing comma pada deklarasi `Column` dan mengurutkan import secara alfabetis.
* **Usulan Kode AI:** Mengubah urutan baris import package pihak ketiga di atas import internal file.

---

## 3. Matriks Verifikasi & Keputusan Final Mahasiswa

| No | Temuan AI | Level | Bukti Pemeriksaan (Grep / Test / Audit) | Status Keputusan | Alasan & Justifikasi Teknis Mahasiswa |
|:--:|:---|:---:|:---|:---:|:---|
| 1 | `AuthNotifier` menyimpan token langsung ke data source | **Blocker** | Terbukti di `auth_providers.dart:55`: memanggil `ref.read(tokenStoreProvider).save(...)`. | ✅ **DITERIMA** | **Pelanggaran Arsitektur Nyata.** Tanggung jawab persistensi kredensial adalah wewenang Data Layer (`AuthRepositoryImpl`). Presentation layer tidak boleh mengetahui eksistensi `TokenStore`. |
| 2 | Throw generic `Exception` menghilangkan tipe `Failure` | **Saran** | Terbukti di `announcements_providers.dart:27`: `throw Exception(result.failure!.message);`. | ✅ **DITERIMA** | **Loss of Type Information.** Merusak keunggulan *sealed class* `Failure`. UI presenter membutuhkan tipe failure spesifik untuk menampilkan tombol *Retry* pada `NetworkFailure` atau kembali ke beranda pada `NotFoundFailure`. |
| 3 | Satukan Model ke Domain & gunakan `dio.CancelToken` di Use Case | **Blocker** | Grep sterilitas membuktikan `domain/` saat ini 100% bebas dari Dio dan JSON parsing. | ❌ **DITOLAK KERAS** | **Pelanggaran Fatal The Dependency Rule!** Domain layer wajib steril murni Dart tanpa import framework atau third-party package seperti Dio. Saran AI ini over-engineering dan merusak Clean Architecture. Pembatalan request cukup ditangani di presentation provider via Riverpod `ref.onDispose()`. |
| 4 | Penambahan test case untuk validasi parameter kosong | **Saran** | File `test/get_announcement_detail_test.dart` saat ini hanya menguji 2 skenario sukses & gagal biasa. | ✅ **DITERIMA** | **Meningkatkan Test Robustness.** Menambah cakupan pengujian edge cases memastikan use case tahan terhadap input anomali dari UI atau rute deep link. |
| 5 | Perubahan urutan import alfabetis dan koma gantung | **Saran** | Perintah `dart format --set-exit-if-changed` dan CI sudah memvalidasi formatting. | ❌ **DITOLAK** | **Di Luar Fokus Review.** Modul codelab secara eksplisit menyatakan *"Abaikan style"*. Masalah formatting dan style sudah ditangani otomatis oleh mesin (`dart format` dan GitHub Actions CI). Reviewer tidak boleh membuang waktu untuk nitpicking tampilan kode. |

---

## 4. Kesimpulan Kritis AI Challenge

Dari 5 temuan yang diajukan AI:
* **3 Temuan Diterima (60%):** Temuan terkait kebocoran tanggung jawab layer (presentation vs data), degradasi type-safety pada error handling, dan kelemahan cakupan pengujian domain.
* **2 Temuan Ditolak (40%):**
  1. *Ditolak karena racun arsitektur:* Usulan mengimpor `Dio` ke dalam `Domain Layer` yang melanggar aturan fundamental Clean Architecture.
  2. *Ditolak karena nitpick sepele:* Usulan perubahan style yang seharusnya ditangani secara otomatis oleh formatter dan CI.

> **Refleksi Utama:** AI adalah asisten review yang sangat cepat, namun **tidak boleh dipercaya secara membabi-buta**. Tanpa pemahaman kokoh mengenai *The Dependency Rule*, saran AI yang tampak "ringkas" dapat merusak arsitektur perangkat lunak dalam sekejap.

