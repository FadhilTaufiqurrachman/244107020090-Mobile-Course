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
