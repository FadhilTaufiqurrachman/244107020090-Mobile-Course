# Laporan Praktikum Pemrograman Mobile - Minggu 07
# Clean Architecture & Separation of Concerns

**Nama:** Fadhil Taufiqurrachman  
**NIM:** 244107020090  
**Kelas:** TI-3H  

---

## Praktikum 1: Audit Layer Project Lama

### 1. Pemetaan File ke Layer (Project: `campus_notify`)

Berikut adalah hasil audit pemetaan file awal sebelum refactoring:

| File | Layer Saat Ini | Masalah / Pelanggaran Arsitektur |
| :--- | :--- | :--- |
| `lib/pages/home_page.dart` | Presentation | Memanggil `unsubscribeCampusTopic()` langsung ke push service eksternal; komponen UI terikat langsung dengan logic notifikasi. |
| `lib/pages/login_page.dart` | Presentation | Menampilkan error mentah melalui `authState.error.toString()` ke UI tanpa konversi ke objek *domain Failure*. |
| `lib/pages/announcement_page.dart` | Presentation | Menampilkan detail berbasis query/path parameter statis tanpa entitas bisnis (*Entity*) domain. |
| `lib/main.dart` | Presentation / Bootstrap | Memanggil instance `apiClientProvider` (Dio) secara langsung di dalam UI (`dio.post('/devices')`) untuk registrasi token FCM. |
| `lib/providers/auth_provider.dart` | Presentation (State & DI) | Melakukan instansiasi konkret langsung (`AuthRepository()`, `TokenStore()`) tanpa interface abstraksi domain; mengelola token store dan network secara tercampur. |
| `lib/data/auth_repository.dart` | Data (+ Kontrak Tercampur) | Tidak memiliki pemisahan kontrak (`interface`) di domain dan implementasi di data; `AuthSession` tercampur di file implementasi. |
| `lib/data/token_store.dart` | Data (Data Source) | Instansiasi langsung `FlutterSecureStorage` tanpa abstraksi repository atau data source contract. |
| `lib/data/api_client.dart` | Data (Network) | Memerlukan implementasi konkret `TokenStore` dan `AuthRepository` secara ketat. |
| `lib/data/api_errors.dart` | Data / Helper | Memetakan `DioException` langsung ke String UI tanpa melalui domain failure abstraction. |
| `lib/messaging/push_service.dart` | Infrastructure / Data | Menangani interaksi langsung dengan plugin Firebase Messaging & Local Notifications. |
| `lib/routes.dart` | Navigation / Core | Konfigurasi routing GoRouter dan helper ekstraksi payload notifikasi. |

---

### 2. Temuan Tiga Pelanggaran Klasik

Berdasarkan audit pencarian pola pelanggaran kode:

1. **Widget yang menyentuh Jaringan / Database langsung:**
   * **Lokasi:** `lib/main.dart` (baris 113–117)
   * **Potongan Kode:**
     ```dart
     final dio = ref.read(apiClientProvider);
     await dio.post(
       '/devices',
       data: {'fcm_token': token, 'platform': 'android'},
     );
     ```
   * **Masalah:** Widget/presentation memanggil HTTP client `Dio` secara langsung untuk menembak endpoint backend. Seharusnya didelegasikan melalui repository/use case.

2. **Logika Bisnis di dalam UI & Penanganan Error Mentah:**
   * **Lokasi:** `lib/pages/login_page.dart` (baris 64)
   * **Potongan Kode:**
     ```dart
     Text(authState.error.toString(), style: const TextStyle(color: Colors.red))
     ```
   * **Masalah:** UI menampilkan exception mentah (`Exception: ...`) tanpa standardisasi domain `Failure`.

3. **Instansiasi Manual (Dependency Injection Bocor):**
   * **Lokasi:** `lib/providers/auth_provider.dart` (baris 7 & 10)
   * **Potongan Kode:**
     ```dart
     final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
     final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
     ```
   * **Masalah:** Provider menginstansiasi kelas implementasi konkret `AuthRepository` langsung, bukan abstraksi/interface kontrak dari domain.

---

### 3. Diagram Struktur Target (Feature-First Clean Architecture)

Struktur target setelah refactoring dirancang berbasis **Feature-First**:

```text
lib/
├── core/
│   ├── failures.dart                         # Failure domain murni Dart
│   └── format.dart                           # Utility formatting murni
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/user_session.dart     # Entitas bisnis murni
│   │   │   ├── repositories/auth_repository.dart  # Interface kontrak murni!
│   │   │   └── usecases/login_usecase.dart    # Operasi bisnis spesifik
│   │   ├── data/
│   │   │   ├── datasources/token_store.dart   # Secure storage driver
│   │   │   ├── models/user_session_model.dart # Mapping JSON / Token ke Entity
│   │   │   └── repositories/auth_repository_impl.dart # Implementasi repository
│   │   └── presentation/
│   │       ├── providers/auth_providers.dart  # State Notifier & DI wiring
│   │       └── pages/login_page.dart          # UI Login steril
│   └── announcements/
│       ├── domain/
│       │   ├── entities/announcement.dart     # Entitas pengumuman
│       │   ├── repositories/announcement_repository.dart # Interface kontrak
│       │   └── usecases/get_announcement_detail.dart    # Use case pengumuman
│       ├── data/
│       │   ├── models/announcement_model.dart # Model mapping
│       │   └── repositories/announcement_repository_impl.dart
│       └── presentation/
│           ├── pages/home_page.dart           # UI Home steril
│           └── pages/announcement_page.dart   # Detail pengumuman
├── messaging/
│   └── push_service.dart                     # Service Firebase & Notifikasi
├── routes.dart                               # GoRouter & rute navigasi
└── main.dart                                 # App bootstrap
```

---

## Praktikum 2: Domain dan Data per Fitur

Pada tahap ini, dibuat pemisahan tegas antara layer **Domain** (logika bisnis murni, tanpa dependensi framework) dan layer **Data** (implementasi sumber data & serialisasi model) yang disesuaikan untuk project `campus_notify`.

### 1. Core Domain: Standardisasi Failure
Dibuat di `lib/core/failures.dart`:
```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
```
*Tujuan:* Mencegah kebocoran exception mentah (mis. `DioException` atau `PlatformException`) langsung ke UI/presentation layer.

---

### 2. Fitur `auth`: Pemisahan Domain & Data

#### a. Entity Murni (`lib/features/auth/domain/entities/auth_session.dart`)
* Bebas dari `package:flutter`, tanpa metode serialisasi (`toJson`/`fromJson`).
```dart
class AuthSession {
  const AuthSession({
    required this.access,
    required this.refresh,
    this.email,
  });

  final String access;
  final String refresh;
  final String? email;
}
```

#### b. Repository Interface Kontrak (`lib/features/auth/domain/repositories/auth_repository.dart`)
* Menggunakan Dart Record `({T? data, Failure? failure})` untuk penanganan hasil eksplisit.
```dart
abstract class AuthRepository {
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<({String? refreshedToken, Failure? failure})> refresh(
    String refreshToken,
  );
}
```

#### c. Use Case: Operasi Bisnis Spesifik (`lib/features/auth/domain/usecases/login_usecase.dart`)
```dart
class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<({AuthSession? session, Failure? failure})> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
```

#### d. Model Serialisasi Data (`lib/features/auth/data/models/auth_session_model.dart`)
* Mewarisi entity `AuthSession` dan menyediakan mapping `toJson`, `fromJson`, dan `toEntity()`.

#### e. Implementasi Repository (`lib/features/auth/data/repositories/auth_repository_impl.dart`)
* Memenuhi kontrak `AuthRepository` dari domain, menangani error secara aman dengan konversi ke domain `Failure`.

---

### 3. Fitur `announcements`: Pemisahan Domain & Data

#### a. Entity Murni (`lib/features/announcements/domain/entities/announcement.dart`)
```dart
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
}
```

#### b. Kontrak Repository (`lib/features/announcements/domain/repositories/announcement_repository.dart`)
```dart
abstract class AnnouncementRepository {
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  );
}
```

#### c. Use Case (`lib/features/announcements/domain/usecases/get_announcement_detail.dart`)
```dart
class GetAnnouncementDetail {
  const GetAnnouncementDetail(this._repository);
  final AnnouncementRepository _repository;

  Future<({Announcement? announcement, Failure? failure})> call(String id) {
    return _repository.getAnnouncementById(id);
  }
}
```

#### d. Model & Implementasi Data
* `lib/features/announcements/data/models/announcement_model.dart`
* `lib/features/announcements/data/repositories/announcement_repository_impl.dart`

---

### 4. Core Pure Utility: `lib/core/format.dart`
* Menyediakan fungsi pure murni `formatDateIndo(DateTime dateTime)` tanpa bergantung pada context atau widget.

---

## Praktikum 3: Presentation, DI, dan Verifikasi

### 1. Dependency Injection Menggunakan Riverpod

Wiring seluruh dependensi dilakukan secara terpusat pada provider masing-masing fitur tanpa memerlukan package DI tambahan (seperti `get_it`).

#### a. Provider Fitur `auth` (`lib/features/auth/presentation/providers/auth_providers.dart`)
```dart
// Data layer provider
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepositoryImpl();
});

// Domain layer provider (menerima interface abstraksi, bukan konkrit)
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

// Presentation layer provider (state management UI)
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);
```

#### b. Provider Fitur `announcements` (`lib/features/announcements/presentation/providers/announcements_providers.dart`)
```dart
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return const AnnouncementRepositoryImpl();
});

final getAnnouncementDetailProvider = Provider<GetAnnouncementDetail>((ref) {
  return GetAnnouncementDetail(ref.watch(announcementRepositoryProvider));
});

final announcementDetailProvider =
    FutureProvider.family<Announcement, String>((ref, id) async {
  final getDetail = ref.watch(getAnnouncementDetailProvider);
  final result = await getDetail.call(id);
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.announcement!;
});
```

---

### 2. Halaman Hanya Membaca State (Steril dari I/O & Formatting Mentah)

* **`LoginPage`** (`lib/features/auth/presentation/pages/login_page.dart`):
  Hanya mengamati `authStateProvider` untuk mengendalikan state UI (loading, form enabled/disabled, serta menampilkan pesan ramah dari `AuthFailure`). Tidak memanggil database atau HTTP request secara langsung.
* **`AnnouncementPage`** (`lib/features/announcements/presentation/pages/announcement_page.dart`):
  Menggunakan `ref.watch(announcementDetailProvider(id))` dengan pola `state.when(...)`:
  - `loading:` menampilkan `CircularProgressIndicator`
  - `error:` menampilkan `ErrorView` dan tombol coba lagi via `ref.invalidate`
  - `data:` merender detail pengumuman dan memformat tanggal menggunakan fungsi pure `formatDateIndo` dari `core/format.dart`.
* **`HomePage`** (`lib/features/announcements/presentation/pages/home_page.dart`):
  Berfungsi sebagai beranda steril yang berinteraksi murni via `authStateProvider.notifier.logout()`, navigasi route terisolasi, dan token mask provider.
* **`main.dart` Bootstrap:**
  Panggilan `Dio` langsung pada saat token FCM didaftarkan telah didelegasikan keluar dari presentation layer ke `registerDeviceToken(token)`.

---

### 3. Verifikasi Dependency Rule

Tiga pemeriksaan sterilitas arsitektur dijalankan untuk membuktikan kepatuhan arsitektur:

#### Pemeriksaan 1: Presentation Steril dari Data Mentah (Target: 0 Hasil)
*Perintah:*
```bash
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation lib/pages lib/main.dart
```
*Hasil:* **0 temuan (Lolos)**. Presentation layer tidak menyentuh database, jaringan, secure storage, atau parser JSON langsung.

#### Pemeriksaan 2: Domain Steril dari Framework & Package Luar (Target: 0 Hasil)
*Perintah:*
```bash
rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core
```
*Hasil:* **0 temuan (Lolos)**. Layer Domain dan Core murni menggunakan Dart standar tanpa ketergantungan framework.

#### Pemeriksaan 3: Static Analysis & Unit Tests
*Perintah:*
```bash
flutter analyze
flutter test
```
*Hasil:*
```text
Analyzing campus_notify...
No issues found! (ran in 2.8s)

00:00 +0: loading test/widget_test.dart
00:00 +0: routeFromMessage menangani route kosong dan tanpa slash
00:00 +1: data payload membawa id pengumuman
00:00 +2: provider auth membaca status login dari token
00:00 +3: refresh gagal -> sesi dibersihkan (paksa login ulang)
00:00 +4: mapDioExceptionToUserMessage memetakan 401, timeout, dan offline
00:00 +5: All tests passed!
```
Semua static analysis bersih dan seluruh unit test lulus dengan sukses.

---

## 6. AI Challenge: Reorganisasi Arsitektur Clean Architecture

### 1. Prompt AI yang Diajukan
```text
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

---

### 2. Output Usulan Solusi Arsitektur AI

#### Struktur Feature-First yang Diusulkan
```text
lib/
├── core/
│   ├── failures.dart                           # Failure murni domain Dart
│   └── format.dart                             # Pure utility murni formatting
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/auth_session.dart      # Entity murni
│   │   │   ├── repositories/auth_repository.dart # Interface abstrak
│   │   │   └── usecases/login_usecase.dart     # Business use case
│   │   ├── data/
│   │   │   ├── datasources/token_store.dart    # Secure storage adapter
│   │   │   ├── models/auth_session_model.dart  # Serializer JSON/Model
│   │   │   └── repositories/auth_repository_impl.dart # Implementasi repository
│   │   └── presentation/
│   │       ├── providers/auth_providers.dart   # Riverpod DI & Notifier
│   │       └── pages/login_page.dart           # UI login steril
│   └── announcements/
│       ├── domain/
│       │   ├── entities/announcement.dart      # Entity murni
│       │   ├── repositories/announcement_repository.dart # Interface
│       │   └── usecases/get_announcement_detail.dart # Business use case
│       ├── data/
│       │   ├── models/announcement_model.dart  # Serializer model
│       │   └── repositories/announcement_repository_impl.dart
│       └── presentation/
│           ├── providers/announcements_providers.dart # Riverpod DI
│           ├── pages/home_page.dart            # Beranda UI steril
│           └── pages/announcement_page.dart    # Detail pengumuman UI steril
├── messaging/
│   └── push_service.dart                       # Service FCM & Local Notification
├── routes.dart                                 # GoRouter configuration
└── main.dart                                   # App initialization
```

---

### 3. Tabel Pemetaan File Lama ke Tujuan Baru

| File Lama | Status Tindakan | Lokasi Baru | Alasan Arsitektural |
| :--- | :--- | :--- | :--- |
| `lib/data/auth_repository.dart` | **Dipecah** | `lib/features/auth/domain/entities/auth_session.dart`, `.../domain/repositories/auth_repository.dart`, `.../data/repositories/auth_repository_impl.dart` | Memisahkan kontrak abstrak (domain) dari implementasi konkret & memindahkan entitas dari data layer ke domain. |
| `lib/data/token_store.dart` | **Pindah** | `lib/features/auth/data/datasources/token_store.dart` | Merupakan data source lokal fitur auth. |
| `lib/data/api_client.dart` | **Refactor** | `lib/data/api_client.dart` | Disesuaikan agar bergantung pada interface `AuthRepository` domain, bukan implementasi konkret. |
| `lib/data/api_errors.dart` | **Digantikan** | `lib/core/failures.dart` | Menggantikan pemetaan error mentah menjadi domain failure terstandarisasi. |
| `lib/providers/auth_provider.dart` | **Dipecah** | `lib/features/auth/presentation/providers/auth_providers.dart` | Menggabungkan provider data, use case domain, dan UI state notifier dalam satu wiring yang rapi. |
| `lib/pages/login_page.dart` | **Pindah** | `lib/features/auth/presentation/pages/login_page.dart` | Terisolasi di dalam presentation layer fitur auth. |
| `lib/pages/home_page.dart` | **Pindah** | `lib/features/announcements/presentation/pages/home_page.dart` | Terisolasi di dalam presentation layer fitur pengumuman/beranda. |
| `lib/pages/announcement_page.dart` | **Pindah & Refactor** | `lib/features/announcements/presentation/pages/announcement_page.dart` | Menghubungkan ke `announcementDetailProvider` dan memisahkan formatting tanggal ke pure utility. |
| `lib/main.dart` | **Refactor** | `lib/main.dart` | Menghapus pemanggilan `dio.post('/devices')` langsung di presentation, mendelegasikannya ke service layer. |
| `lib/messaging/push_service.dart` | **Tetap / Perkaya** | `lib/messaging/push_service.dart` | Mengelola FCM isolate & local notifications di layer infrastruktur. |

---

### 4. Analisis Over-Engineering vs Kapan Use Case Dibutuhkan

#### Potensi Over-Engineering:
* Pada operasi CRUD sederhana 1-baris (misal: `getAnnouncementById(id)` yang hanya meneruskan panggilan langsung ke `repository.getAnnouncementById(id)`):
  * **Biaya:** Menambahkan 1 kelas baru, 1 file baru, dan 1 provider baru hanya untuk memanggil satu baris fungsi. Untuk tim kecil, ini dapat meningkatkan kompleksitas kode tanpa nilai fungsional tambahan.
  * **Alternatif Ringkas:** UI Notifier/Provider langsung memanggil `ref.watch(announcementRepositoryProvider).getAnnouncementById(id)`.

#### Kapan Use Case Benar-Benar Wajib / Dibutuhkan:
1. **Koordinasi Multi-Repository:** Contoh operasi checkout/sync yang harus mengambil data lokal, memverifikasi ke backend, dan menulis ke storage.
2. **Aturan Bisnis Murni (Domain Logic):** Validasi format input, enkripsi data sebelum kirim, filter data sensitif, deduplikasi pengumuman.
3. **Pengujian Mandiri (Pure Unit Testing):** Saat operasi bisnis perlu diuji 100% tanpa mock framework Flutter atau plugin native.

---

### 5. Wiring Dependency Injection dengan Riverpod

Tidak diperlukan service locator global seperti `GetIt`. Semua instansiasi dideklarasikan secara deklaratif melalui Riverpod:

```dart
// 1. Data Layer: Data source & Repository Implementation
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepositoryImpl();
});

// 2. Domain Layer: Use case bergantung pada abstraksi repository
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

// 3. Presentation Layer: State Notifier UI
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);
```

**Keuntungan Dibandingkan GetIt:**
* Siklus hidup terikat pada widget lifecycle & auto-dispose otomatis.
* Tidak ada bahaya runtime error akibat singleton belum terdaftar (`unregistered instance`).
* Mudah di-override saat unit testing atau widget testing menggunakan `ProviderScope(overrides: [...])`.

---

### 6. Tabel Usulan AI vs Keputusan Final Mahasiswa

| Aspek Arsitektur | Usulan Awal AI | Keputusan Final Mahasiswa | Alasan & Justifikasi Teknis |
| :--- | :--- | :--- | :--- |
| **Lokasi Repository Interface** | Di dalam `domain/repositories/` | **Diterima** | Sesuai Dependency Inversion: domain menentukan kontrak, data mengimplementasikannya. |
| **Pemakaian Use Case di Announcements** | Membuat `GetAnnouncementDetail` use case | **Diterima dengan Catatan** | Dipertahankan untuk memenuhi standar codelab, namun dicatat sebagai trade-off over-engineering untuk CRUD sederhana. |
| **Penanganan Error** | Menggunakan Dart Records `({T? data, Failure? failure})` | **Diterima** | Menggunakan fitur bawaan Dart 3 murni tanpa dependensi eksternal seperti `fpdart`. |
| **Penyimpanan Token** | `TokenStore` di `data/datasources/` | **Diterima** | Memisahkan adapter storage dari logika repository auth. |
| **Re-export untuk Kompatibilitas** | Memindahkan file dan membiarkan file lama dihapus | **Modifikasi: Tetap Menyediakan Re-export** | Menjaga backward compatibility sehingga route/test eksisting tidak rusak mendadak saat refactor bertahap. |

---

### 7. AI Verification Checklist
- [x] Interface repository tinggal di `domain` dan implementasi di `data`.
- [x] `domain` bebas 100% dari import Flutter/Dio/SQLite/Firebase (dibuktikan via grep).
- [x] Evaluasi over-engineering use case CRUD 1-baris tercatat secara tertulis.
- [x] Entity bebas mapping (`toJson`/`fromJson` hanya ada di Model).
- [x] Wiring DI terpusat di provider, widget tidak pernah melakukan `new Repository()`.

---

## 7. Refactoring, Testing, dan Error Umum

### 1. Refactoring Challenge: Fitur `announcements` & Core Utilities
* **Penerapan Arsitektur Bersih pada Fitur Kedua:**
  Fitur `announcements` telah mengadopsi 3-layer architecture secara utuh:
  - **Domain:** `Announcement` (entity), `AnnouncementRepository` (interface), dan `GetAnnouncementDetail` (use case).
  - **Data:** `AnnouncementModel` (mapping `toJson`/`fromJson`/`toEntity`) dan `AnnouncementRepositoryImpl`.
  - **Presentation:** `announcements_providers.dart` (DI) dan `announcement_page.dart` (UI steril).
* **Ekstraksi Fungsi Murni ke `lib/core/format.dart`:**
  - `formatDateIndo(DateTime)`: Memformat tanggal ke string lokal Indonesia tanpa widget context.
  - `parseRouteFromMessage(Map<String, dynamic>)`: Mengekstrak rute navigasi dari payload FCM tanpa inisialisasi Firebase.
* **Standardisasi Failure Domain:**
  - Seluruh raw exception dikonversi menjadi `Failure` (`LocalFailure`, `NetworkFailure`, `AuthFailure`) sebelum disajikan ke UI.

---

### 2. Testing: Use Case dengan Repository Palsu (*Fake Repository*)

Pengujian dilakukan pada layer domain secara murni tanpa koneksi database, jaringan Dio, atau Firebase.

#### a. Pengujian `GetAnnouncementDetail` (`test/get_announcement_detail_test.dart`)
```dart
class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.announcement, this.fail = false});

  final Announcement? announcement;
  final bool fail;

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(String id) async {
    if (fail) {
      return (announcement: null, failure: const LocalFailure('Simulasi error: Pengumuman tidak ditemukan'));
    }
    return (announcement: announcement, failure: null);
  }
}
```

#### b. Pengujian `LoginUseCase` (`test/login_usecase_test.dart`)
Menggunakan `FakeAuthRepository` untuk memvalidasi:
1. Skenario sukses: Mengembalikan `AuthSession` dan `failure == null`.
2. Skenario gagal: Mengembalikan `AuthFailure` tanpa melempar runtime exception.

#### c. Pengujian Pure Utilities (`test/core_format_test.dart`)
Menguji fungsi formatting tanggal dan parser rute payload.

#### d. Hasil Eksekusi `flutter test`
```text
00:00 +0: loading test/core_format_test.dart
00:00 +0: Core Pure Format & Route Parser Tests formatDateIndo memformat DateTime menjadi format teks bahasa Indonesia
00:00 +1: Core Pure Format & Route Parser Tests parseRouteFromMessage menangani route normal, route tanpa slash, dan route kosong
00:00 +2: GetAnnouncementDetail Use Case Tests Mengembalikan detail pengumuman dari repository palsu saat sukses
00:00 +3: GetAnnouncementDetail Use Case Tests Meneruskan Failure dengan aman tanpa melempar exception saat gagal
00:00 +4: LoginUseCase Tests Berhasil login dan mengembalikan AuthSession tanpa failure
00:00 +5: LoginUseCase Tests Mengembalikan AuthFailure tanpa melempar exception saat kredensial salah
00:00 +6: routeFromMessage menangani route kosong dan tanpa slash
00:00 +7: data payload membawa id pengumuman
00:00 +8: provider auth membaca status login dari token
00:00 +9: refresh gagal -> sesi dibersihkan (paksa login ulang)
00:00 +10: mapDioExceptionToUserMessage memetakan 401, timeout, dan offline
00:00 +11: All tests passed!
```
**Total 11 Unit Test Lulus 100%!**

---

### 3. Error Umum dan Solusinya

| Gejala Masalah | Penyebab Umum | Solusi yang Diterapkan |
| :--- | :--- | :--- |
| **Import cycle / circular dependency** | Presentation diimpor oleh data/domain, atau fitur saling mengimpor presentation. | Menegakkan Dependency Rule: dependensi satu arah (`presentation -> domain <- data`). Navigasi antar fitur memakai GoRouter string path, bukan import widget langsung. |
| **`The argument type 'Model' can't be assigned to 'Entity'`** | Repository Impl mengembalikan model langsung, padahal kontrak meminta entity. | Menggunakan method `.toEntity()` di repository implementation sebelum data dikembalikan ke domain/presentation. |
| **Provider `ref.watch` di luar widget/provider** | Panggilan DI ditulis di dalam method helper biasa atau constructor kelas. | Menjaga seluruh wiring DI Riverpod di dalam provider top-level (`Provider`, `FutureProvider`, `NotifierProvider`). |
| **Test butuh database / network sungguhan** | Use case diuji menggunakan `RepositoryImpl` konkret asli. | Mengimplementasikan `FakeRepository` yang mengimplementasikan interface kontrak domain murni untuk testing. |
| **Refactor merusak fitur yang sudah jalan** | Tidak ada snapshot commit dan langsung memindahkan file secara drastis. | Membuat snapshot commit awal, mempertahankan re-export sementara untuk file lama, serta menjalankan uji unit regression test. |

---

### 4. Checklist Verifikasi Mandiri Akhir
- [x] **Tiga grep sterilitas nol hasil:** Presentation bebas dari Dio/Database/SecureStorage/JSON parser; Domain bebas dari import Flutter/Dio/SQLite/Firebase.
- [x] **Separation of Concerns:** Kontrak interface di domain, implementasi di data, mapping data hanya di model.
- [x] **Dependency Injection:** Widget tidak menginstansiasi repository; seluruh dependensi disuntikkan melalui Riverpod.
- [x] **Behavior Identik:** Fitur auth login, logout, debug FCM token, dan deep link pengumuman tetap berjalan persis seperti sebelum refactor.
- [x] **Analisis Statis & Test:** `flutter analyze` bersih (0 issues) dan 11 unit test lulus hijau.



