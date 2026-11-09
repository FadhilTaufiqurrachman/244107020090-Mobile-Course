import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiService {
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String _apiUrl;

  AiService({FlutterSecureStorage? storage, http.Client? client, String? apiUrl})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client(),
      _apiUrl =
          apiUrl ??
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  Future<Uint8List> _resolveBytes(dynamic input) async {
    if (input is Uint8List) return input;
    if (input is List<int>) return Uint8List.fromList(input);
    if (input is File) return await input.readAsBytes();
    if (input is String) {
      final file = File(input);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      try {
        return base64Decode(input);
      } catch (_) {
        return Uint8List.fromList(utf8.encode(input));
      }
    }
    try {
      final dynamic dynamicInput = input;
      final bytes = await dynamicInput.readAsBytes();
      if (bytes is Uint8List) return bytes;
      if (bytes is List<int>) return Uint8List.fromList(bytes);
    } catch (_) {}

    throw ArgumentError('Tipe berkas tidak didukung: ${input.runtimeType}');
  }

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
              {'text': question},
            ],
          },
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

  /// OCR: Ekstraksi teks dari gambar KTM, receipt, pengumuman, atau dokumen
  Future<String> recognizeText(
    dynamic imageFile, {
    String mimeType = 'image/jpeg',
  }) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final bytes = await _resolveBytes(imageFile);
    final base64Image = base64Encode(bytes);

    // Menggunakan endpoint model multimodal flash/vision
    final visionUrl = _apiUrl.replaceAll('gemini-pro', 'gemini-1.5-flash');

    final response = await _client.post(
      Uri.parse('$visionUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'Lakukan OCR: ekstrak seluruh teks yang tertulis pada gambar ini secara akurat. Tampilkan hanya teks yang terdeteksi tanpa tambahan komentar.',
              },
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Image},
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gagal melakukan OCR: ${response.statusCode}');
    }
  }

  /// Speech-to-Text: Mengonversi rekaman suara menjadi teks
  Future<String> speechToText(
    dynamic audioFile, {
    String mimeType = 'audio/mp3',
  }) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final bytes = await _resolveBytes(audioFile);
    final base64Audio = base64Encode(bytes);

    final audioUrl = _apiUrl.replaceAll('gemini-pro', 'gemini-1.5-flash');

    final response = await _client.post(
      Uri.parse('$audioUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'Transkripsikan rekaman audio berikut secara persis ke dalam teks bahasa Indonesia tanpa format tambahan.',
              },
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Audio},
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gagal melakukan Speech-to-Text: ${response.statusCode}');
    }
  }

  /// Image Understanding: Menganalisis konteks atau deskripsi visual gambar
  Future<String> describeImage(
    dynamic imageFile, {
    String? prompt,
    String mimeType = 'image/jpeg',
  }) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final bytes = await _resolveBytes(imageFile);
    final base64Image = base64Encode(bytes);

    final visionUrl = _apiUrl.replaceAll('gemini-pro', 'gemini-1.5-flash');

    final response = await _client.post(
      Uri.parse('$visionUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': prompt ?? 'Jelaskan isi gambar ini secara detail, informatif, dan ringkas untuk mahasiswa kampus.',
              },
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Image},
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gagal menganalisis gambar: ${response.statusCode}');
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
