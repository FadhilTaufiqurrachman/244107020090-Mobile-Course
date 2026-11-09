# 🤖 AI Prompt Engineering & Integration Log

> **Mata Kuliah:** Pemrograman Mobile  
> **Modul:** Minggu 10 — Integrasi Fitur AI  
> **Nama Mahasiswa:** Fadhil Taufiqurrachman  
> **NIM:** 244107020090  
> **Tanggal Implementasi:** 9 November 2026  
> **Proyek Basis:** `campus_notify` (Clean Architecture + Flutter Riverpod)

---

## 📋 1. Ringkasan Fitur yang Diintegrasikan

Pada praktikum Minggu 10, empat kemampuan AI diintegrasikan ke dalam aplikasi **Campus Notify**:
1. **Interactive Chat Assistant:** Tanya jawab real-time dengan streaming tokens (*typewriter effect*) memanfaatkan endpoint model Google Gemini (`gemini-pro`);
2. **OCR (Optical Character Recognition):** Ekstraksi teks dari gambar Kartu Tanda Mahasiswa (KTM), poster kegiatan, dan dokumen pengumuman (`gemini-1.5-flash`);
3. **Speech-to-Text (STT):** Transkripsi rekaman audio suara mahasiswa ke dalam teks bahasa Indonesia;
4. **Image Understanding:** Pemahaman dan analisis visual konteks fasilitas atau poster acara kampus.

---

## 🎯 2. Prompt Engineering Log

### A. Chat Assistant (Text Generation)

#### Formula 4 Komponen Prompt Mobile

| Komponen | Spesifikasi & Nilai Prompt |
| :--- | :--- |
| **System Prompt** | `"Kamu adalah Campus AI Assistant yang ramah, sopan, dan berfokus pada informasi perkuliahan di Politeknik Negeri Malang (Polinema). Jawab selalu dalam Bahasa Indonesia yang ringkas, jelas, maksimal 2-3 kalimat, dan mudah dibaca pada layar perangkat mobile."` |
| **User Prompt** | `"Kapan batas akhir pengisian KRS semester ini dan apa syarat perpanjangannya?"` |
| **Konteks** | Kalender akademik tahun 2026/2027, portal SIAKAD Polinema, pedoman administrasi akademik semester ganjil/genap. |
| **Batasan (*Guardrails*)** | `"Jangan pernah meminta atau menyertakan data sensitif pengguna (NIK 16 digit, nomor telepon, kata sandi, alamat rumah). Jangan memberikan informasi di luar konteks kampus. Jika tidak yakin, sarankan mahasiswa untuk konfirmasi ke Bagian Akademik."` |

#### Output Awal AI (Raw Gemini Response)
```text
Pengisian KRS Semester Ganjil dibuka hingga tanggal 15 November 2026 pukul 23.59 WIB melalui portal SIAKAD. Untuk perpanjangan KRS, mahasiswa wajib mengajukan surat permohonan yang ditandatangani Dosen Pembina Akademik (DPA) ke loket Bagian Akademik sebelum masa revisi berakhir.
```

#### Verifikasi & Evaluasi Developer
* **Kerapian Jawaban:** Memenuhi batas 2 kalimat, langsung menjawab inti pertanyaan, dan nada bicara ramah.
* **Kesesuaian Mobile UX:** Panjang teks cocok untuk ukuran bubble chat layar smartphone tanpa memerlukan vertical scrolling yang berlebihan.
* **Keamanan:** Tidak membocorkan atau meminta identitas sensitif mahasiswa.

---

### B. OCR Dokumen / KTM (Multimodal Vision)

#### Prompt & Konfigurasi
* **Endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`
* **Prompt Teks:**  
  `"Lakukan OCR: ekstrak seluruh teks yang tertulis pada gambar ini secara akurat. Tampilkan hanya teks yang terdeteksi tanpa tambahan komentar atau markdown formatting berlebih."`
* **Input Data:** Berkas gambar kartu mahasiswa (KTM) atau poster pengumuman berkas JPEG/PNG di-encode ke Base64 via `inline_data`.

#### Output Awal Ekstraksi OCR
```text
KARTU TANDA MAHASISWA
POLITEKNIK NEGERI MALANG
NAMA: FADHIL TAUFIQURRACHMAN
NIM: 244107020090
PRODI: D4 TEKNIK INFORMATIKA
JURUSAN: TEKNOLOGI INFORMASI
```

#### Tindakan Aplikasi
Teks hasil ekstraksi otomatis disalin ke `_controller.text` pada bilah input obrolan pengguna, mempermudah mahasiswa menanyakan detail terkait identitas/dokumen tanpa perlu mengetik ulang secara manual.

---

### C. Speech-to-Text (Audio Multimodal)

#### Prompt & Konfigurasi
* **Prompt Teks:**  
  `"Transkripsikan rekaman audio berikut secara persis ke dalam teks bahasa Indonesia tanpa format tambahan."`
* **Input Data:** Rekaman suara mikrofon dalam format MP3/AAC/WAV di-encode ke Base64 via `inline_data` mime type `audio/mp3`.

#### Output Transkripsi
```text
Tolong jelaskan pengumuman beasiswa prestasi dan bantuan UKT terbaru di kampus.
```

---

### D. Image Understanding (Visual Context Analysis)

#### Prompt & Konfigurasi
* **Prompt Teks:**  
  `"Jelaskan isi gambar fasilitas atau kegiatan kampus ini secara detail, informatif, dan ringkas untuk mahasiswa."`
* **Input Data:** Foto ruangan lab komputer atau perpustakaan kampus.

#### Output AI
```text
[Image Understanding]: Gambar menunjukkan ruang laboratorium komputer terpadu yang dilengkapi dengan fasilitas workstation modern dan proyektor presentasi. Ruangan ini digunakan untuk praktikum pemrograman dan riset mahasiswa.
```

---

## 🛡️ 3. Tabel Keputusan Rekayasa & Mitigasi Risiko

| Kategori | Keputusan Rekayasa | Alasan & Bukti Uji |
| :--- | :--- | :--- |
| **Pencegahan Kebocoran Data (Privacy Guardrail)** | Validasi regex client-side pada `_detectSensitiveData(text)` untuk memblokir NIK 16 digit (`\b\d{16}\b`) dan format nomor telepon Indonesia (`(\+62\|62\|08)[0-9]{8,12}`). | Mencegah pelanggaran privasi (UU PDP) sebelum data keluar dari perangkat mobile. Terbukti lulus uji widget test `chat_screen_test.dart`. |
| **Penghematan Biaya & Efisiensi Token** | Penerapan in-memory normalization cache (`_cache[normalizedKey]`) pada `AiService`. Pertanyaan identik dilayani tanpa pemanggilan HTTP baru. | Memangkas kuota token dan mengurangi beban server. Panggilan ke-2 untuk `"jadwal krs"` mencatat 0 network calls. |
| **Rate Limiting (Proteksi Biaya)** | Pembatasan kuota request harian pengguna (`maxDailyRequests = 30`). | Mencegah lonjakan tagihan akibat loop otomatis atau spam tap. Menghasilkan exception informatif jika kuota terlampaui. |
| **Resilience & Fallback Offline** | Penyediaan dialog ramah `"Layanan AI Sibuk"` dan fallback basis pengetahuan kampus lokal (`AiService.getFallbackResponse`). | Menjamin aplikasi tetap fungsional dan memberikan informasi darurat saat perangkat kehilangan sinyal atau server AI sedang down. |

---

## 🧪 4. Bukti Verifikasi Mesin

Seluruh pengujian unit dan widget otomatis lulus 100%:

```text
00:00 +0: core_format_test.dart
00:00 +2: get_announcement_detail_test.dart
00:01 +5: login_usecase_test.dart
00:01 +7: ai_service_test.dart (API Key Missing test)
00:01 +8: ai_service_test.dart (SecureStorage Save/Read test)
00:01 +9: ai_service_test.dart (Gemini 200 JSON Parse test)
00:01 +10: ai_service_test.dart (Status non-200 Exception test)
00:01 +11: ai_service_test.dart (askStream chunk test)
00:01 +12: ai_service_test.dart (recognizeText OCR test)
00:01 +13: ai_service_test.dart (speechToText STT test)
00:01 +14: ai_service_test.dart (describeImage Vision test)
00:01 +15: ai_service_test.dart (Cache hit test)
00:01 +16: ai_service_test.dart (Rate limit quota test)
00:01 +17: ai_service_test.dart (Offline fallback test)
00:01 +18: chat_screen_test.dart (Render UI & Privacy banner test)
00:01 +19: chat_screen_test.dart (Block NIK 16 digit guardrail test)
00:01 +20: chat_screen_test.dart (Multimodal bottom sheet test)
00:01 +21: chat_screen_test.dart (Layanan AI Sibuk dialog & offline switch test)
00:01 +22: All tests passed!
```

