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
