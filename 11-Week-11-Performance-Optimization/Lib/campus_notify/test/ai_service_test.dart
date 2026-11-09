import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:campus_notify/ai/ai_service.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }
}

void main() {
  group('AiService Tests', () {
    late FakeSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeSecureStorage();
    });

    test('Melempar exception jika API key belum tersedia', () async {
      final aiService = AiService(storage: fakeStorage);

      expect(
        () => aiService.ask('Halo kampus'),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('API key tidak tersedia'),
          ),
        ),
      );
    });

    test('Berhasil menyimpan dan membaca API key ke Secure Storage', () async {
      final aiService = AiService(storage: fakeStorage);

      await aiService.saveApiKey('test-api-key-12345');
      final savedKey = await aiService.getApiKey();

      expect(savedKey, 'test-api-key-12345');
    });

    test(
      'Berhasil memanggil Gemini API dan mem-parsing jawaban teks',
      () async {
        await fakeStorage.write(key: 'ai_api_key', value: 'valid-test-key');

        final mockClient = MockClient((request) async {
          expect(request.url.queryParameters['key'], 'valid-test-key');
          expect(request.headers['Content-Type'], 'application/json');

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['contents'][0]['parts'][0]['text'], 'Kapan batas KRS?');

          final fakeResponse = {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Batas pengisian KRS adalah 15 November 2026.'},
                  ],
                },
              },
            ],
          };

          return http.Response(jsonEncode(fakeResponse), 200);
        });

        final aiService = AiService(storage: fakeStorage, client: mockClient);

        final response = await aiService.ask('Kapan batas KRS?');
        expect(response, 'Batas pengisian KRS adalah 15 November 2026.');
      },
    );

    test('Melempar exception jika status code API bukan 200', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'invalid-key');

      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final aiService = AiService(storage: fakeStorage, client: mockClient);

      expect(
        () => aiService.ask('Pertanyaan error'),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Gagal memanggil AI API: 401'),
          ),
        ),
      );
    });

    test('askStream mengalirkan kata secara berurutan', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'valid-test-key');

      final mockClient = MockClient((request) async {
        final fakeResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Halo mahasiswa Polinema'},
                ],
              },
            },
          ],
        };
        return http.Response(jsonEncode(fakeResponse), 200);
      });

      final aiService = AiService(storage: fakeStorage, client: mockClient);

      final chunks = await aiService.askStream('Tes stream').toList();
      expect(chunks.length, 3);
      expect(chunks.join(''), 'Halo mahasiswa Polinema');
    });

    test('recognizeText berhasil mengekstrak teks OCR dari gambar', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'valid-test-key');

      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final parts = body['contents'][0]['parts'] as List<dynamic>;

        expect(parts[0]['text'], contains('Lakukan OCR'));
        expect(parts[1]['inline_data']['mime_type'], 'image/jpeg');

        final fakeResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'KARTU TANDA MAHASISWA\nNAMA: FADHIL\nNIM: 244107020090',
                  },
                ],
              },
            },
          ],
        };
        return http.Response(jsonEncode(fakeResponse), 200);
      });

      final aiService = AiService(storage: fakeStorage, client: mockClient);
      final rawImageBytes = utf8.encode('dummy-ktm-image-bytes');
      final result = await aiService.recognizeText(rawImageBytes);

      expect(result, contains('244107020090'));
      expect(result, contains('KARTU TANDA MAHASISWA'));
    });

    test('speechToText berhasil mengonversi audio ke teks', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'valid-test-key');

      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final parts = body['contents'][0]['parts'] as List<dynamic>;

        expect(parts[0]['text'], contains('Transkripsikan'));
        expect(parts[1]['inline_data']['mime_type'], 'audio/mp3');

        final fakeResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text':
                        'Tolong jelaskan pengumuman beasiswa terbaru kampus',
                  },
                ],
              },
            },
          ],
        };
        return http.Response(jsonEncode(fakeResponse), 200);
      });

      final aiService = AiService(storage: fakeStorage, client: mockClient);
      final rawAudioBytes = utf8.encode('dummy-voice-recording');
      final text = await aiService.speechToText(rawAudioBytes);

      expect(text, 'Tolong jelaskan pengumuman beasiswa terbaru kampus');
    });

    test('describeImage berhasil memberikan deskripsi visual', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'valid-test-key');

      final mockClient = MockClient((request) async {
        final fakeResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'Gambar menunjukkan suasana perpustakaan lantai 3 Polinema.',
                  },
                ],
              },
            },
          ],
        };
        return http.Response(jsonEncode(fakeResponse), 200);
      });

      final aiService = AiService(storage: fakeStorage, client: mockClient);
      final rawImageBytes = utf8.encode('dummy-campus-photo');
      final description = await aiService.describeImage(
        rawImageBytes,
        prompt: 'Jelaskan fasilitas kampus dalam gambar ini',
      );

      expect(
        description,
        'Gambar menunjukkan suasana perpustakaan lantai 3 Polinema.',
      );
    });

    test(
      'Cache lokal menghemat panggilan API untuk pertanyaan yang sama',
      () async {
        await fakeStorage.write(key: 'ai_api_key', value: 'valid-test-key');

        int networkCalls = 0;
        final mockClient = MockClient((request) async {
          networkCalls++;
          final fakeResponse = {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Jadwal KRS tanggal 1-15 November.'},
                  ],
                },
              },
            ],
          };
          return http.Response(jsonEncode(fakeResponse), 200);
        });

        final aiService = AiService(storage: fakeStorage, client: mockClient);

        // Panggilan pertama (memanggil network)
        final res1 = await aiService.ask('Jadwal KRS');
        expect(res1, 'Jadwal KRS tanggal 1-15 November.');
        expect(networkCalls, 1);
        expect(aiService.cacheSize, 1);

        // Panggilan kedua pertanyaan sama (harus dilayani dari cache)
        final res2 = await aiService.ask('jadwal krs');
        expect(res2, 'Jadwal KRS tanggal 1-15 November.');
        expect(networkCalls, 1); // Tidak ada tambahan panggilan HTTP!
      },
    );

    test('Mencegah pembengkakan biaya dengan membatasi kuota harian', () async {
      await fakeStorage.write(key: 'ai_api_key', value: 'valid-test-key');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Jawaban valid'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      // Set batas kuota kecil: maks 2 request
      final aiService = AiService(
        storage: fakeStorage,
        client: mockClient,
        maxDailyRequests: 2,
      );

      await aiService.ask('Pertanyaan 1', useCache: false);
      await aiService.ask('Pertanyaan 2', useCache: false);

      // Panggilan ke-3 harus dilempar exception batas kuota
      expect(
        () => aiService.ask('Pertanyaan 3', useCache: false),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Batas kuota harian tercapai'),
          ),
        ),
      );
    });

    test(
      'getFallbackResponse mengembalikan jawaban offline kampus yang akurat',
      () {
        final krsFallback = AiService.getFallbackResponse('kapan jadwal krs?');
        expect(krsFallback, contains('SIAKAD'));

        final beasiswaFallback = AiService.getFallbackResponse('info beasiswa');
        expect(beasiswaFallback, contains('Kemahasiswaan'));

        final generalFallback = AiService.getFallbackResponse(
          'pertanyaan acak lainnya',
        );
        expect(generalFallback, contains('Mode Offline'));
      },
    );
  });
}
