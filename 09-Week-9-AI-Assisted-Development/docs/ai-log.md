# 🤖 Log AI-Assisted Development (AI Log)

Dokumen ini merupakan pencatatan resmi seluruh interaksi prompt AI, evaluasi halusinasi, dan verifikasi keputusan pada **Minggu 9 — AI-Assisted Development / Vibe Coding**.

---

## 1. Identitas Praktikan
* **Nama:** Fadhil Taufiqurrachman
* **NIM:** 244107020090
* **Project Target:** `week5_offline_notes` & `campus_notify` (Clean Architecture)
* **Fitur yang Dikembangkan:** Search & Empty State

---

## 2. Praktikum 1: Prompt & Context Engineering

### Formula 5 Slot Standar Industri
Setiap prompt yang diajukan ke AI coding assistant dirancang menggunakan formula 5 elemen:

1. **Peran (Role):** Senior Flutter Developer & Clean Architecture Specialist.
2. **Konteks (Context):** Mobile app Flutter 3 (Dart 3), state management Riverpod, offline-first SQLite / REST API Dio, struktur *feature-first* (`presentation -> domain <- data`).
3. **Tugas (Task):** Menambahkan fitur pencarian (*search filter*) berdasarkan kata kunci pada daftar data, disertai penanganan status kosong (*empty state*).
4. **Batasan (Constraints):**
   - Wajib mematuhi *The Dependency Rule* (UI dilarang memanggil database/API langsung).
   - Filter harus *case-insensitive* dan menangani *leading/trailing whitespace*.
   - Ukuran kode ringkas (< 80 baris perubahan logis).
   - Tidak mengubah kontrak arsitektur yang sudah berjalan stabil.
5. **Output (Expected Output):** Potongan kode controller/notifier + widget UI + minimal 2 unit test + langkah pengujian manual.

---

### Perbandingan Kualitas Prompt

| Karakteristik | Prompt Buruk (*Vibe Coding*) | Prompt Berkualitas (*Context-Engineered*) |
| :--- | :--- | :--- |
| **Deskripsi** | `"buatkan search notes yang keren dan canggih"` | `"Buatkan fitur pencarian judul catatan (search notes). Arsitektur: feature-first presentation -> domain <- data. Jangan panggil SQLite dari widget. Filter case-insensitive via Riverpod provider. Sertakan tampilan empty state dan 2 unit test."` |
| **Dampak Hasil** | Menghasilkan kode monolitik (logic campur di widget), rawan halusinasi package baru, tidak ada pengujian, melanggar Clean Architecture. | Menghasilkan kode modular, terikat Riverpod provider yang ada, langsung dapat diuji, dan steril dari pelanggaran layer. |

---

### Protokol Privasi & Context Masking
Sebelum mengajukan konteks file kode ke AI, seluruh kredensial dan data sensitif disanitasi:
* Token autentikasi FCM / JWT $\rightarrow$ Diganti dengan `TOKEN_PLACEHOLDER`
* User ID & API Secret $\rightarrow$ Diganti dengan `MOCK_USER_ID` dan `DUMMY_SECRET_KEY`
* File yang dilampirkan hanya mencakup interface kontrak (`repository`), model entitas, dan potongan konfigurasi `pubspec.yaml` yang relevan.
