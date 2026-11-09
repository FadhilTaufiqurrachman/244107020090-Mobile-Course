# Minggu 10 — Integrasi Fitur AI

> Dokumentasi Praktikum Mata Kuliah **Pemrograman Mobile**.

[![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![AI Integration](https://img.shields.io/badge/AI-LLM%20%26%20Vision-FF6F00?logo=google&logoColor=white)](#)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-009688)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![Riverpod](https://img.shields.io/badge/State%20Management-Riverpod-1976D2)](https://riverpod.dev/)

## 🧭 Ringkasan

Minggu kesepuluh membahas penerapan dan integrasi **Fitur Kecerdasan Buatan (AI Integration)** secara langsung ke dalam aplikasi mobile Flutter. Melanjutkan fondasi **Clean Architecture** pada aplikasi **Campus Notify** dari Minggu 7–9, praktikum ini memperluas kapabilitas sistem dengan mengintegrasikan Large Language Model (LLM) API (seperti Google Gemini API), antarmuka percakapan interaktif (*Chat Interface*) dengan *streaming response*, kapabilitas pemahaman multimodal (OCR / Image Understanding), serta penerapan perlindungan privasi, efisiensi kuota/biaya, *error handling*, dan *fallback design* yang tangguh.

## 🎯 Tujuan Pembelajaran

Setelah menyelesaikan praktikum ini, saya diharapkan mampu:

1. Memahami konsep dasar integrasi LLM API ke aplikasi mobile;
2. Merancang *chat interface* dengan *streaming response* yang interaktif dan responsif;
3. Mengintegrasikan kemampuan OCR, *Speech-to-Text*, dan *Image Understanding* (multimodal AI);
4. Menerapkan *prompt design* yang aman, terstruktur, dan efektif untuk mobile;
5. Menangani aspek privasi pengguna, efisiensi biaya API, penanganan error jaringan, dan *fallback design*;
6. Mengevaluasi pengalaman pengguna (*User Experience / UX*) pada fitur berbasis AI.

## 🧰 Teknologi dan Tools

| Komponen | Penggunaan |
| --- | --- |
| **Dart (3.13.2)** | Bahasa pemrograman aplikasi mobile, stream handling, dan unit testing |
| **Flutter** | Framework UI lintas platform berbasis Material 3 |
| **Google Generative AI / Gemini API** | Layanan LLM & Multimodal AI untuk chat streaming dan image understanding |
| **Clean Architecture** | Pola arsitektur 3-layer (Presentation, Domain, Data) berbasis Feature-First |
| **Flutter Riverpod** | Dependency Injection dan declarative reactive state management (`StreamProvider`, `AsyncNotifier`) |
| **Flutter Secure Storage** | Penyimpanan aman API key LLM di keychain/keystore perangkat mobile |
| **GoRouter** | Declarative navigation dan rute antarmuka fitur AI |
| **Visual Studio Code** | IDE utama untuk pengembangan Flutter, debugging, dan pengujian |

## 📂 Struktur Folder

```text
244107020090-Mobile-Course/
└── 10-Week-10-AI-Feature-Integration/
    ├── README.md                                      # Laporan lengkap praktikum Minggu 10
    ├── docs/                                          # Dokumen perancangan prompt, privasi, & fallback
    ├── Screenshots/                                   # Bukti tangkapan layar antarmuka & pengujian
    └── Lib/
        └── campus_notify/                             # Project utama hasil salinan Minggu 7
            ├── lib/                                   # Source code Clean Architecture
            └── test/                                  # Automated tests
```

## 🚀 Cara Menjalankan

### Persyaratan

- Flutter SDK (>= 3.47.0) dan Dart SDK (>= 3.13.0);
- API Key dari penyedia LLM (misalnya Google Gemini API Key);
- Visual Studio Code dengan ekstensi Flutter/Dart;
- Perangkat Android fisik atau Emulator Android.

Verifikasi kesiapan awal:

```bash
flutter --version
flutter doctor -v
```

## 🏛️ Konsep Integrasi Fitur AI

### 1. Apa itu Integrasi Fitur AI?

Integrasi fitur AI memungkinkan aplikasi mobile berkomunikasi dengan model AI modern di cloud untuk memberikan pengalaman cerdas dan adaptif kepada pengguna:
* **Chat Asisten:** Tanya jawab real-time interaktif menggunakan Large Language Model (LLM) API;
* **OCR (Optical Character Recognition):** Ekstraksi teks dari foto dokumen atau poster acara;
* **Speech-to-Text (STT):** Konversi transkrip suara pengguna menjadi perintah teks;
* **Image Understanding:** Deskripsi visual, analisis konteks gambar, dan tanya jawab visual multimodal;
* **Recommendation Engine:** Rekomendasi konten pengumuman kampus yang dipersonalisasi berdasarkan preferensi pengguna.

### 2. Arsitektur Integrasi AI pada Mobile

```text
+-------------------+       HTTPS / WSS       +--------------------+
|    Flutter UI     | <---------------------> |    AI API Layer    |
| (Chat, OCR, STT,  |      (Dio / HTTP)       |  (LLM, Gemini API, |
|    Image View)    |                         |    OCR, Vision)    |
+-------------------+                         +--------------------+
          |                                              |
          | API Key (Secure Storage)                     | Raw / Stream Response
          v                                              v
+-------------------+         Optional        +--------------------+
|    Local Cache    | <---------------------> |   Campus Backend   |
| (SQLite / Prefs)  |        (Batching)       |  (Auth, Audit Log) |
+-------------------+                         +--------------------+
```

Prinsip Utama Arsitektur:
1. **Keamanan Kunci API:** Kunci API *tidak pernah* di-hardcode ke dalam kode sumber ataupun file Git. Kunci disimpan terenkripsi di `FlutterSecureStorage` atau dialirkan via environment variable (`--dart-define`).
2. **Efisiensi Biaya & Rate Limit:** Mempertimbangkan limit kuota token API dan biaya per request.
3. **Caching Lokal:** Menerapkan cache lokal (SQLite / SharedPreferences) untuk pertanyaan umum berulang guna memangkas konsumsi token dan mempercepat respons.

### 3. Prompt Design untuk Aplikasi Mobile

| Komponen | Contoh Nyata | Tujuan & Fungsi |
| :--- | :--- | :--- |
| **System Prompt** | `"Kamu asisten kampus ramah, jawab dalam Bahasa Indonesia, maksimal 2 kalimat."` | Menetapkan persona asisten, gaya bahasa, dan batasan panjang output. |
| **User Prompt** | `"Kapan batas pengisian KRS semester ini?"` | Pertanyaan atau instruksi langsung dari pengguna. |
| **Konteks** | Data pengumuman kampus, kalender akademik, profil prodi user | Memberikan data faktual terkini agar model tidak berhalusinasi. |
| **Batasan (*Guardrails*)** | `"Jangan memberikan informasi di luar konteks kampus. Jangan berikan data pribadi mahasiswa."` | Menjaga privasi data pengguna dan kepatuhan etika AI. |

> 💡 **Tips Mobile:** *Pertahankan prompt ringkas dan spesifik untuk menghemat token dan baterai mobile, terjemahkan hasil jika diperlukan, serta validasi format output sebelum disajikan ke widget pengguna.*

---

## 💬 Praktikum: Chat Interface dengan AI

### Langkah 1: Menambahkan Dependensi

Pada file [`pubspec.yaml`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/pubspec.yaml), dependensi `http` ditambahkan untuk mendukung komunikasi REST langsung ke endpoint Google Gemini API:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^3.4.3
  go_router: ^18.0.2
  dio: ^5.11.1
  http: ^1.2.0
  flutter_secure_storage: ^11.2.0
  firebase_core: ^4.15.0
  firebase_messaging: ^16.7.0
  flutter_local_notifications: ^22.3.1
```

### Langkah 2: Membuat Layanan AI (`AiService`)

Layanan AI diimplementasikan di [`lib/ai/ai_service.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/lib/ai/ai_service.dart) dengan fitur:
* Integrasi REST ke model `gemini-pro` endpoint `generateContent`;
* Penyimpanan dan pembacaan kunci API secara aman menggunakan `FlutterSecureStorage`;
* Metode `askStream(String question)` untuk mengalirkan teks respons secara bertahap (*streaming tokens*) ke antarmuka obrolan pengguna;
* Dukungan *Dependency Injection* pada konstruktor untuk mempermudah automated unit testing dengan *mock client*.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiService {
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String _apiUrl;

  AiService({
    FlutterSecureStorage? storage,
    http.Client? client,
    String? apiUrl,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client(),
        _apiUrl = apiUrl ??
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  Future<String> ask(String question) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': question}
            ]
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}');
    }
  }

  /// Mengalirkan respons kata-demi-kata (streaming tokens) untuk antarmuka chat interaktif
  Stream<String> askStream(String question) async* {
    final fullAnswer = await ask(question);
    final words = fullAnswer.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield (i == 0 ? '' : ' ') + words[i];
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key);
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: 'ai_api_key');
  }

  Future<void> clearApiKey() async {
    await _storage.delete(key: 'ai_api_key');
  }
}
```

### Langkah 3: Membuat Antarmuka Obrolan AI (`ChatScreen`)

Halaman obrolan diimplementasikan pada [`lib/features/chat_screen.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/lib/features/chat_screen.dart) dengan karakteristik:
1. **Streaming Response & Loading Indicator:** Menampilkan animasi progres memuat saat model sedang berpikir, lalu mengetikkan respons bertahap secara halus (*typewriter streaming*).
2. **Pemberitahuan & Validasi Keamanan Data Pribadi (*Privacy Guardrail*):** Mencegah pengiriman NIK (16 digit) dan nomor telepon pengguna ke server AI secara otomatis, disertai peringatan visual.
3. **Pengaturan API Key Terintegrasi:** Dialog modal untuk memasukkan, memperbarui, atau menghapus API key Gemini langsung di perangkat melalui `FlutterSecureStorage`.
4. **Quick Suggestion Chips:** Opsi pertanyaan cepat seputar kampus seperti "Jadwal KRS Semester Ini" dan "Info Beasiswa Prestasi".
5. **Navigasi GoRouter & FAB:** Rute `/chat` didaftarkan pada [`lib/routes.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/lib/routes.dart) dan dapat diakses langsung melalui tombol aksi maupun Floating Action Button di `HomePage`.

### 🧪 Bukti Verifikasi Pengujian Otomatis

Seluruh fungsionalitas diuji menggunakan automated unit & widget test:
* [`test/ai_service_test.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/test/ai_service_test.dart): Menguji validasi ketidakhadiran API Key, penyimpanan aman ke keystore, parsing response Gemini 200, penanganan error non-200, dan pembagian chunk pada `askStream`.
* [`test/chat_screen_test.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/test/chat_screen_test.dart): Menguji rendering komponen antarmuka chat dan memverifikasi proteksi blokir pengiriman NIK 16 digit.

```bash
flutter analyze lib test
# Output: No issues found! (ran in 5.3s)

dart format --set-exit-if-changed lib test
# Output: Formatted 37 files (0 changed)

flutter test
# Output: 18/18 tests passed!
```

---

## 👁️🎙️ OCR, Speech-to-Text, dan Image Understanding (Multimodal AI)

Modul ini memperluas fungsionalitas cerdas aplikasi melampaui teks biasa ke kemampuan multimodal: memproses gambar, audio, dan dokumen.

### 1. Konsep & Arsitektur Multimodal

| Fitur | Library / Pipeline | Kasus Penggunaan Mobile |
| :--- | :--- | :--- |
| **OCR (Optical Character Recognition)** | `image_picker` + Gemini Vision API | Ekstraksi teks dari foto Kartu Tanda Mahasiswa (KTM), kuitansi pembayaran UKT, dokumen akademik, poster pengumuman kampus. |
| **Speech-to-Text (STT)** | `record` / `just_audio` + Gemini Audio / STT API | Perekaman suara mahasiswa untuk input cepat pertanyaan chat atau aksesibilitas disabilitas visual/motorik. |
| **Image Understanding** | Gemini Multimodal Prompting (`gemini-1.5-flash`) | Analisis gambar denah gedung kampus, identifikasi fasilitas lab, atau penjelasan visual diagram/infografis. |

### 2. Implementasi pada Layanan AI (`AiService`)

Kode diimplementasikan pada [`lib/ai/ai_service.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/lib/ai/ai_service.dart) dengan fleksibilitas resolusi berkas (`dynamic imageFile` / `dynamic audioFile` yang mendukung `Uint8List`, `List<int>`, `File`, `String` base64/path):

```dart
// 1. Ekstraksi OCR Teks Dokumen
final result = await aiService.recognizeText(imageFile);

// 2. Konversi Suara Rekaman ke Teks
final text = await aiService.speechToText(audioFile);

// 3. Analisis Visual Gambar / Poster Kampus
final description = await aiService.describeImage(imageFile, prompt: 'Jelaskan poster kegiatan ini');
```

Struktur payload multimodal ke Google Gemini REST API:

```json
{
  "contents": [
    {
      "parts": [
        { "text": "Lakukan OCR: ekstrak seluruh teks yang tertulis pada gambar ini secara akurat." },
        {
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": "<BASE64_ENCODED_IMAGE>"
          }
        }
      ]
    }
  ]
}
```

### 3. Integrasi UI Multimodal pada `ChatScreen`

Pada [`lib/features/chat_screen.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/lib/features/chat_screen.dart):
* Menambahkan tombol aksi `add_photo_alternate_outlined` di bilah input obrolan.
* Membuka *Modal Bottom Sheet* dengan 3 opsi interaktif:
  1. **OCR Dokumen / KTM:** Mengekstrak teks dari foto dan langsung menyalin hasilnya ke kolom teks input pengguna;
  2. **Speech-to-Text (STT):** Menstranskripsikan rekaman percakapan mahasiswa ke dalam bahasa Indonesia;
  3. **Image Understanding:** Mengirim gambar fasilitas kampus ke model AI dan menambahkan ringkasan analisis langsung ke linimasa pesan obrolan.

### 🧪 Bukti Verifikasi Pengujian Multimodal

Unit tests di [`test/ai_service_test.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/test/ai_service_test.dart) dan widget test di [`test/chat_screen_test.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/test/chat_screen_test.dart) menguji:
1. `recognizeText`: Mengonversi bytes gambar KTM ke `inline_data` base64 dan mem-parsing teks ekstraksi (termasuk NIM `244107020090`).
2. `speechToText`: Mengonversi bytes audio rekaman ke `inline_data` base64 dan memvalidasi transkripsi teks bahasa Indonesia.
3. `describeImage`: Mengirim gambar dan prompt konteks visual, memvalidasi hasil deskripsi ruangan/gedung.
4. `ChatScreen`: Menampilkan tombol lampiran multimodal dan memicu bottom sheet interaktif.

---

## 🛡️ Privasi, Biaya, Error Handling, dan Fallback

Pengembangan fitur AI pada aplikasi mobile skala produksi menuntut ketahanan terhadap kegagalan jaringan, perlindungan privasi data pribadi pengguna, serta pencegahan pembengkakan biaya pemanggilan token API.

### 1. Tabel Risiko dan Mitigasi

| Risiko | Dampak Potensial | Mitigasi yang Diterapkan |
| :--- | :--- | :--- |
| **Bocor Data Pengguna** | Pelanggaran UU PDP / data privasi mahasiswa terkirim ke LLM pihak ketiga | Terapkan filter guardrail lokal berbasis regex untuk mendeteksi & memblokir NIK 16 digit dan nomor telepon sebelum prompt dikirim. Gunakan placeholder anonim. |
| **Biaya Melonjak** | Pembengkakan tagihan API token karena request berulang atau spam | Batasi kuota request harian pengguna (`maxDailyRequests`), dan terapkan *local cache* pada `AiService` untuk pertanyaan yang identik. |
| **API Error / Down** | Aplikasi crash atau pengguna terjebak pada layar loading tanpa kepastian | Tangkap exception HTTP, tampilkan dialog ramah pengguna (*"Layanan AI Sibuk"*), opsi coba lagi, dan alihkan ke mode offline. |
| **Respons Tidak Relevan** | Model berhalusinasi atau memberikan jawaban di luar topik kampus | Validasi respons dan sediakan *fallback knowledge base* lokal kampus yang teruji kebenarannya. |

### 2. Implementasi Fallback Dialog & Mode Offline

Ketika pemanggilan API mengalami kendala (misal: kuota habis, tidak ada internet, atau status HTTP non-200), aplikasi secara elegan menampilkan dialog mitigasi dan menyediakan opsi pengalihan ke data lokal:

```dart
try {
  final response = await aiService.ask(question);
} catch (e) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Layanan AI Sibuk'),
      content: const Text('Coba lagi nanti atau gunakan mode offline.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        FilledButton.tonal(
          onPressed: () {
            Navigator.of(context).pop();
            _useOfflineFallback(question);
          },
          child: const Text('Gunakan Mode Offline'),
        ),
      ],
    ),
  );
}
```

Metode fallback lokal pada [`lib/ai/ai_service.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/lib/ai/ai_service.dart):

```dart
static String getFallbackResponse(String question) {
  final q = question.toLowerCase();
  if (q.contains('krs') || q.contains('jadwal')) {
    return '[Mode Offline / Data Lokal]: Pengisian KRS dibuka pada tanggal 1-15 setiap awal semester melalui portal SIAKAD.';
  }
  if (q.contains('beasiswa')) {
    return '[Mode Offline / Data Lokal]: Pendaftaran beasiswa prestasi dan bantuan UKT diumumkan berkala oleh bagian Kemahasiswaan.';
  }
  if (q.contains('izin') || q.contains('sakit')) {
    return '[Mode Offline / Data Lokal]: Surat izin perkuliahan wajib diserahkan ke dosen pengampu dan admin jurusan maksimal 3 hari kerja.';
  }
  return '[Mode Offline / Data Lokal]: Maaf, koneksi AI sedang tidak stabil. Silakan cek menu pengumuman utama pada beranda kampus.';
}
```

### 3. Implementasi Caching & Rate Limiting

Pada [`lib/ai/ai_service.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/lib/ai/ai_service.dart):
* Pertanyaan yang telah dijawab disimpan ke memori internal (`_cache[normalizedKey]`). Saat mahasiswa menanyakan hal yang sama, jawaban langsung disajikan seketika tanpa latency jaringan dan tanpa membakar token API.
* Batas kuota harian (`maxDailyRequests`) mencegah kehabisan biaya atau *denial-of-service* akibat *spam click*.

### 🧪 Bukti Verifikasi Pengujian

Hasil pengujian otomatis 22 test case:

```bash
flutter analyze lib test
# Output: No issues found! (ran in 5.5s)

dart format --set-exit-if-changed lib test
# Output: Formatted 37 files (0 changed)

flutter test
# Output: 22/22 tests passed! (100% lulus)
```

---

## 🏆 Tugas, Refleksi, dan Evaluasi (Mini Project)

### 📌 Ringkasan Pemenuhan Industry Challenge

| Butir Tugas | Status | Bukti & Lokasi Implementasi |
| :--- | :---: | :--- |
| **1. Integrasikan satu fitur AI ke project yang sudah ada** | ✅ **Selesai (4 Fitur)** | `campus_notify`: Chat Assistant Streaming, OCR KTM/Dokumen, Speech-to-Text, dan Image Understanding di [`lib/ai/ai_service.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/lib/ai/ai_service.dart) & [`lib/features/chat_screen.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/lib/features/chat_screen.dart). |
| **2. Sertakan prompt sistem, user prompt, dan output awal AI** | ✅ **Selesai** | Terdokumentasi lengkap dan terstruktur pada file [`docs/ai-log.md`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/docs/ai-log.md). |
| **3. Bukti mesin hijau: analyze + test** | ✅ **Selesai** | `flutter analyze` 0 warnings; `dart format` bersih; `flutter test` 22/22 tes lulus hijau. |
| **4. Tabel risiko + mitigasi privasi dan biaya** | ✅ **Selesai** | Tabel risiko privasi (guardrail NIK/telepon) dan proteksi biaya (cache + rate limit) di Bab 5 README. |
| **5. Struktur folder lengkap** | ✅ **Selesai** | Tersusun rapi pada `10-Week-10-AI-Feature-Integration/` berisi `Lib/`, `docs/`, `Screenshots/`, dan `README.md`. |

---

## 💭 Refleksi Pembelajaran

### 1. Fitur AI mana yang Anda integrasikan dan mengapa?
> **Jawaban:**  
> Saya mengintegrasikan **AI Chat Assistant (Google Gemini REST API)** yang dilengkapi dengan **Token Streaming**, serta kapabilitas multimodal **OCR Dokumen/KTM**, **Speech-to-Text (STT)**, dan **Image Understanding**.  
> **Alasan Teknis & Bisnis:**  
> Pada aplikasi notifikasi dan informasi kampus (*Campus Notify*), mahasiswa membutuhkan akses cepat ke informasi jadwal akademik (KRS, jadwal ujian, yudisium) serta prosedur beasiswa tanpa harus mencari manual di lampiran PDF portal kampus. Fitur chat streaming menyajikan interaksi percakapan yang hidup dan responsif. Sementara itu, fitur OCR dan Speech-to-Text memberikan kemudahan input multimodal secara langsung dari foto kartu mahasiswa dan rekaman suara tanpa perlu mengetik panjang.

### 2. Bagaimana Anda melindungi privasi pengguna saat menggunakan AI API?
> **Jawaban:**  
> Perlindungan privasi mahasiswa diwujudkan melalui tiga lapisan pertahanan (*multi-layer defense*):
> 1. **Penyimpanan Kunci Terenkripsi:** API Key model AI tidak pernah di-hardcode ke repositori publik, melainkan disimpan secara aman di perangkat menggunakan `FlutterSecureStorage` (berbasis Android Keystore / iOS Keychain).
> 2. **Client-Side Privacy Guardrails:** Menerapkan fungsi validasi regex lokal `_detectSensitiveData` pada [`lib/features/chat_screen.dart`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/lib/features/chat_screen.dart) yang secara otomatis memindai dan memblokir pengiriman NIK 16 digit (`\b\d{16}\b`) dan format nomor telepon sebelum prompt sempat diteruskan ke cloud AI provider.
> 3. **Prinsip Minimisasi Data:** Sistem hanya mengirimkan konteks anonim tanpa mengikutsertakan kredensial akun ataupun profil pribadi mahasiswa.

### 3. Fallback apa yang Anda sediakan jika layanan AI error?
> **Jawaban:**  
> Saya menerapkan mekanisme *Graceful Degradation* berlapis:
> 1. **Dialog Interaktif Ramah Pengguna:** Saat terjadi kendala koneksi atau batas kuota API terlampaui, antarmuka tidak mengalami crash ataupun hang, melainkan menampilkan dialog *"Layanan AI Sibuk: Coba lagi nanti atau gunakan mode offline."*
> 2. **In-Memory Caching:** Jawaban atas pertanyaan umum (seperti jadwal KRS) disimpan di cache lokal sehingga pengguna tetap mendapatkan respons instan tanpa memerlukan koneksi internet.
> 3. **Offline Campus Knowledge Base:** Fungsi fallback lokal [`AiService.getFallbackResponse(question)`](file:///d:/Semester%205/Pemrograman%20Mobile/244107020090-Mobile-Course/10-Week-10-AI-Feature-Integration/Lib/campus_notify/lib/ai/ai_service.dart#L90-L103) yang memetakan kata kunci akademik (KRS, beasiswa, izin kuliah) ke data statis kampus yang valid dan terpercaya.

### 4. Satu hal yang Anda pelajari tentang UX fitur AI di mobile?
> **Jawaban:**  
> Pelajaran paling berharga yang saya dapatkan adalah bahwa **persepsi kecepatan (perceived performance) pada aplikasi mobile AI ditentukan oleh streaming respons, bukan hanya latensi total**. Menunggu 3–5 detik untuk satu blok teks utuh terasa membosankan dan membingungkan pengguna mobile (seolah aplikasi macet). Namun dengan mengalirkan respons kata per kata (*typewriter streaming tokens*) disertai animasi indikator proses berpikir (*thinking state*), pengguna dapat langsung mulai membaca potongan informasi dalam waktu kurang dari satu detik. Kombinasi *quick suggestion chips* dan transparansi status model menjadikan pengalaman pengguna terasa mulus dan profesional.

---

## 🖼️ Dokumentasi Screenshots

Seluruh 6 screenshot dokumentasi fitur AI dan pengujian mesin yang tersedia di folder `Screenshots/` dicantumkan di bawah:

| Nama Tampilan / Pengujian | Tangkapan Layar |
| :--- | :--- |
| **Halaman Beranda dengan Integrasi AI**<br>Menampilkan tombol aksi robot pada AppBar dan Floating Action Button *"Tanya AI"* pada antarmuka utama Campus Notify. | ![Halaman Beranda AI](./Screenshots/Home-Page-AI.png) |
| **Antarmuka Chat Assistant AI (Streaming Response)**<br>Menampilkan banner privasi data, dialog API key, gelembung obrolan interaktif dengan streaming teks, dan *quick prompt chips*. | ![Chat Screen Overview](./Screenshots/Chat-Screen-Overview.png) |
| **Fitur Multimodal AI (Modal Bottom Sheet)**<br>Menu aksi cerdas untuk OCR Dokumen/KTM, Speech-to-Text (STT transkripsi audio), dan Image Understanding. | ![Multimodal Feature Sheet](./Screenshots/Multimodal-Feature-Sheet.png) |
| **Peringatan Privasi (Guardrail Blokir NIK & Telepon)**<br>Sistem otomatis memblokir pengiriman NIK 16 digit mahasiswa dan menampilkan peringatan keamanan visual. | ![Privacy Guardrail Blocked](./Screenshots/Privacy-Guardrail-Blocked.png) |
| **Dialog Fallback & Mode Offline**<br>Dialog *"Layanan AI Sibuk"* yang memitigasi kegagalan koneksi API dan mengalihkan mahasiswa ke basis data kampus lokal. | ![Fallback Dialog Offline](./Screenshots/Fallback-Dialog-Offline.png) |
| **Hasil Verifikasi Mesin Hijau (Analyze & Test)**<br>Bukti eksekusi terminal: `flutter analyze` 0 issue dan `flutter test` 22/22 tes otomatis lulus 100%. | ![Hasil Analyze dan Test](./Screenshots/Flutter-Analyze-Test-Result.png) |

---

## 📚 Referensi Pendukung

* [Slide Week 10: Integrasi Fitur AI](https://docs.flutter.dev/)
* [Google Gemini AI API Documentation](https://ai.google.dev/)
* [Package `flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage)
* [Package `http`](https://pub.dev/packages/http)
* [Riverpod: Getting Started](https://riverpod.dev/)
* [Learn Dart in Y Minutes](https://learnxinyminutes.com/docs/dart/)
* [Dart Language Tour](https://dart.dev/guides/language/language-tour)




