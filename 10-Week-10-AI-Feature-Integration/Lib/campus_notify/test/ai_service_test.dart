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
  });
}
