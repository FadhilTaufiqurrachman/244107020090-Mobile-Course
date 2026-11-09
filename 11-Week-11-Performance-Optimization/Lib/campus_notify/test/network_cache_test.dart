import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/network_cache.dart';
import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:campus_notify/features/auth/data/datasources/token_store.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';

class FakeTokenStore implements TokenStore {
  String? access;
  String? refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }
}

class FakeAuthRepo implements AuthRepository {
  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async => (session: null, failure: null);

  @override
  Future<({String? refreshedToken, Failure? failure})> refresh(
    String refreshToken,
  ) async => (refreshedToken: null, failure: null);
}

void main() {
  group('Network Caching & Performance Tests', () {
    late InMemoryCacheStorage cacheStorage;

    setUp(() {
      cacheStorage = InMemoryCacheStorage();
    });

    test('InMemoryCacheStorage menyimpan, membaca, dan menghapus cache', () {
      cacheStorage.write('profile', {'name': 'Fadhil', 'nim': '244107020090'});
      expect(cacheStorage.hasValid('profile'), isTrue);

      final data = cacheStorage.read<Map<String, dynamic>>('profile');
      expect(data?['name'], 'Fadhil');
      expect(data?['nim'], '244107020090');

      cacheStorage.clear();
      expect(cacheStorage.read('profile'), isNull);
      expect(cacheStorage.hasValid('profile'), isFalse);
    });

    test('CacheInterceptor melayani request dengan strategi Cache-First', () async {
      final dio = Dio();
      dio.interceptors.add(
        CacheInterceptor(
          storage: cacheStorage,
          policy: CachePolicy.cacheFirst,
        ),
      );

      // Isi cache terlebih dahulu
      const testUrl = 'https://api.test/profile';
      cacheStorage.write(testUrl, {'status': 'cached_data'});

      // Request GET ke URL tersebut akan langsung diselesaikan dari cache tanpa memukul server
      final response = await dio.get(testUrl);
      expect(response.statusCode, 200);
      expect(response.statusMessage, 'OK (From Cache)');
      expect(response.data['status'], 'cached_data');
    });

    test('CacheInterceptor melempar error pada Cache-Only jika cache kosong', () async {
      final dio = Dio();
      dio.interceptors.add(
        CacheInterceptor(
          storage: cacheStorage,
          policy: CachePolicy.cacheOnly,
        ),
      );

      expect(
        () async => await dio.get('https://api.test/missing'),
        throwsA(isA<DioException>()),
      );
    });

    test('buildApiClient terkonfigurasi dengan timeout dan header kompresi', () {
      final dio = buildApiClient(FakeTokenStore(), FakeAuthRepo());

      expect(dio.options.connectTimeout, const Duration(seconds: 10));
      expect(dio.options.receiveTimeout, const Duration(seconds: 15));
      expect(dio.options.headers['Accept-Encoding'], 'gzip, deflate, br');
      expect(
        dio.interceptors.any((element) => element is RetryInterceptor),
        isTrue,
      );
    });

    test(
      'AnnouncementRepositoryImpl menyimpan cache dan menyajikan data dari cache',
      () async {
        final repo = AnnouncementRepositoryImpl(cacheStorage: cacheStorage);

        // Fetch detail pengumuman
        final result = await repo.getAnnouncementById('101');
        expect(result.failure, isNull);
        expect(result.announcement, isNotNull);
        expect(result.announcement!.id, '101');

        // Pastikan tersimpan di cache
        expect(cacheStorage.hasValid('announcement_detail_101'), isTrue);

        // Fetch page 1
        final pageResult = await repo.fetchAnnouncementsPage(1, limit: 3);
        expect(pageResult.failure, isNull);
        expect(pageResult.announcements.length, 3);
        expect(cacheStorage.hasValid('announcements_page_1'), isTrue);
      },
    );
  });
}

